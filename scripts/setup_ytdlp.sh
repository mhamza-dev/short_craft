#!/bin/bash
# Setup script for yt-dlp dependency

set -e

echo "🎥 Setting up yt-dlp for YouTube video downloads..."

# 1. If yt-dlp is already installed, just add its path to .env and exit
if command -v yt-dlp &> /dev/null; then
    YTDLP_PATH="$(command -v yt-dlp)"
    echo "✅ yt-dlp is already installed at $YTDLP_PATH"
    if grep -q '^YTDLP_PATH=' .env 2>/dev/null; then
        # Update existing YTDLP_PATH
        sed -i.bak "s|^YTDLP_PATH=.*$|YTDLP_PATH=\"$YTDLP_PATH\"|" .env
        rm -f .env.bak
    else
        # Append if not present
        echo "YTDLP_PATH=\"$YTDLP_PATH\"" >> .env
    fi
    echo "YTDLP_PATH set in .env"
    yt-dlp --version
    exit 0
fi

# 2. Try asdf (if available)
if command -v asdf &> /dev/null; then
    echo "🔍 asdf detected. Trying to install yt-dlp with asdf python..."
    if ! asdf plugin-list | grep -q python; then
        asdf plugin-add python
    fi
    asdf install python 3.12.2
    asdf global python 3.12.2
    python3 -m pip install --user --upgrade yt-dlp
    # Find yt-dlp in asdf python user base
    YTDLP_PATH="$(asdf where python)/bin/yt-dlp"
    if [ ! -x "$YTDLP_PATH" ]; then
        # Try user base bin
        YTDLP_PATH="$(python3 -m site --user-base)/bin/yt-dlp"
    fi
    if [ -x "$YTDLP_PATH" ]; then
        echo "✅ yt-dlp installed at: $YTDLP_PATH"
        if grep -q '^YTDLP_PATH=' .env 2>/dev/null; then
            # Update existing YTDLP_PATH
            sed -i.bak "s|^YTDLP_PATH=.*$|YTDLP_PATH=\"$YTDLP_PATH\"|" .env
            rm -f .env.bak
        else
            # Append if not present
            echo "YTDLP_PATH=\"$YTDLP_PATH\"" >> .env
        fi
        echo "YTDLP_PATH set in .env"
        "$YTDLP_PATH" --version
        exit 0
    fi
fi

# 3. Try pip3 (if available)
if command -v pip3 &> /dev/null; then
    echo "📦 Installing yt-dlp with pip3..."
    pip3 install --user --upgrade yt-dlp
    YTDLP_PATH="$(python3 -m site --user-base)/bin/yt-dlp"
    if [ -x "$YTDLP_PATH" ]; then
        echo "✅ yt-dlp installed at: $YTDLP_PATH"
        if grep -q '^YTDLP_PATH=' .env 2>/dev/null; then
            # Update existing YTDLP_PATH
            sed -i.bak "s|^YTDLP_PATH=.*$|YTDLP_PATH=\"$YTDLP_PATH\"|" .env
            rm -f .env.bak
        else
            # Append if not present
            echo "YTDLP_PATH=\"$YTDLP_PATH\"" >> .env
        fi
        echo "YTDLP_PATH set in .env"
        "$YTDLP_PATH" --version
        exit 0
    fi
fi

# 4. Try python3 -m pip (if available)
if command -v python3 &> /dev/null; then
    echo "📦 Installing yt-dlp with python3 -m pip..."
    python3 -m pip install --user --upgrade yt-dlp
    YTDLP_PATH="$(python3 -m site --user-base)/bin/yt-dlp"
    if [ -x "$YTDLP_PATH" ]; then
        echo "✅ yt-dlp installed at: $YTDLP_PATH"
        if grep -q '^YTDLP_PATH=' .env 2>/dev/null; then
            # Update existing YTDLP_PATH
            sed -i.bak "s|^YTDLP_PATH=.*$|YTDLP_PATH=\"$YTDLP_PATH\"|" .env
            rm -f .env.bak
        else
            # Append if not present
            echo "YTDLP_PATH=\"$YTDLP_PATH\"" >> .env
        fi
        echo "YTDLP_PATH set in .env"
        "$YTDLP_PATH" --version
        exit 0
    fi
fi

echo "❌ yt-dlp installation failed. Please check your Python/pip3/asdf setup."
exit 1