#!/bin/bash

# Download Flutter
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Add to path
export PATH="$PATH:$(pwd)/flutter/bin"

# Run doctor to pre-download artifacts (optional but helps)
flutter doctor

# Build web
flutter build web --release
