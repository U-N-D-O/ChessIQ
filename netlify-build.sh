#!/usr/bin/env bash
set -euo pipefail

if [ ! -d "$HOME/flutter" ]; then
  git clone --depth 1 -b "${FLUTTER_CHANNEL:-stable}" https://github.com/flutter/flutter.git "$HOME/flutter"
fi

export PATH="$HOME/flutter/bin:$PATH"

flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release
