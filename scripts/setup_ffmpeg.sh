#!/bin/bash
# Setup script for FFmpeg with libx264 support

set -e

echo "🎬 Setting up FFmpeg with libx264 support for ShortCraft..."

if command -v brew >/dev/null 2>&1; then
  # Remove old conflicting binaries manually if they exist
  if [ -f /usr/local/bin/ffmpeg ]; then
    echo "⚠️ Removing existing /usr/local/bin/ffmpeg to avoid conflicts..."
    sudo rm -f /usr/local/bin/ffmpeg
  fi

  if [ -f /usr/local/bin/ffprobe ]; then
    echo "⚠️ Removing existing /usr/local/bin/ffprobe to avoid conflicts..."
    sudo rm -f /usr/local/bin/ffprobe
  fi

  echo "🧹 Uninstalling any existing Homebrew ffmpeg (if any)..."
  brew uninstall ffmpeg || true

  echo "⬇️ Installing FFmpeg with default options (includes libx264)..."
  brew install ffmpeg

  echo "🔗 Linking ffmpeg with force and overwrite flags..."
  brew link --overwrite ffmpeg

  echo "✅ FFmpeg installation complete."
  echo "🔍 Checking for x264 encoder support:"
  if ffmpeg -encoders | grep -q 'libx264'; then
    echo "🎉 FFmpeg with x264 support is ready!"
  else
    echo "❌ FFmpeg does not have x264 support."
    echo "👉 Consider installing a static build from: https://evermeet.cx/ffmpeg/"
    exit 1
  fi
else
  echo "❌ Homebrew not found. Please install Homebrew first: https://brew.sh/"
  exit 1
fi
