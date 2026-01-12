#!/bin/bash

# Script para crear imágenes de prueba usando ImageMagick

IMAGES_DIR="$(dirname "$0")/server/public/images"

# Verificar que ImageMagick está instalado
if ! command -v convert &> /dev/null
then
    echo "ERROR: ImageMagick no está instalado"
    echo "Instálalo con: brew install imagemagick"
    exit 1
fi

echo "Creando imágenes de prueba..."

# Lista de jugadores y sus colores
declare -A PLAYERS=(
    ["rui-silva"]="22DD22"
    ["fran-vieites"]="22EE55"
    ["aitor-ruibal"]="22FF88"
    ["german-pezzella"]="44FF44"
    ["edgar-gonzalez"]="66FF66"
    ["zouma"]="88FF88"
    ["lo-celso"]="99FF99"
    ["guido-rodriguez"]="AAFFAA"
    ["dani-martin"]="BBFFBB"
    ["abner"]="CCFFCC"
    ["ayoze-perez"]="DDFFDD"
    ["nabil-fekir"]="EEFFEE"
    ["juanmi"]="FFFFFF"
    ["william-carvalho"]="FFFF99"
)

# Crear imágenes de prueba
for player in "${!PLAYERS[@]}"
do
    color="${PLAYERS[$player]}"
    convert -size 200x200 "xc:#$color" \
        -font Helvetica -pointsize 24 \
        -fill black -gravity center \
        -annotate +0+0 "$player" \
        "$IMAGES_DIR/$player.jpg"
    echo "✓ Creada imagen: $player.jpg"
done

echo ""
echo "Imágenes de prueba creadas en: $IMAGES_DIR"
echo "Las imágenes reales pueden reemplazar estos placeholders."
