import 'dart:io';

final _csStringRegExp = RegExp(r'"([^"\\]*(?:\\.[^"\\]*)*)"');
final _wordNormalizing = RegExp(r'[^a-z0-9]+');

String normalizeWord(String value) {
  final trimmed = value.trim();
  final withoutQuotes = trimmed.replaceAll(RegExp(r'^"|"\$'), '');
  final lower = withoutQuotes.toLowerCase();
  return lower.replaceAll(_wordNormalizing, '');
}

Iterable<String> parseCsFile(File file) sync* {
  final content = file.readAsStringSync();
  for (final match in _csStringRegExp.allMatches(content)) {
    final raw = match.group(1);
    if (raw == null) continue;
    final word = normalizeWord(raw);
    if (word.isNotEmpty) {
      yield word;
    }
  }
}

Iterable<String> parseTextFile(File file) sync* {
  for (final raw in file.readAsLinesSync()) {
    final word = normalizeWord(raw);
    if (word.isNotEmpty) {
      yield word;
    }
  }
}

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln(
      'Usage: dart tool/merge_profanity.dart <output.dart> <input1> [input2 ...]',
    );
    exit(1);
  }

  final outputPath = args.first;
  final inputs = args.sublist(1);
  final combined = <String>{};

  for (final inputPath in inputs) {
    final file = File(inputPath);
    if (!file.existsSync()) {
      stderr.writeln('File not found: $inputPath');
      continue;
    }
    if (inputPath.toLowerCase().endsWith('.cs')) {
      combined.addAll(parseCsFile(file));
    } else {
      combined.addAll(parseTextFile(file));
    }
  }

  final sorted = combined.toList()..sort();

  final buffer = StringBuffer();
  buffer.writeln('// Generated profanity list.');
  buffer.writeln(
    '// Run: dart tool/merge_profanity.dart $outputPath <input files>',
  );
  buffer.writeln('const Set<String> profanityWords = <String>{');
  for (final word in sorted) {
    buffer.writeln("  '$word',");
  }
  buffer.writeln('};');

  File(outputPath).writeAsStringSync(buffer.toString());
  stdout.writeln(
    'Wrote ${sorted.length} normalized profanity words to $outputPath',
  );
}
