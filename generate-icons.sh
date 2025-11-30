#!/bin/bash

# Script to generate all required app icon sizes from a source image
# Usage: ./generate-icons.sh

SOURCE_IMAGE="VoiceInk/Assets.xcassets/AppIcon.appiconset/new-icon.png"
OUTPUT_DIR="VoiceInk/Assets.xcassets/AppIcon.appiconset"

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

echo "🎨 Generating app icons from: $SOURCE_IMAGE"
echo "📁 Output directory: $OUTPUT_DIR"
echo ""

# Array of required sizes for macOS app icons
declare -a sizes=("1024" "512" "256" "128" "64" "32" "16")

# Generate each size
for size in "${sizes[@]}"; do
    output_file="${OUTPUT_DIR}/${size}-mac.png"
    echo "⚙️  Generating ${size}x${size}..."
    convert "$SOURCE_IMAGE" -resize ${size}x${size} "$output_file"
    
    if [ $? -eq 0 ]; then
        echo "✅ Created: $output_file"
    else
        echo "❌ Failed to create: $output_file"
    fi
done

echo ""
echo "🎉 Icon generation complete!"
echo "📝 All icon sizes have been generated in: $OUTPUT_DIR"
echo ""
echo "Next steps:"
echo "1. Clean and rebuild your Xcode project"
echo "2. The new icons should appear in your app"
