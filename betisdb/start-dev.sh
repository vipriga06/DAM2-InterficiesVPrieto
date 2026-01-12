#!/bin/bash

# Script para ejecutar el servidor y la aplicación Flutter
# Uso: ./start-dev.sh

echo "================================"
echo "Betis DB - Entorno de Desarrollo"
echo "================================"
echo ""

# Verificar que npm está instalado
if ! command -v npm &> /dev/null
then
    echo "ERROR: npm no está instalado"
    exit 1
fi

# Verificar que flutter está instalado
if ! command -v flutter &> /dev/null
then
    echo "ERROR: Flutter no está instalado"
    exit 1
fi

echo "1. Iniciando servidor NodeJS en puerto 3000..."
cd "$(dirname "$0")/server"
npm start &
SERVER_PID=$!

sleep 3

echo ""
echo "2. Iniciando aplicación Flutter..."
cd "$(dirname "$0")"
flutter run

# Limpiar al salir
trap "kill $SERVER_PID" EXIT
