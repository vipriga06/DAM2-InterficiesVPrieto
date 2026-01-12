const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Datos de categorías
const categories = [
  {
    id: '1',
    name: 'Porteros',
    description: 'Guardametas',
    icon: '🧤'
  },
  {
    id: '2',
    name: 'Defensas',
    description: 'Defensa',
    icon: '🛡️'
  },
  {
    id: '3',
    name: 'Centrocampistas',
    description: 'Mediocampo',
    icon: '⚙️'
  },
  {
    id: '4',
    name: 'Delanteros',
    description: 'Ataque',
    icon: '⚽'
  }
];

// Datos de jugadores del Betis 2025/2026
const players = [
  // Porteros
  {
    id: '1',
    name: 'Rui Silva',
    position: 'Portero',
    category: '1',
    number: 1,
    nationality: 'Portugal',
    description: 'Experimentado portero portugués. Conocido por su seguridad bajo palos y excelente distribución de balón.',
    imageUrl: 'rui-silva.jpg',
    height: 189,
    weight: 82,
    birthDate: '15/01/1989'
  },
  {
    id: '2',
    name: 'Fran Vieites',
    position: 'Portero',
    category: '1',
    number: 13,
    nationality: 'España',
    description: 'Joven portero español con mucho potencial. Está en pleno desarrollo de su carrera profesional.',
    imageUrl: 'fran-vieites.jpg',
    height: 187,
    weight: 80,
    birthDate: '20/08/2003'
  },

  // Defensas
  {
    id: '3',
    name: 'Aitor Ruibal',
    position: 'Defensa',
    category: '2',
    number: 3,
    nationality: 'España',
    description: 'Lateral izquierdo versátil con gran capacidad defensiva y participación en ataque.',
    imageUrl: 'aitor-ruibal.jpg',
    height: 182,
    weight: 74,
    birthDate: '29/11/1996'
  },
  {
    id: '4',
    name: 'Germán Pezzella',
    position: 'Defensa',
    category: '2',
    number: 4,
    nationality: 'Argentina',
    description: 'Defensa central experimentado y líder del equipo. Excelente en el juego aéreo.',
    imageUrl: 'german-pezzella.jpg',
    height: 188,
    weight: 78,
    birthDate: '27/06/1992'
  },
  {
    id: '5',
    name: 'Edgar González',
    position: 'Defensa',
    category: '2',
    number: 2,
    nationality: 'España',
    description: 'Lateral derecho rápido y defensivamente sólido. Buen en acciones recuperadas.',
    imageUrl: 'edgar-gonzalez.jpg',
    height: 180,
    weight: 72,
    birthDate: '10/02/1998'
  },
  {
    id: '6',
    name: 'Zouma',
    position: 'Defensa',
    category: '2',
    number: 5,
    nationality: 'Francia',
    description: 'Defensa central potente y con buena técnica. Experimentado en competiciones internacionales.',
    imageUrl: 'zouma.jpg',
    height: 187,
    weight: 80,
    birthDate: '27/12/1994'
  },

  // Centrocampistas
  {
    id: '7',
    name: 'Giovani Lo Celso',
    position: 'Centrocampista',
    category: '3',
    number: 8,
    nationality: 'Argentina',
    description: 'Mediapunta ofensivo de gran técnica. Creador de juego y peligroso en la transición.',
    imageUrl: 'lo-celso.jpg',
    height: 180,
    weight: 75,
    birthDate: '09/04/1996'
  },
  {
    id: '8',
    name: 'Guido Rodríguez',
    position: 'Centrocampista',
    category: '3',
    number: 17,
    nationality: 'Argentina',
    description: 'Volante defensivo robusto. Recuperador de balones y organizador del juego.',
    imageUrl: 'guido-rodriguez.jpg',
    height: 183,
    weight: 79,
    birthDate: '09/06/1994'
  },
  {
    id: '9',
    name: 'Dani Martin',
    position: 'Centrocampista',
    category: '3',
    number: 6,
    nationality: 'España',
    description: 'Centrocampista box-to-box versátil. Buen físico y capacidad defensiva.',
    imageUrl: 'dani-martin.jpg',
    height: 185,
    weight: 77,
    birthDate: '14/03/1996'
  },
  {
    id: '10',
    name: 'Abner',
    position: 'Centrocampista',
    category: '3',
    number: 11,
    nationality: 'Brasil',
    description: 'Extremo brasileño rápido y desequilibrante. Excelente en el uno contra uno.',
    imageUrl: 'abner.jpg',
    height: 177,
    weight: 70,
    birthDate: '17/11/1999'
  },

  // Delanteros
  {
    id: '11',
    name: 'Ayoze Pérez',
    position: 'Delantero',
    category: '4',
    number: 10,
    nationality: 'España',
    description: 'Delantero letal y referencia ofensiva del equipo. Gran capacidad goleadora.',
    imageUrl: 'ayoze-perez.jpg',
    height: 183,
    weight: 75,
    birthDate: '09/07/1990'
  },
  {
    id: '12',
    name: 'Nabil Fekir',
    position: 'Delantero',
    category: '4',
    number: 7,
    nationality: 'Francia',
    description: 'Extremo versátil con excelente técnica. Peligroso en ambas bandas.',
    imageUrl: 'nabil-fekir.jpg',
    height: 180,
    weight: 73,
    birthDate: '18/07/1994'
  },
  {
    id: '13',
    name: 'Juanmi',
    position: 'Delantero',
    category: '4',
    number: 9,
    nationality: 'España',
    description: 'Delantero agresivo y combativo. Excelente en el juego aéreo y las segundas jugadas.',
    imageUrl: 'juanmi.jpg',
    height: 184,
    weight: 78,
    birthDate: '14/03/1992'
  },
  {
    id: '14',
    name: 'William Carvalho',
    position: 'Delantero',
    category: '4',
    number: 14,
    nationality: 'Portugal',
    description: 'Extremo portugués rápido y con buen remate. Peligroso en transición.',
    imageUrl: 'william-carvalho.jpg',
    height: 178,
    weight: 71,
    birthDate: '04/04/1992'
  }
];

// Rutas de API

// GET categorías
app.post('/api/categories', (req, res) => {
  res.json(categories);
});

// GET jugadores por categoría
app.post('/api/players/category', (req, res) => {
  const { categoryId } = req.body;
  const playersByCategory = players.filter(p => p.category === categoryId);
  res.json(playersByCategory);
});

// GET detalle de jugador
app.post('/api/players/detail', (req, res) => {
  const { playerId } = req.body;
  const player = players.find(p => p.id === playerId);
  
  if (player) {
    res.json(player);
  } else {
    res.status(404).json({ error: 'Jugador no encontrado' });
  }
});

// GET búsqueda de jugadores
app.post('/api/players/search', (req, res) => {
  const { query } = req.body;
  
  if (!query || query.trim() === '') {
    return res.json([]);
  }

  const searchResults = players.filter(player =>
    player.name.toLowerCase().includes(query.toLowerCase()) ||
    player.position.toLowerCase().includes(query.toLowerCase()) ||
    player.nationality.toLowerCase().includes(query.toLowerCase())
  );

  res.json(searchResults);
});

// Servir imágenes estáticas
app.use('/images', express.static(path.join(__dirname, 'public/images')));

// Crear carpeta de imágenes si no existe
const imagesDir = path.join(__dirname, 'public/images');
if (!fs.existsSync(imagesDir)) {
  fs.mkdirSync(imagesDir, { recursive: true });
}

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`Servidor Betis DB ejecutándose en http://localhost:${PORT}`);
  console.log(`Endpoints disponibles:`);
  console.log(`  POST http://localhost:${PORT}/api/categories`);
  console.log(`  POST http://localhost:${PORT}/api/players/category`);
  console.log(`  POST http://localhost:${PORT}/api/players/detail`);
  console.log(`  POST http://localhost:${PORT}/api/players/search`);
  console.log(`  GET  http://localhost:${PORT}/images/{image}`);
});
