#!/bin/bash

# Script para instalar dependencias del servidor

echo "Instalando dependencias del servidor Betis DB..."

cd "$(dirname "$0")/server"

if ! command -v npm &> /dev/null
then
    echo "npm no está instalado. Por favor, instala Node.js desde https://nodejs.org/"
    exit 1
fi

echo "Instalando módulos npm..."
npm install

echo ""
echo "✓ Dependencias instaladas correctamente"
echo ""
echo "Para iniciar el servidor, ejecuta:"
echo "  cd server && npm start"
echo ""
echo "O para desarrollo con auto-reload:"
echo "  cd server && npm run dev"
