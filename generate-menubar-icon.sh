#!/bin/bash

# Script to generate menu bar icon from app icon
# Extracts just the black outline/border from the pixel skull design

SOURCE_IMAGE="VoiceInk/Assets.xcassets/AppIcon.appiconset/1024-mac.png"
OUTPUT_FILE="VoiceInk/Assets.xcassets/menuBarIcon.imageset/menuBarIcon.png"
TEMP_FILE="/tmp/menubar-temp.png"

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick is not installed."
    echo "📦 Installing ImageMagick via Homebrew..."
    
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew is not installed. Please install it first:"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    
    brew install imagemagick
fi

# Check if source image exists
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "❌ Source image not found: $SOURCE_IMAGE"
    exit 1
fi

echo "🎨 Generating menu bar icon from: $SOURCE_IMAGE"
echo "📁 Output: $OUTPUT_FILE"
echo ""

# Menu bar icons should be:
# - Small size (44x44 for Retina, displays at 22x22)
# - Black silhouette on transparent background
# - Template rendering (macOS will handle light/dark mode)

echo "⚙️  Step 1: Extracting black outline only (removing yellow and white)..."
# Remove yellow background and white fill, keep only black outline
convert "$SOURCE_IMAGE" \
    -fuzz 20% \
    \( +clone -fill white -colorize 100% \) \
    +swap -compose Difference -composite \
    -threshold 50% \
    -negate \
    -transparent white \
    "$TEMP_FILE"

echo "⚙️  Step 2: Resizing to 44x44 (Retina size)..."
convert "$TEMP_FILE" -resize 44x44 "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Menu bar icon created successfully!"
    echo ""
    echo "📝 The icon is configured as a template image, so macOS will:"
    echo "   • Show it in black in Light Mode"
    echo "   • Show it in white in Dark Mode"
    echo ""
    echo "Next steps:"
    echo "1. Clean and rebuild your Xcode project"
    echo "2. The new menu bar icon should appear"
else
    echo "❌ Failed to create menu bar icon"
    exit 1
fi

# Clean up temp file
rm -f "$TEMP_FILE"
