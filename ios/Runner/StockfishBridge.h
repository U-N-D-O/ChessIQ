#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^StockfishOutputHandler)(NSString *line);

@interface StockfishBridge : NSObject

+ (instancetype)shared;

- (BOOL)start:(NSError * _Nullable * _Nullable)error;
- (void)sendCommand:(NSString *)command;
- (void)stop;
- (void)setOutputHandler:(StockfishOutputHandler _Nullable)handler;

@end

NS_ASSUME_NONNULL_END
