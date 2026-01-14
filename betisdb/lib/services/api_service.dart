import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/category.dart';
import '../models/player.dart';

class ApiService {
  // Usar datos locales con imágenes reales de Transfermark
  static const bool useLocalData = true;
  static const String baseUrl = 'http://127.0.0.1:3000';
  static const String transfermarktApiUrl = 'https://transfermarkt-api.fly.dev';
  static const String realBetisClubId = '23'; // ID del Real Betis en Transfermark

  // Datos locales de categorías
  static final List<Map<String, dynamic>> _categoriesData = [
    {
      'id': '1',
      'name': 'Porteros',
      'description': 'Guardametas',
      'icon': '🧤'
    },
    {
      'id': '2',
      'name': 'Defensas',
      'description': 'Defensa',
      'icon': '🛡️'
    },
    {
      'id': '3',
      'name': 'Centrocampistas',
      'description': 'Mediocampo',
      'icon': '⚙️'
    },
    {
      'id': '4',
      'name': 'Delanteros',
      'description': 'Ataque',
      'icon': '⚽'
    },
    {
      'id': '5',
      'name': 'Cuerpo Técnico',
      'description': 'Entrenador',
      'icon': '📋'
    }
  ];

  // Datos locales de jugadores
  static final List<Map<String, dynamic>> _playersData = [
    // PORTEROS
    {
      'id': '1',
      'name': 'Álvaro Valles',
      'position': 'Portero',
      'category': '1',
      'number': 1,
      'nationality': 'España',
      'description': 'Portero titular del Betis 2025/2026. Guardián de la portería verdiblanca.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/alvaro-valles-real-betis-2023-1695050862-116606.jpg',
      'height': 190,
      'weight': 83,
      'birthDate': '25/11/1997'
    },
    {
      'id': '2',
      'name': 'Pau López',
      'position': 'Portero',
      'category': '1',
      'number': 25,
      'nationality': 'España',
      'description': 'Portero suplente con experiencia en la élite.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/pau-lopez-fc-girona-2022-1630502196-72486.jpg',
      'height': 186,
      'weight': 80,
      'birthDate': '13/04/1994'
    },
    // DEFENSAS
    {
      'id': '3',
      'name': 'Héctor Bellerín',
      'position': 'Lateral Derecho',
      'category': '2',
      'number': 2,
      'nationality': 'España',
      'description': 'Lateral derecho ofensivo con gran velocidad.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/hector-bellerin-real-betis-2023-1725527883-120277.jpg',
      'height': 180,
      'weight': 72,
      'birthDate': '19/03/1995'
    },
    {
      'id': '4',
      'name': 'Diego Llorente',
      'position': 'Defensa Central',
      'category': '2',
      'number': 3,
      'nationality': 'España',
      'description': 'Defensa central español experimentado.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/diego-llorente-real-betis-2023-1632294672-73691.jpg',
      'height': 187,
      'weight': 77,
      'birthDate': '16/02/1993'
    },
    {
      'id': '5',
      'name': 'Natan',
      'position': 'Defensa Central',
      'category': '2',
      'number': 4,
      'nationality': 'Brasil',
      'description': 'Defensa central brasileño con solidez defensiva.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/natan-real-betis-2023-1693905851-115797.jpg',
      'height': 188,
      'weight': 79,
      'birthDate': '15/05/1999'
    },
    {
      'id': '6',
      'name': 'Sergi Altimira',
      'position': 'Lateral Izquierdo',
      'category': '2',
      'number': 6,
      'nationality': 'España',
      'description': 'Lateral izquierdo español con buen manejo defensivo.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/sergi-altimira-real-betis-2023-1693476639-115544.jpg',
      'height': 179,
      'weight': 71,
      'birthDate': '09/10/2001'
    },
    {
      'id': '7',
      'name': 'Ricardo Rodríguez',
      'position': 'Lateral Izquierdo',
      'category': '2',
      'number': 12,
      'nationality': 'Suiza',
      'description': 'Lateral izquierdo suizo experimentado.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/ricardo-rodriguez-torino-fc-2022-1632123806-73687.jpg',
      'height': 181,
      'weight': 73,
      'birthDate': '25/08/1992'
    },
    {
      'id': '8',
      'name': 'Valentín Gómez',
      'position': 'Defensa Central',
      'category': '2',
      'number': 16,
      'nationality': 'Argentina',
      'description': 'Joven defensa central argentino en desarrollo.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/valentin-gomez-velez-sarsfield-2023-1701351886-105843.jpg',
      'height': 190,
      'weight': 82,
      'birthDate': '21/02/2003'
    },
    {
      'id': '9',
      'name': 'Aitor Ruibal',
      'position': 'Lateral Izquierdo',
      'category': '2',
      'number': 24,
      'nationality': 'España',
      'description': 'Lateral izquierdo versátil con capacidad defensiva.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/aitor-ruibal-real-betis-2023-1693817854-115748.jpg',
      'height': 182,
      'weight': 74,
      'birthDate': '29/11/1996'
    },
    {
      'id': '10',
      'name': 'Dani Pérez',
      'position': 'Defensa Central',
      'category': '2',
      'number': 37,
      'nationality': 'España',
      'description': 'Defensa central español en desarrollo.',
      'imageUrl': 'https://img.a.transfermarkt.technology/portrait/big/default.jpg?lm=1',
      'height': 186,
      'weight': 76,
      'birthDate': '15/07/2004'
    },
    {
      'id': '11',
      'name': 'Pablo García',
      'position': 'Defensa Central',
      'category': '2',
      'number': 52,
      'nationality': 'España',
      'description': 'Joven defensa central de la cantera.',
      'imageUrl': 'https://img.a.transfermarkt.technology/portrait/big/default.jpg?lm=1',
      'height': 189,
      'weight': 80,
      'birthDate': '12/09/2003'
    },
    {
      'id': '12',
      'name': 'José Ortiz',
      'position': 'Defensa',
      'category': '2',
      'number': 40,
      'nationality': 'España',
      'description': 'Defensor español con experiencia.',
      'imageUrl': 'https://img.a.transfermarkt.technology/portrait/big/default.jpg?lm=1',
      'height': 185,
      'weight': 75,
      'birthDate': '18/01/2002'
    },
    // CENTROCAMPISTAS
    {
      'id': '13',
      'name': 'Antony',
      'position': 'Extremo Derecho',
      'category': '3',
      'number': 7,
      'nationality': 'Brasil',
      'description': 'Extremo derecho brasileño con gol.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/antony-real-betis-2023-1693817727-115732.jpg',
      'height': 176,
      'weight': 68,
      'birthDate': '24/02/2000'
    },
    {
      'id': '14',
      'name': 'Alexis Fornals',
      'position': 'Centrocampista Ofensivo',
      'category': '3',
      'number': 8,
      'nationality': 'España',
      'description': 'Centrocampista ofensivo español de gran técnica.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/alexis-fornals-real-betis-2023-1693817739-115733.jpg',
      'height': 180,
      'weight': 74,
      'birthDate': '05/08/1996'
    },
    {
      'id': '15',
      'name': 'Chimy Ávila',
      'position': 'Extremo',
      'category': '3',
      'number': 9,
      'nationality': 'Argentina',
      'description': 'Extremo argentino versátil con velocidad.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/joaquin-correa-real-betis-2023-1693817846-115746.jpg',
      'height': 180,
      'weight': 75,
      'birthDate': '26/01/1996'
    },
    {
      'id': '16',
      'name': 'Abde Ezzalzouli',
      'position': 'Extremo Izquierdo',
      'category': '3',
      'number': 10,
      'nationality': 'Marruecos',
      'description': 'Extremo izquierdo marroquí rápido.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/abdessamad-ezzalzouli-real-betis-2023-1693817821-115737.jpg',
      'height': 173,
      'weight': 66,
      'birthDate': '03/01/2001'
    },
    {
      'id': '17',
      'name': 'Bakambu',
      'position': 'Delantero',
      'category': '3',
      'number': 11,
      'nationality': 'Congo',
      'description': 'Delantero congoleño con gol.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/bakambu-real-betis-2023-1693817854-115747.jpg',
      'height': 183,
      'weight': 78,
      'birthDate': '09/08/1994'
    },
    {
      'id': '18',
      'name': 'Adrián San Miguel',
      'position': 'Centrocampista Defensivo',
      'category': '3',
      'number': 13,
      'nationality': 'España',
      'description': 'Centrocampista defensivo español.',
      'imageUrl': 'https://img.a.transfermarkt.technology/portrait/big/default.jpg?lm=1',
      'height': 178,
      'weight': 72,
      'birthDate': '27/04/1995'
    },
    {
      'id': '19',
      'name': 'Sofyan Amrabat',
      'position': 'Centrocampista',
      'category': '3',
      'number': 14,
      'nationality': 'Marruecos',
      'description': 'Centrocampista marroquí polivalente.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/sofyan-amrabat-real-betis-2023-1693817780-115734.jpg',
      'height': 183,
      'weight': 76,
      'birthDate': '21/08/1996'
    },
    {
      'id': '20',
      'name': 'Javier Riquelme',
      'position': 'Centrocampista',
      'category': '3',
      'number': 17,
      'nationality': 'España',
      'description': 'Centrocampista español del Betis B.',
      'imageUrl': 'https://img.a.transfermarkt.technology/portrait/big/default.jpg?lm=1',
      'height': 181,
      'weight': 73,
      'birthDate': '10/03/2001'
    },
    {
      'id': '21',
      'name': 'Nelson Deossa',
      'position': 'Centrocampista Defensivo',
      'category': '3',
      'number': 18,
      'nationality': 'Colombia',
      'description': 'Centrocampista defensivo colombiano.',
      'imageUrl': 'https://img.a.transfermarkt.technology/portrait/big/default.jpg?lm=1',
      'height': 185,
      'weight': 78,
      'birthDate': '17/04/2000'
    },
    {
      'id': '22',
      'name': 'Giovani Lo Celso',
      'position': 'Mediapunta',
      'category': '3',
      'number': 20,
      'nationality': 'Argentina',
      'description': 'Mediapunta argentino de gran técnica.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/giovani-lo-celso-real-betis-2023-1693817869-115742.jpg',
      'height': 180,
      'weight': 75,
      'birthDate': '09/04/1996'
    },
    {
      'id': '23',
      'name': 'Marc Roca',
      'position': 'Centrocampista Defensivo',
      'category': '3',
      'number': 21,
      'nationality': 'España',
      'description': 'Centrocampista defensivo español.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/marc-roca-real-betis-2023-1693477023-115549.jpg',
      'height': 184,
      'weight': 77,
      'birthDate': '05/12/1996'
    },
    {
      'id': '24',
      'name': 'Isco Alarcón',
      'position': 'Centrocampista Ofensivo',
      'category': '3',
      'number': 22,
      'nationality': 'España',
      'description': 'Centrocampista ofensivo español experimentado.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/isco-alarcon-real-betis-2023-1693817788-115735.jpg',
      'height': 176,
      'weight': 73,
      'birthDate': '21/04/1992'
    },
    {
      'id': '25',
      'name': 'Junior Firpo',
      'position': 'Lateral Izquierdo',
      'category': '3',
      'number': 23,
      'nationality': 'República Dominicana',
      'description': 'Lateral izquierdo dominicano versátil.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/junior-firpo-real-betis-2023-1693817812-115740.jpg',
      'height': 180,
      'weight': 72,
      'birthDate': '04/04/1996'
    },
    {
      'id': '26',
      'name': 'Juan Miranda',
      'position': 'Lateral Izquierdo',
      'category': '3',
      'number': 23,
      'nationality': 'España',
      'description': 'Lateral izquierdo español de la cantera.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/juan-miranda-real-betis-2023-1693817804-115739.jpg',
      'height': 179,
      'weight': 70,
      'birthDate': '01/10/2000'
    },
    {
      'id': '27',
      'name': 'Carlos Corralero',
      'position': 'Centrocampista',
      'category': '3',
      'number': 21,
      'nationality': 'España',
      'description': 'Centrocampista español del Betis B.',
      'imageUrl': 'https://img.a.transfermarkt.technology/portrait/big/default.jpg?lm=1',
      'height': 182,
      'weight': 73,
      'birthDate': '15/07/2002'
    },
    // DELANTEROS
    {
      'id': '28',
      'name': 'Cucho Hernández',
      'position': 'Delantero Centro',
      'category': '4',
      'number': 19,
      'nationality': 'Colombia',
      'description': 'Delantero colombiano con gol.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/cucho-hernandez-real-betis-2023-1693817829-115741.jpg',
      'height': 183,
      'weight': 77,
      'birthDate': '09/06/1999'
    },
    // CUERPO TÉCNICO
    {
      'id': '29',
      'name': 'Manuel Pellegrini',
      'position': 'Entrenador',
      'category': '5',
      'number': 0,
      'nationality': 'Chile',
      'description': 'Entrenador del Real Betis.',
      'imageUrl': 'https://tmssl.akamaized.net/images/foto/galerie/manuel-pellegrini-real-betis-2023-1693817663-115728.jpg',
      'height': 170,
      'weight': 70,
      'birthDate': '01/09/1953'
    }
  ];

  // Obtener categorías
  static Future<List<Category>> getCategories() async {
    // Siempre usar datos locales para categorías
    return _categoriesData
        .map((item) => Category.fromJson(item))
        .toList();
  }

  // Obtener jugadores por categoría
  static Future<List<Player>> getPlayersByCategory(String categoryId) async {
    // Usar datos locales con imágenes de la API cuando sea necesario
    try {
      // Intentar obtener jugadores de la API primero
      if (!useLocalData) {
        final response = await http.get(
          Uri.parse('$transfermarktApiUrl/clubs/$realBetisClubId/players'),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> players = data['players'] ?? data['squad'] ?? [];

          // Filtrar por categoría/posición
          final filteredPlayers = players.where((player) {
            final position = (player['position'] ?? '').toString().toLowerCase();
            return _matchesCategory(position, categoryId);
          }).toList();

          if (filteredPlayers.isNotEmpty) {
            return filteredPlayers
                .map((item) => _convertTransfermarktPlayerToModel(item))
                .toList();
          }
        }
      }
    } catch (e) {
      print('Error fetching from API: $e');
    }

    // Fallback a datos locales con imágenes reales
    final players = _playersData
        .where((p) => p['category'] == categoryId)
        .toList();
    return players.map((item) => Player.fromJson(item)).toList();
  }

  // Helper para convertir respuesta de Transfermark al modelo Player
  static Player _convertTransfermarktPlayerToModel(dynamic transfermarktPlayer) {
    final position = transfermarktPlayer['position'] ?? 'Unknown';
    final category = _getCategory(position.toString());
    
    return Player(
      id: (transfermarktPlayer['id'] ?? '').toString(),
      name: transfermarktPlayer['name'] ?? 'Unknown',
      position: position,
      category: category,
      number: int.tryParse((transfermarktPlayer['number'] ?? '0').toString()) ?? 0,
      nationality: transfermarktPlayer['country'] ?? 'Unknown',
      description: transfermarktPlayer['name'] ?? '',
      imageUrl: transfermarktPlayer['image'] ?? '',
      height: int.tryParse((transfermarktPlayer['height'] ?? '0').toString()) ?? 0,
      weight: int.tryParse((transfermarktPlayer['weight'] ?? '0').toString()) ?? 0,
      birthDate: transfermarktPlayer['date_of_birth'] ?? 'Unknown',
    );
  }

  // Helper para obtener categoría basada en posición
  static String _getCategory(String position) {
    position = position.toLowerCase();
    
    if (position.contains('goalkeeper') || position.contains('portero') || position.contains('gk')) {
      return '1';
    } else if (position.contains('defender') || position.contains('defensa') || 
               position.contains('left') || position.contains('right') || 
               position.contains('back') || position.contains('centre')) {
      return '2';
    } else if (position.contains('midfielder') || position.contains('centrocampista') || 
               position.contains('winger') || position.contains('extremo') ||
               position.contains('mediapunta')) {
      return '3';
    } else if (position.contains('striker') || position.contains('delantero') || 
               (position.contains('forward') && !position.contains('midfielder'))) {
      return '4';
    } else if (position.contains('trainer') || position.contains('coach') || position.contains('entrenador')) {
      return '5';
    }
    return '3'; // Default a centrocampista
  }

  // Helper para mapear posiciones a categorías
  static bool _matchesCategory(String position, String categoryId) {
    position = position.toLowerCase();
    
    switch (categoryId) {
      case '1': // Porteros
        return position.contains('goalkeeper') || position.contains('portero') || position.contains('gk');
      case '2': // Defensas
        return position.contains('defender') || position.contains('defensa') || 
               position.contains('left') || position.contains('right') || 
               position.contains('back') || position.contains('centre');
      case '3': // Centrocampistas
        return position.contains('midfielder') || position.contains('centrocampista') || 
               position.contains('forward') || position.contains('winger') ||
               position.contains('extremo') || position.contains('mediapunta');
      case '4': // Delanteros
        return position.contains('striker') || position.contains('delantero') || 
               position.contains('forward') && !position.contains('midfielder');
      case '5': // Cuerpo técnico
        return position.contains('trainer') || position.contains('coach') || position.contains('entrenador');
      default:
        return false;
    }
  }

  // Obtener detalle de jugador
  static Future<Player?> getPlayerDetail(String playerId) async {
    try {
      // Primero intentar obtener del local
      final playerData = _playersData.firstWhere(
        (p) => p['id'].toString() == playerId,
        orElse: () => {},
      );
      
      if (playerData.isNotEmpty) {
        return Player.fromJson(playerData);
      }
      
      // Si no está en local, intentar la API
      if (!useLocalData) {
        final response = await http.get(
          Uri.parse('$transfermarktApiUrl/players/$playerId/profile'),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return _convertTransfermarktPlayerToModel(data);
        }
      }
    } catch (e) {
      print('Error fetching player detail: $e');
    }
    
    return null;
  }

  // Buscar jugadores
  static Future<List<Player>> searchPlayers(String query) async {
    if (useLocalData) {
      final searchResults = _playersData
          .where((p) =>
              (p['name'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
              (p['position'] ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              (p['nationality'] ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();

      return searchResults.map((item) => Player.fromJson(item)).toList();
    }

    try {
      // Buscar jugadores en Transfermark
      final response = await http.get(
        Uri.parse('$transfermarktApiUrl/players/search/$query'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['players'] ?? [];
        
        // Filtrar solo jugadores del Real Betis
        final betisPlayers = results
            .where((player) =>
                (player['club_id'] ?? '').toString() == realBetisClubId)
            .toList();

        return betisPlayers
            .map((item) => _convertTransfermarktPlayerToModel(item))
            .toList();
      } else {
        throw Exception('Error en la búsqueda');
      }
    } catch (e) {
      print('Error searching players: $e');
      // Fallback a búsqueda local
      final searchResults = _playersData
          .where((p) =>
              (p['name'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
              (p['position'] ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              (p['nationality'] ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();

      return searchResults.map((item) => Player.fromJson(item)).toList();
    }
  }

  // Obtener imagen
  static String getImageUrl(String imagePath) {
    // Si la ruta ya es una URL completa (http/https), devolverla tal cual
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    // Si no, construir la URL del servidor
    return '$baseUrl/images/$imagePath';
  }
}
