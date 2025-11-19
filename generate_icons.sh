#!/bin/bash

# Script per generare le icone per iOS e Android da un'immagine sorgente

SOURCE_ICON="/Users/mariomoschetta/Downloads/powerfull buddy icon-iOS-Default-1024x1024@1x.png"
PROJECT_DIR="/Users/mariomoschetta/Downloads/Powerful students/powerful_students"

# Verifica che il file sorgente esista
if [ ! -f "$SOURCE_ICON" ]; then
    echo "Errore: File sorgente non trovato: $SOURCE_ICON"
    exit 1
fi

echo "Generazione icone da: $SOURCE_ICON"

# Crea una cartella temporanea per le icone generate
TEMP_DIR=$(mktemp -d)
echo "Cartella temporanea: $TEMP_DIR"

# Funzione per ridimensionare un'immagine
resize_icon() {
    local size=$1
    local output=$2
    sips -z $size $size "$SOURCE_ICON" --out "$output" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ Generata: $output ($size x $size)"
    else
        echo "✗ Errore nella generazione di: $output"
    fi
}

# Genera icone per Android
echo ""
echo "=== Generazione icone Android ==="
ANDROID_RES="$PROJECT_DIR/android/app/src/main/res"

# mipmap-mdpi: 48x48
resize_icon 48 "$TEMP_DIR/ic_launcher_mdpi.png"
cp "$TEMP_DIR/ic_launcher_mdpi.png" "$ANDROID_RES/mipmap-mdpi/ic_launcher.png"

# mipmap-hdpi: 72x72
resize_icon 72 "$TEMP_DIR/ic_launcher_hdpi.png"
cp "$TEMP_DIR/ic_launcher_hdpi.png" "$ANDROID_RES/mipmap-hdpi/ic_launcher.png"

# mipmap-xhdpi: 96x96
resize_icon 96 "$TEMP_DIR/ic_launcher_xhdpi.png"
cp "$TEMP_DIR/ic_launcher_xhdpi.png" "$ANDROID_RES/mipmap-xhdpi/ic_launcher.png"

# mipmap-xxhdpi: 144x144
resize_icon 144 "$TEMP_DIR/ic_launcher_xxhdpi.png"
cp "$TEMP_DIR/ic_launcher_xxhdpi.png" "$ANDROID_RES/mipmap-xxhdpi/ic_launcher.png"

# mipmap-xxxhdpi: 192x192
resize_icon 192 "$TEMP_DIR/ic_launcher_xxxhdpi.png"
cp "$TEMP_DIR/ic_launcher_xxxhdpi.png" "$ANDROID_RES/mipmap-xxxhdpi/ic_launcher.png"

# Genera icone per iOS
echo ""
echo "=== Generazione icone iOS ==="
IOS_ICONSET="$PROJECT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset"

# iPhone 20pt @2x: 40x40
resize_icon 40 "$TEMP_DIR/Icon-App-20x20@2x.png"
cp "$TEMP_DIR/Icon-App-20x20@2x.png" "$IOS_ICONSET/Icon-App-20x20@2x.png"

# iPhone 20pt @3x: 60x60
resize_icon 60 "$TEMP_DIR/Icon-App-20x20@3x.png"
cp "$TEMP_DIR/Icon-App-20x20@3x.png" "$IOS_ICONSET/Icon-App-20x20@3x.png"

# iPhone 29pt @1x: 29x29
resize_icon 29 "$TEMP_DIR/Icon-App-29x29@1x.png"
cp "$TEMP_DIR/Icon-App-29x29@1x.png" "$IOS_ICONSET/Icon-App-29x29@1x.png"

# iPhone 29pt @2x: 58x58
resize_icon 58 "$TEMP_DIR/Icon-App-29x29@2x.png"
cp "$TEMP_DIR/Icon-App-29x29@2x.png" "$IOS_ICONSET/Icon-App-29x29@2x.png"

# iPhone 29pt @3x: 87x87
resize_icon 87 "$TEMP_DIR/Icon-App-29x29@3x.png"
cp "$TEMP_DIR/Icon-App-29x29@3x.png" "$IOS_ICONSET/Icon-App-29x29@3x.png"

# iPhone 40pt @2x: 80x80
resize_icon 80 "$TEMP_DIR/Icon-App-40x40@2x.png"
cp "$TEMP_DIR/Icon-App-40x40@2x.png" "$IOS_ICONSET/Icon-App-40x40@2x.png"

# iPhone 40pt @3x: 120x120
resize_icon 120 "$TEMP_DIR/Icon-App-40x40@3x.png"
cp "$TEMP_DIR/Icon-App-40x40@3x.png" "$IOS_ICONSET/Icon-App-40x40@3x.png"

# iPhone 60pt @2x: 120x120 (già generato, copia)
cp "$TEMP_DIR/Icon-App-40x40@3x.png" "$IOS_ICONSET/Icon-App-60x60@2x.png"

# iPhone 60pt @3x: 180x180
resize_icon 180 "$TEMP_DIR/Icon-App-60x60@3x.png"
cp "$TEMP_DIR/Icon-App-60x60@3x.png" "$IOS_ICONSET/Icon-App-60x60@3x.png"

# iPad 20pt @1x: 20x20
resize_icon 20 "$TEMP_DIR/Icon-App-20x20@1x.png"
cp "$TEMP_DIR/Icon-App-20x20@1x.png" "$IOS_ICONSET/Icon-App-20x20@1x.png"

# iPad 20pt @2x: 40x40 (già generato, copia)
cp "$TEMP_DIR/Icon-App-20x20@2x.png" "$IOS_ICONSET/Icon-App-20x20@2x.png"

# iPad 29pt @1x: 29x29 (già generato, copia)
cp "$TEMP_DIR/Icon-App-29x29@1x.png" "$IOS_ICONSET/Icon-App-29x29@1x.png"

# iPad 29pt @2x: 58x58 (già generato, copia)
cp "$TEMP_DIR/Icon-App-29x29@2x.png" "$IOS_ICONSET/Icon-App-29x29@2x.png"

# iPad 40pt @1x: 40x40
resize_icon 40 "$TEMP_DIR/Icon-App-40x40@1x.png"
cp "$TEMP_DIR/Icon-App-40x40@1x.png" "$IOS_ICONSET/Icon-App-40x40@1x.png"

# iPad 40pt @2x: 80x80 (già generato, copia)
cp "$TEMP_DIR/Icon-App-40x40@2x.png" "$IOS_ICONSET/Icon-App-40x40@2x.png"

# iPad 76pt @1x: 76x76
resize_icon 76 "$TEMP_DIR/Icon-App-76x76@1x.png"
cp "$TEMP_DIR/Icon-App-76x76@1x.png" "$IOS_ICONSET/Icon-App-76x76@1x.png"

# iPad 76pt @2x: 152x152
resize_icon 152 "$TEMP_DIR/Icon-App-76x76@2x.png"
cp "$TEMP_DIR/Icon-App-76x76@2x.png" "$IOS_ICONSET/Icon-App-76x76@2x.png"

# iPad Pro 83.5pt @2x: 167x167
resize_icon 167 "$TEMP_DIR/Icon-App-83.5x83.5@2x.png"
cp "$TEMP_DIR/Icon-App-83.5x83.5@2x.png" "$IOS_ICONSET/Icon-App-83.5x83.5@2x.png"

# iOS Marketing 1024x1024
cp "$SOURCE_ICON" "$IOS_ICONSET/Icon-App-1024x1024@1x.png"

# Pulisci la cartella temporanea
rm -rf "$TEMP_DIR"

echo ""
echo "✓ Completato! Tutte le icone sono state generate e copiate nelle cartelle appropriate."
echo ""
echo "Android: android/app/src/main/res/mipmap-*/ic_launcher.png"
echo "iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/"

