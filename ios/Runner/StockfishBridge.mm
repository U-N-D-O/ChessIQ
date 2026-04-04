#import "StockfishBridge.h"

#import <dispatch/dispatch.h>
#import <pthread.h>
#import <unistd.h>

extern "C" int stockfish_main(int argc, char* argv[]);

@interface StockfishBridge () {
  int _stdinReadFD;
  int _stdinWriteFD;
  int _stdoutReadFD;
  int _stdoutWriteFD;

  int _savedStdinFD;
  int _savedStdoutFD;
  int _savedStderrFD;

  pthread_t _engineThread;
  BOOL _engineThreadStarted;
  BOOL _running;

  dispatch_queue_t _ioQueue;
  dispatch_source_t _stdoutSource;
  NSMutableData *_pendingOutputData;
}

@property(nonatomic, copy, nullable) StockfishOutputHandler outputHandler;

@end

@implementation StockfishBridge

+ (instancetype)shared {
  static StockfishBridge *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[StockfishBridge alloc] initPrivate];
  });
  return instance;
}

- (instancetype)init {
  [NSException raise:@"Singleton"
              format:@"Use +[StockfishBridge shared] instead of init"];
  return nil;
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    _stdinReadFD = -1;
    _stdinWriteFD = -1;
    _stdoutReadFD = -1;
    _stdoutWriteFD = -1;
    _savedStdinFD = -1;
    _savedStdoutFD = -1;
    _savedStderrFD = -1;
    _engineThreadStarted = NO;
    _running = NO;
    _ioQueue = dispatch_queue_create("com.chessiq.stockfish.io", DISPATCH_QUEUE_SERIAL);
    _pendingOutputData = [NSMutableData data];
  }
  return self;
}

- (void)setOutputHandler:(StockfishOutputHandler _Nullable)handler {
  _outputHandler = [handler copy];
}

static void *StockfishThreadEntry(void *ctx) {
  StockfishBridge *bridge = (__bridge StockfishBridge *)ctx;
  @autoreleasepool {
    [bridge runEngineMain];
  }
  return nullptr;
}

- (BOOL)start:(NSError * _Nullable * _Nullable)error {
  if (_running) {
    return YES;
  }

  int stdinPipe[2] = {-1, -1};
  int stdoutPipe[2] = {-1, -1};
  if (pipe(stdinPipe) != 0 || pipe(stdoutPipe) != 0) {
    if (error) {
      *error = [NSError errorWithDomain:@"StockfishBridge"
                                   code:1001
                               userInfo:@{NSLocalizedDescriptionKey: @"Failed to create engine pipes"}];
    }
    if (stdinPipe[0] != -1) close(stdinPipe[0]);
    if (stdinPipe[1] != -1) close(stdinPipe[1]);
    if (stdoutPipe[0] != -1) close(stdoutPipe[0]);
    if (stdoutPipe[1] != -1) close(stdoutPipe[1]);
    return NO;
  }

  _savedStdinFD = dup(STDIN_FILENO);
  _savedStdoutFD = dup(STDOUT_FILENO);
  _savedStderrFD = dup(STDERR_FILENO);
  if (_savedStdinFD == -1 || _savedStdoutFD == -1 || _savedStderrFD == -1) {
    if (error) {
      *error = [NSError errorWithDomain:@"StockfishBridge"
                                   code:1002
                               userInfo:@{NSLocalizedDescriptionKey: @"Failed to save stdio file descriptors"}];
    }
    close(stdinPipe[0]);
    close(stdinPipe[1]);
    close(stdoutPipe[0]);
    close(stdoutPipe[1]);
    return NO;
  }

  _stdinReadFD = stdinPipe[0];
  _stdinWriteFD = stdinPipe[1];
  _stdoutReadFD = stdoutPipe[0];
  _stdoutWriteFD = stdoutPipe[1];

  [self startOutputReader];

  _running = YES;
  int threadErr = pthread_create(&_engineThread, nullptr, StockfishThreadEntry, (__bridge void *)self);
  if (threadErr != 0) {
    _running = NO;
    [self stopOutputReader];
    [self closeIfOpen:&_stdinReadFD];
    [self closeIfOpen:&_stdinWriteFD];
    [self closeIfOpen:&_stdoutReadFD];
    [self closeIfOpen:&_stdoutWriteFD];
    [self closeIfOpen:&_savedStdinFD];
    [self closeIfOpen:&_savedStdoutFD];
    [self closeIfOpen:&_savedStderrFD];

    if (error) {
      *error = [NSError errorWithDomain:@"StockfishBridge"
                                   code:1003
                               userInfo:@{NSLocalizedDescriptionKey: @"Failed to start engine thread"}];
    }
    return NO;
  }

  _engineThreadStarted = YES;
  return YES;
}

- (void)runEngineMain {
  dup2(_stdinReadFD, STDIN_FILENO);
  dup2(_stdoutWriteFD, STDOUT_FILENO);
  dup2(_stdoutWriteFD, STDERR_FILENO);

  [self closeIfOpen:&_stdinReadFD];
  [self closeIfOpen:&_stdoutWriteFD];

  char arg0[] = "stockfish";
  char *argv[] = {arg0, nullptr};
  stockfish_main(1, argv);

  fflush(stdout);
  fflush(stderr);

  if (_savedStdinFD != -1) {
    dup2(_savedStdinFD, STDIN_FILENO);
  }
  if (_savedStdoutFD != -1) {
    dup2(_savedStdoutFD, STDOUT_FILENO);
  }
  if (_savedStderrFD != -1) {
    dup2(_savedStderrFD, STDERR_FILENO);
  }

  [self closeIfOpen:&_savedStdinFD];
  [self closeIfOpen:&_savedStdoutFD];
  [self closeIfOpen:&_savedStderrFD];

  _running = NO;
}

- (void)sendCommand:(NSString *)command {
  if (!_running || _stdinWriteFD == -1) {
    return;
  }
  NSData *data = [[command stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding];
  if (data.length == 0) return;

  dispatch_sync(_ioQueue, ^{
    const uint8_t *bytes = (const uint8_t *)data.bytes;
    ssize_t remaining = (ssize_t)data.length;
    while (remaining > 0) {
      ssize_t written = write(self->_stdinWriteFD, bytes, (size_t)remaining);
      if (written <= 0) {
        break;
      }
      remaining -= written;
      bytes += written;
    }
  });
}

- (void)stop {
  if (!_running && !_engineThreadStarted) {
    return;
  }

  [self sendCommand:@"quit"];

  [self closeIfOpen:&_stdinWriteFD];

  if (_engineThreadStarted) {
    pthread_join(_engineThread, nullptr);
    _engineThreadStarted = NO;
  }

  [self stopOutputReader];
  [self closeIfOpen:&_stdoutReadFD];

  [self closeIfOpen:&_savedStdinFD];
  [self closeIfOpen:&_savedStdoutFD];
  [self closeIfOpen:&_savedStderrFD];

  _running = NO;
}

- (void)startOutputReader {
  if (_stdoutReadFD == -1) return;

  _pendingOutputData.length = 0;
  _stdoutSource = dispatch_source_create(
      DISPATCH_SOURCE_TYPE_READ,
      (uintptr_t)_stdoutReadFD,
      0,
      _ioQueue);

  __weak typeof(self) weakSelf = self;
  dispatch_source_set_event_handler(_stdoutSource, ^{
    __strong typeof(self) self = weakSelf;
    if (!self) return;

    char buffer[4096];
    ssize_t n = read(self->_stdoutReadFD, buffer, sizeof(buffer));
    if (n <= 0) {
      [self emitPendingOutputIfAny];
      if (self->_stdoutSource) {
        dispatch_source_cancel(self->_stdoutSource);
      }
      return;
    }

    [self->_pendingOutputData appendBytes:buffer length:(NSUInteger)n];
    [self flushCompleteLines];
  });

  dispatch_source_set_cancel_handler(_stdoutSource, ^{
    __strong typeof(self) self = weakSelf;
    if (!self) return;
    self->_stdoutSource = nil;
  });

  dispatch_resume(_stdoutSource);
}

- (void)stopOutputReader {
  if (_stdoutSource) {
    dispatch_source_cancel(_stdoutSource);
    _stdoutSource = nil;
  }
}

- (void)flushCompleteLines {
  const uint8_t *bytes = (const uint8_t *)_pendingOutputData.bytes;
  NSUInteger length = _pendingOutputData.length;
  NSUInteger lineStart = 0;

  for (NSUInteger i = 0; i < length; i++) {
    if (bytes[i] == '\n') {
      NSUInteger lineLen = i - lineStart;
      if (lineLen > 0) {
        NSData *lineData = [_pendingOutputData subdataWithRange:NSMakeRange(lineStart, lineLen)];
        NSString *line = [[NSString alloc] initWithData:lineData encoding:NSUTF8StringEncoding];
        [self emitLine:line ?: @""];
      }
      lineStart = i + 1;
    }
  }

  if (lineStart > 0) {
    NSData *rest = [_pendingOutputData subdataWithRange:NSMakeRange(lineStart, length - lineStart)];
    _pendingOutputData.length = 0;
    [_pendingOutputData appendData:rest];
  }
}

- (void)emitPendingOutputIfAny {
  if (_pendingOutputData.length == 0) return;
  NSString *line = [[NSString alloc] initWithData:_pendingOutputData encoding:NSUTF8StringEncoding];
  _pendingOutputData.length = 0;
  [self emitLine:line ?: @""];
}

- (void)emitLine:(NSString *)line {
  NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (trimmed.length == 0) return;

  StockfishOutputHandler handler = self.outputHandler;
  if (!handler) return;

  dispatch_async(dispatch_get_main_queue(), ^{
    handler(trimmed);
  });
}

- (void)closeIfOpen:(int *)fd {
  if (*fd != -1) {
    close(*fd);
    *fd = -1;
  }
}

@end
