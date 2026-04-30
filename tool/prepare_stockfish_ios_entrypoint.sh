#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <input-main.cpp> <output-main_stockfish.cpp>" >&2
  exit 1
fi

input_file="$1"
output_file="$2"

if [[ ! -f "$input_file" ]]; then
  echo "Input file not found: $input_file" >&2
  exit 1
fi

perl -0777 -pe '
  BEGIN { $count = 0 }
  $count += s/\bint\s+main\s*\(/extern "C" int stockfish_main(/;
  END {
    die "Expected exactly one main() signature rewrite\n" unless $count == 1;
  }
' "$input_file" > "$output_file"

grep -F 'extern "C" int stockfish_main(' "$output_file" >/dev/null
