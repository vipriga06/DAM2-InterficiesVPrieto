#!/bin/bash
# Script de inicio rápido para Betis DB

clear

echo "╔════════════════════════════════════╗"
echo "║         🟢 BETIS DB 🟢             ║"
echo "║   Base de Datos de Jugadores      ║"
echo "║   Temporada 2025/2026             ║"
echo "╚════════════════════════════════════╝"
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: Ejecuta este script desde la raíz del proyecto betisdb${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Opciones disponibles:${NC}"
echo ""
echo "1) Verificar instalación"
echo "2) Instalar dependencias"
echo "3) Iniciar servidor NodeJS"
echo "4) Ejecutar aplicación Flutter"
echo "5) Ver documentación"
echo "6) Salir"
echo ""
read -p "Selecciona una opción (1-6): " option

case $option in
    1)
        echo -e "${BLUE}🔍 Verificando instalación...${NC}"
        bash verify.sh
        ;;
    2)
        echo -e "${BLUE}📦 Instalando dependencias...${NC}"
        echo ""
        echo -e "${YELLOW}→ Instalando dependencias Flutter...${NC}"
        flutter pub get
        echo ""
        echo -e "${YELLOW}→ Instalando dependencias Node.js...${NC}"
        cd server
        npm install
        cd ..
        echo -e "${GREEN}✓ Dependencias instaladas correctamente${NC}"
        ;;
    3)
        echo -e "${BLUE}🚀 Iniciando servidor NodeJS...${NC}"
        echo -e "${YELLOW}Puerto: 3000${NC}"
        echo -e "${YELLOW}URL: http://localhost:3000${NC}"
        echo ""
        echo "Presiona Ctrl+C para detener el servidor"
        echo ""
        cd server
        npm start
        ;;
    4)
        echo -e "${BLUE}📱 Ejecutando aplicación Flutter...${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  Asegúrate de que el servidor NodeJS está ejecutándose en otro terminal${NC}"
        echo ""
        sleep 2
        flutter run
        ;;
    5)
        echo -e "${BLUE}📚 Documentación disponible:${NC}"
        echo ""
        echo "  • README_BETIS.md - Documentación completa"
        echo "  • TESTING.md - Guía de pruebas"
        echo "  • QUICK_REFERENCE.md - Referencia rápida"
        echo "  • RESUMEN_PROYECTO.md - Resumen del proyecto"
        echo ""
        read -p "¿Deseas abrir alguna documentación? (1-4, 0=no): " doc
        case $doc in
            1) open README_BETIS.md 2>/dev/null || cat README_BETIS.md | less ;;
            2) open TESTING.md 2>/dev/null || cat TESTING.md | less ;;
            3) open QUICK_REFERENCE.md 2>/dev/null || cat QUICK_REFERENCE.md | less ;;
            4) open RESUMEN_PROYECTO.md 2>/dev/null || cat RESUMEN_PROYECTO.md | less ;;
        esac
        ;;
    6)
        echo -e "${GREEN}✓ ¡Hasta pronto! ⚽${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Opción no válida${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✓ Operación completada${NC}"
