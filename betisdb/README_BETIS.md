# Betis DB - Aplicación Flutter

## Descripción
Aplicación Flutter que muestra información sobre los jugadores del Real Betis Balompié para la temporada 2025/2026. La aplicación obtiene datos de un servidor NodeJS mediante llamadas HTTP POST y GET.

## Características

### Vistas Principales
1. **Categorías** - Muestra las posiciones disponibles (Porteros, Defensas, Centrocampistas, Delanteros)
2. **Lista de Jugadores** - Muestra los jugadores de cada categoría seleccionada
3. **Detalle del Jugador** - Información detallada del jugador, incluyendo imagen, estadísticas y descripción
4. **Búsqueda** - Busca jugadores en tiempo real

### Navegación
- Interfaz con navegación inferior (Bottom Navigation Bar)
- Navegación entre vistas: Categorías → Jugadores → Detalle
- Búsqueda directa desde la vista de búsqueda

## Requisitos

### Flutter
- Flutter SDK 3.10.4 o superior
- Dart 3.10 o superior

### Server NodeJS
- Node.js 14.x o superior
- npm o yarn

## Instalación

### 1. Instalar dependencias Flutter
```bash
cd betisdb
flutter pub get
```

### 2. Instalar dependencias del servidor NodeJS
```bash
cd betisdb/server
npm install
```

## Ejecución

### 1. Iniciar el servidor NodeJS
```bash
cd betisdb/server
npm start
# O para desarrollo con auto-reload:
npm run dev
```

El servidor estará disponible en `http://localhost:3000`

### 2. Ejecutar la aplicación Flutter
En otra terminal:
```bash
cd betisdb
flutter run
```

Para ejecutar en dispositivo específico:
```bash
flutter run -d <device-id>
```

## API Endpoints

### GET Categorías
```
POST http://localhost:3000/api/categories
```

### GET Jugadores por Categoría
```
POST http://localhost:3000/api/players/category
Body: {"categoryId": "1"}
```

### GET Detalle del Jugador
```
POST http://localhost:3000/api/players/detail
Body: {"playerId": "1"}
```

### Búsqueda de Jugadores
```
POST http://localhost:3000/api/players/search
Body: {"query": "Ayoze"}
```

### GET Imágenes
```
GET http://localhost:3000/images/{imageName}
```

## Estructura del Proyecto

```
betisdb/
├── lib/
│   ├── main.dart                 # Punto de entrada y navegación
│   ├── models/
│   │   ├── category.dart         # Modelo de categoría
│   │   └── player.dart           # Modelo de jugador
│   ├── services/
│   │   └── api_service.dart      # Servicios HTTP
│   └── views/
│       ├── categories_view.dart   # Vista de categorías
│       ├── players_list_view.dart # Vista de lista de jugadores
│       ├── player_detail_view.dart# Vista de detalle
│       └── search_view.dart       # Vista de búsqueda
├── server/
│   ├── server.js                 # Servidor Express
│   ├── package.json              # Dependencias Node
│   └── public/
│       └── images/               # Carpeta para imágenes
└── pubspec.yaml                  # Dependencias Flutter
```

## Datos Incluidos

La aplicación incluye información de 14 jugadores del Real Betis:

### Porteros (2)
- Rui Silva
- Fran Vieites

### Defensas (3)
- Aitor Ruibal
- Germán Pezzella
- Edgar González
- Zouma

### Centrocampistas (4)
- Giovani Lo Celso
- Guido Rodríguez
- Dani Martin
- Abner

### Delanteros (4)
- Ayoze Pérez
- Nabil Fekir
- Juanmi
- William Carvalho

## Características de la Interfaz

- Diseño material con colores de Betis (verde y blanco)
- Navegación inferior con dos pestañas
- Tarjetas visuales en la vista de categorías
- Lista con imágenes y detalles en la vista de jugadores
- Detalle completo con imagen grande en la vista de jugador
- Búsqueda en tiempo real con resultados instantáneos
- Manejo de errores y estados de carga

## Próximas Mejoras

- [ ] Agregar imágenes reales de los jugadores
- [ ] Implementar base de datos
- [ ] Agregar estadísticas de temporada
- [ ] Agregar historial de búsquedas
- [ ] Implementar favoritos
- [ ] Agregar autenticación

## Licencia

Este proyecto es de propósito educativo para la asignatura de Interfaces.

## Autor

Victor Prieto - DAM2 Interfaces

---

**Nota**: Para que las imágenes se carguen correctamente, coloca los archivos de imagen en la carpeta `server/public/images/` con los nombres especificados en la base de datos del servidor.
