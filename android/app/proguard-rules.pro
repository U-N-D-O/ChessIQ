# The Stockfish and system-audio plugins are registered directly from
# MainActivity, but keeping their public channel handlers makes the custom
# platform bridge resilient to release shrinking and obfuscation changes.
-keep class com.qila.chessiq.StockfishPlugin { *; }
-keep class com.qila.chessiq.SystemAudioPlugin { *; }
