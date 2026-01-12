# Guía de Prueba - Betis DB

## Pasos para ejecutar la aplicación

### 1. Inicial el servidor NodeJS
```bash
cd betisdb/server
npm start
```

Deberías ver:
```
Servidor Betis DB ejecutándose en http://localhost:3000
Endpoints disponibles:
  POST http://localhost:3000/api/categories
  POST http://localhost:3000/api/players/category
  POST http://localhost:3000/api/players/detail
  POST http://localhost:3000/api/players/search
  GET  http://localhost:3000/images/{image}
```

### 2. En otra terminal, ejecutar la aplicación Flutter
```bash
cd betisdb
flutter run
```

O si tienes múltiples dispositivos:
```bash
flutter devices  # Para ver dispositivos disponibles
flutter run -d <device-id>
```

## Pruebas de Funcionalidad

### Test 1: Ver Categorías
1. Inicia la aplicación
2. Deberías ver 4 categorías: Porteros, Defensas, Centrocampistas, Delanteros
3. Cada categoría tiene un icono y descripción

**Resultado esperado:** ✓ Se muestran todas las categorías correctamente

### Test 2: Ver Jugadores por Categoría
1. Toca cualquier categoría
2. Deberías ver una lista de jugadores de esa categoría
3. Cada jugador muestra: nombre, número, posición, nacionalidad

**Resultado esperado:** ✓ Se muestra la lista de jugadores correctamente

### Test 3: Ver Detalle del Jugador
1. Desde la lista de jugadores, toca cualquier jugador
2. Deberías ver:
   - Imagen grande del jugador
   - Nombre y número destacado
   - Información: nacionalidad, categoría, fecha nacimiento, altura, peso
   - Descripción del jugador

**Resultado esperado:** ✓ Se muestra todo el detalle correctamente

### Test 4: Buscar Jugadores
1. Toca la pestaña "Búsqueda" en la barra inferior
2. Escribe el nombre de un jugador (ej: "Ayoze", "Fekir")
3. Deberías ver resultados en tiempo real
4. Toca un resultado para ver su detalle

**Resultado esperado:** ✓ La búsqueda funciona en tiempo real

### Test 5: Navegación
1. Verifica que puedas navegar entre todas las vistas
2. Los botones atrás funcionan correctamente
3. La barra inferior permite cambiar entre Categorías y Búsqueda

**Resultado esperado:** ✓ La navegación funciona fluidamente

## Pruebas de API (Opcional)

Puedes testear los endpoints directamente con curl:

```bash
# Test 1: Obtener categorías
curl -X POST http://localhost:3000/api/categories \
  -H "Content-Type: application/json"

# Test 2: Obtener jugadores de categoría 1 (Porteros)
curl -X POST http://localhost:3000/api/players/category \
  -H "Content-Type: application/json" \
  -d '{"categoryId":"1"}'

# Test 3: Obtener detalle de jugador 1
curl -X POST http://localhost:3000/api/players/detail \
  -H "Content-Type: application/json" \
  -d '{"playerId":"1"}'

# Test 4: Buscar jugadores
curl -X POST http://localhost:3000/api/players/search \
  -H "Content-Type: application/json" \
  -d '{"query":"Ayoze"}'
```

## Solución de Problemas

### La aplicación no se conecta al servidor
- Verifica que el servidor NodeJS esté ejecutándose
- Asegúrate de que está en http://localhost:3000
- En emulador Android, usa http://10.0.2.2:3000 en lugar de localhost

### Las imágenes no cargan
- Las imágenes son placeholders por defecto
- Para agregar imágenes reales:
  1. Descarga las imágenes de los jugadores
  2. Colócalas en `server/public/images/`
  3. Asegúrate de que los nombres coincidan (ej: rui-silva.jpg)

### Error "Network is unreachable"
- Verifica que el servidor esté corriendo
- Comprueba el firewall
- En iOS, puede ser necesario agregar excepciones en Info.plist

## Requisitos Cumplidos

✓ Aplicación Flutter con información sobre jugadores del Betis  
✓ Servidor NodeJS que sirve datos mediante POST  
✓ Imágenes servidas mediante GET  
✓ Mínimo 3 vistas: Categorías, Jugadores, Detalle  
✓ Imágenes en la vista detalle  
✓ Navegación: Categorías → Jugadores → Detalle  
✓ Vista de búsqueda con resultados en tiempo real  
✓ Temática única (Betis 2025/2026)  

## Información Adicional

- **Jugadores Totales:** 14 jugadores
- **Categorías:** 4 (Porteros, Defensas, Centrocampistas, Delanteros)
- **Puerto del servidor:** 3000
- **Colores tema:** Verde y blanco (Betis)
- **Dependencias Flutter:** http, provider
- **Dependencias Node:** express, cors, body-parser
