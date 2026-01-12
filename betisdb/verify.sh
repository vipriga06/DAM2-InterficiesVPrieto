#!/bin/bash

# Script para verificar la configuración del proyecto

echo "================================"
echo "Verificación de Betis DB"
echo "================================"
echo ""

# Verificar Flutter
echo "1. Verificando Flutter..."
if command -v flutter &> /dev/null
then
    FLUTTER_VERSION=$(flutter --version | head -1)
    echo "✓ Flutter instalado: $FLUTTER_VERSION"
else
    echo "✗ Flutter NO instalado"
    exit 1
fi

# Verificar Dart
echo ""
echo "2. Verificando Dart..."
if command -v dart &> /dev/null
then
    DART_VERSION=$(dart --version 2>&1 | head -1)
    echo "✓ Dart instalado: $DART_VERSION"
else
    echo "✗ Dart NO instalado"
    exit 1
fi

# Verificar Node.js
echo ""
echo "3. Verificando Node.js..."
if command -v node &> /dev/null
then
    NODE_VERSION=$(node --version)
    echo "✓ Node.js instalado: $NODE_VERSION"
else
    echo "✗ Node.js NO instalado"
    exit 1
fi

# Verificar npm
echo ""
echo "4. Verificando npm..."
if command -v npm &> /dev/null
then
    NPM_VERSION=$(npm --version)
    echo "✓ npm instalado: $NPM_VERSION"
else
    echo "✗ npm NO instalado"
    exit 1
fi

# Verificar estructura del proyecto Flutter
echo ""
echo "5. Verificando estructura Flutter..."
if [ -f "pubspec.yaml" ]; then
    echo "✓ pubspec.yaml encontrado"
else
    echo "✗ pubspec.yaml NO encontrado"
fi

if [ -f "lib/main.dart" ]; then
    echo "✓ main.dart encontrado"
else
    echo "✗ main.dart NO encontrado"
fi

# Verificar estructura del servidor
echo ""
echo "6. Verificando estructura del servidor..."
if [ -f "server/server.js" ]; then
    echo "✓ server.js encontrado"
else
    echo "✗ server.js NO encontrado"
fi

if [ -f "server/package.json" ]; then
    echo "✓ package.json encontrado"
else
    echo "✗ package.json NO encontrado"
fi

if [ -d "server/node_modules" ]; then
    echo "✓ node_modules instalado"
else
    echo "✗ node_modules NO instalado (ejecuta: cd server && npm install)"
fi

# Verificar dependencias Flutter
echo ""
echo "7. Verificando dependencias Flutter..."
if [ -d ".dart_tool" ]; then
    echo "✓ Dependencias Flutter instaladas"
else
    echo "✗ Dependencias Flutter NO instaladas (ejecuta: flutter pub get)"
fi

echo ""
echo "================================"
echo "✓ Verificación completada"
echo "================================"
echo ""
echo "Para ejecutar la aplicación:"
echo ""
echo "Terminal 1 - Inicia el servidor:"
echo "  cd server && npm start"
echo ""
echo "Terminal 2 - Inicia Flutter:"
echo "  flutter run"
echo ""
