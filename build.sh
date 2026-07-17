#!/bin/bash

# Download Flutter
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Add to path
export PATH="$PATH:$(pwd)/flutter/bin"

# Run doctor to pre-download artifacts (optional but helps)
flutter doctor

# Ensure .env exists for web build (especially on Vercel where .env is gitignored)
if [ ! -f ".env" ]; then
  echo "Creating .env file for web build from environment variables or defaults..."
  echo "SUPABASE_URL=${SUPABASE_URL:-https://iyznzyqhsbjgtvxgiewe.supabase.co}" > .env
  echo "SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5em56eXFoc2JqZ3R2eGdpZXdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxMTQzMzUsImV4cCI6MjA5MjY5MDMzNX0.JaaXQd9n8uJPZwO-WQ7m06Kvf1Rw35itu07MAAOBKyQ}" >> .env
fi

# Build web
flutter build web --release
