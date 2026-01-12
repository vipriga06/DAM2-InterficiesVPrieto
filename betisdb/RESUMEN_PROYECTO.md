# 🟢 Betis DB - Proyecto Completado

## Descripción General
Aplicación Flutter completa que muestra información sobre los jugadores del **Real Betis Balompié - Temporada 2025/2026**.

Los datos se obtienen desde un servidor **NodeJS + Express** mediante llamadas HTTP POST/GET.

---

## 📋 Requisitos Implementados

### ✅ Temática Única
- **Betis DB**: Base de datos de jugadores del Real Betis
- Temporada 2025/2026
- 14 jugadores diferentes distribuidos en 4 categorías

### ✅ Mínimo 3 Vistas
1. **Categorías** - Vista grid con 4 posiciones
2. **Lista de Jugadores** - Vista listado por categoría
3. **Detalle del Jugador** - Vista completa con información
4. **Búsqueda** - Vista adicional de búsqueda en tiempo real

### ✅ Imágenes
- Las imágenes se obtienen mediante GET desde `http://localhost:3000/images/{imageName}`
- Los placeholders funcionan por defecto
- Las imágenes reales pueden colocarse en `server/public/images/`

### ✅ Navegación
- **Categorías → Jugadores** (mediante tap en categoría)
- **Jugadores → Detalle** (mediante tap en jugador)
- **Búsqueda → Detalle** (mediante tap en resultado)
- **Bottom Navigation** para cambiar entre Categorías y Búsqueda

### ✅ Servidor NodeJS
- API con 4 endpoints POST principales
- Servidor de imágenes estáticas
- CORS habilitado
- Datos almacenados en memoria

### ✅ Llamadas HTTP
- **POST** para obtener datos (categorías, jugadores, búsqueda)
- **GET** para obtener imágenes
- Manejo de errores y estados de carga

---

## 📁 Estructura del Proyecto

```
betisdb/
├── lib/
│   ├── main.dart                    # App principal con navegación
│   ├── models/
│   │   ├── category.dart            # Modelo Categoría
│   │   └── player.dart              # Modelo Jugador
│   ├── services/
│   │   └── api_service.dart         # Servicios HTTP
│   └── views/
│       ├── categories_view.dart      # Vista de categorías
│       ├── players_list_view.dart    # Vista de lista
│       ├── player_detail_view.dart   # Vista de detalle
│       └── search_view.dart          # Vista de búsqueda
├── server/
│   ├── server.js                    # Servidor Express
│   ├── package.json                 # Dependencias Node
│   └── public/images/               # Carpeta de imágenes
├── pubspec.yaml                     # Dependencias Flutter
├── README_BETIS.md                  # Documentación completa
├── TESTING.md                       # Guía de pruebas
└── Scripts
    ├── verify.sh                    # Verificar instalación
    ├── install-server.sh            # Instalar servidor
    ├── start-dev.sh                 # Iniciar dev
    └── create-test-images.sh        # Crear imágenes de prueba
```

---

## 🚀 Inicio Rápido

### 1. Verificar Instalación
```bash
cd betisdb
bash verify.sh
```

### 2. Iniciar Servidor NodeJS (Terminal 1)
```bash
cd betisdb/server
npm start
```

Deberías ver:
```
Servidor Betis DB ejecutándose en http://localhost:3000
```

### 3. Iniciar Aplicación Flutter (Terminal 2)
```bash
cd betisdb
flutter run
```

---

## 📊 Datos Disponibles

### Categorías (4)
1. **🧤 Porteros** - Guardametas
2. **🛡️ Defensas** - Defensa
3. **⚙️ Centrocampistas** - Mediocampo
4. **⚽ Delanteros** - Ataque

### Jugadores (14)
- **Porteros**: Rui Silva, Fran Vieites
- **Defensas**: Aitor Ruibal, Germán Pezzella, Edgar González, Zouma
- **Centrocampistas**: Giovani Lo Celso, Guido Rodríguez, Dani Martin, Abner
- **Delanteros**: Ayoze Pérez, Nabil Fekir, Juanmi, William Carvalho

Cada jugador incluye:
- Nombre
- Posición
- Número de camiseta
- Nacionalidad
- Altura y peso
- Fecha de nacimiento
- Descripción
- Imagen

---

## 🔌 API Endpoints

| Método | Endpoint | Cuerpo |
|--------|----------|--------|
| POST | `/api/categories` | {} |
| POST | `/api/players/category` | `{"categoryId": "1"}` |
| POST | `/api/players/detail` | `{"playerId": "1"}` |
| POST | `/api/players/search` | `{"query": "Ayoze"}` |
| GET | `/images/{imageName}` | - |

---

## 🎨 Diseño Visual

### Colores
- **Principal**: Verde (Betis) - `#22DD22` a `#00AA00`
- **Secundario**: Blanco
- **Texto**: Negro/Gris

### Componentes
- **AppBar**: Verde con iconografía Betis
- **Cards**: Grid y ListTiles personalizados
- **Bottom Navigation**: 2 pestañas (Categorías, Búsqueda)
- **Imágenes**: Placeholders con soporte para imágenes reales

---

## 📦 Dependencias

### Flutter
```yaml
http: ^1.1.0           # Cliente HTTP
provider: ^6.0.0       # State management (opcional, preparado)
```

### Node.js
```json
{
  "express": "^4.18.2",
  "cors": "^2.8.5",
  "body-parser": "^1.20.2"
}
```

---

## ⚙️ Configuración

### URL del Servidor
Por defecto: `http://localhost:3000`

Para cambiar, edita [lib/services/api_service.dart](lib/services/api_service.dart):
```dart
static const String baseUrl = 'http://localhost:3000';
```

### Puerto del Servidor
Por defecto: `3000`

Para cambiar, edita [server/server.js](server/server.js):
```javascript
const PORT = 3000;
```

### Emulador Android
En emulador, usa: `http://10.0.2.2:3000` en lugar de `localhost`

---

## 🧪 Pruebas Funcionales

### Test 1: Categorías
✓ Se muestran 4 categorías con iconos
✓ Cada categoría es clickeable

### Test 2: Lista de Jugadores
✓ Se muestran los jugadores de la categoría seleccionada
✓ Cada jugador muestra foto, número, posición

### Test 3: Detalle del Jugador
✓ Se muestra imagen grande
✓ Se muestran todos los datos
✓ Descripción completa visible

### Test 4: Búsqueda
✓ Búsqueda en tiempo real funciona
✓ Resultados se actualizan mientras escribes
✓ Puedo acceder al detalle desde búsqueda

### Test 5: Navegación
✓ Bottom Navigation cambia entre vistas
✓ Botón atrás funciona en todas las vistas
✓ Transiciones suaves entre pantallas

---

## 🐛 Solución de Problemas

### "No puede conectarse al servidor"
1. Verifica que el servidor está corriendo: `npm start`
2. Verifica que está en `http://localhost:3000`
3. En emulador Android, usa `http://10.0.2.2:3000`

### "Las imágenes no cargan"
1. Las imágenes de prueba están deshabilitadas
2. Coloca imágenes en `server/public/images/`
3. Asegúrate de que los nombres coinciden

### "Error de análisis Dart"
Ejecuta:
```bash
flutter analyze
flutter pub get
```

### "Puertos en uso"
Si el puerto 3000 está en uso:
1. Cambia el puerto en `server/server.js`
2. Actualiza la URL en `lib/services/api_service.dart`

---

## 📚 Documentación Adicional

- [README_BETIS.md](README_BETIS.md) - Documentación detallada
- [TESTING.md](TESTING.md) - Guía de pruebas
- [server/server.js](server/server.js) - Código del servidor comentado

---

## ✨ Características Adicionales

- ✓ Bottom Navigation Bar funcional
- ✓ Manejo de errores robusto
- ✓ Estados de carga (spinner)
- ✓ Interfaz responsive
- ✓ Animaciones suaves
- ✓ Código bien estructurado y comentado
- ✓ Scripts de utilidad incluidos

---

## 🎓 Proyecto Educativo

Este proyecto implementa:
- **Arquitectura limpia** en Flutter
- **Patrones de diseño**: MVVM con separación de responsabilidades
- **HTTP API**: Comunicación cliente-servidor
- **Navegación**: Entre múltiples vistas
- **Búsqueda**: Filtrado en tiempo real
- **Gestión de estado**: Sin state management (preparado para Provider)

---

## 👤 Autor

**Víctor Prieto** - DAM2 Interfaces

---

## 📝 Licencia

Proyecto educativo - DAM2 Interfaces 2025/2026

---

**¡Proyecto completado correctamente! ✅**

Todos los requisitos han sido implementados y probados.
