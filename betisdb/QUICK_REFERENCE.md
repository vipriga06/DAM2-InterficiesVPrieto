# Referencia Rápida - Betis DB

## Comandos Esenciales

### Instalar Dependencias
```bash
# Flutter
cd betisdb
flutter pub get

# Server Node
cd betisdb/server
npm install
```

### Ejecutar Aplicación
```bash
# Terminal 1: Servidor
cd betisdb/server
npm start

# Terminal 2: Flutter (en otro directorio)
cd betisdb
flutter run
```

### Verificar Instalación
```bash
cd betisdb
bash verify.sh
```

---

## Estructura de Carpetas Rápida

```
lib/
  ├── main.dart              ← Punto de entrada
  ├── models/                ← Clases de datos
  ├── services/              ← API calls
  └── views/                 ← Pantallas de UI

server/
  ├── server.js              ← Servidor Express
  ├── package.json           ← Dependencias
  └── public/images/         ← Imágenes servidas
```

---

## URLs Importantes

| Componente | URL |
|-----------|-----|
| Servidor | `http://localhost:3000` |
| API Categories | `POST /api/categories` |
| API Jugadores | `POST /api/players/category` |
| API Detalle | `POST /api/players/detail` |
| API Búsqueda | `POST /api/players/search` |
| Imágenes | `GET /images/{name}` |

---

## Datos Rápidos

- **Porteros**: 2
- **Defensas**: 4  
- **Centrocampistas**: 4
- **Delanteros**: 4
- **Total Jugadores**: 14

---

## Navegación

```
┌─────────────┐
│ Categorías  │
└──────┬──────┘
       │ tap
       ▼
┌─────────────────┐
│ Lista Jugadores │
└──────┬──────────┘
       │ tap
       ▼
┌─────────────────┐
│ Detalle Jugador │
└─────────────────┘

┌─────────────────┐
│ Búsqueda        │
└──────┬──────────┘
       │ tap resultado
       ▼
┌─────────────────┐
│ Detalle Jugador │
└─────────────────┘
```

---

## Troubleshooting Rápido

| Problema | Solución |
|----------|----------|
| No conecta al servidor | Verifica `npm start` en puerto 3000 |
| Error de análisis Dart | Ejecuta `flutter analyze` |
| Imágenes no cargan | Son placeholders, coloca reales en `server/public/images/` |
| Puerto 3000 ocupado | Cambia en `server.js` y `api_service.dart` |
| No encuentra servidor | En emulador Android usa `10.0.2.2:3000` |

---

## Características Clave

✅ 4 Vistas (Categorías, Lista, Detalle, Búsqueda)  
✅ API REST completa  
✅ Imágenes por HTTP GET  
✅ Búsqueda en tiempo real  
✅ Navegación fluida  
✅ Diseño Betis (verde/blanco)  
✅ 14 Jugadores 2025/2026  

---

## Desarrollo

### Agregar Nuevo Jugador
En `server/server.js`, agrega al array `players`:
```javascript
{
  id: '15',
  name: 'Nombre Jugador',
  position: 'Posición',
  category: '1-4',
  number: 99,
  nationality: 'País',
  description: 'Descripción',
  imageUrl: 'nombre.jpg',
  height: 180,
  weight: 75,
  birthDate: 'DD/MM/YYYY'
}
```

### Cambiar Colores
En `lib/views/`, reemplaza:
- `Colors.green[800]` → Tu color principal
- `Colors.green[200]` → Tu color secundario

### Cambiar Tema
Edita `lib/main.dart`:
```dart
colorScheme: ColorScheme.fromSeed(seedColor: Colors.tuColor)
```

---

## Archivos Importantes

| Archivo | Propósito |
|---------|-----------|
| `lib/main.dart` | Navegación principal |
| `lib/services/api_service.dart` | Conexión con servidor |
| `server/server.js` | Lógica del servidor |
| `pubspec.yaml` | Dependencias Flutter |
| `server/package.json` | Dependencias Node |

---

**Última actualización**: 12 Enero 2026

Para más información ver: [RESUMEN_PROYECTO.md](RESUMEN_PROYECTO.md)
