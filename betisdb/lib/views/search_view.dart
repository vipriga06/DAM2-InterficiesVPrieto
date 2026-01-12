import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/api_service.dart';
import 'player_detail_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  List<Player> _allPlayers = [];
  List<Player> _searchResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllPlayers();
  }

  Future<void> _loadAllPlayers() async {
    try {
      // Cargar todos los jugadores de todas las categorías
      final porteros = await ApiService.getPlayersByCategory('1');
      final defensas = await ApiService.getPlayersByCategory('2');
      final centrocampistas = await ApiService.getPlayersByCategory('3');
      final delanteros = await ApiService.getPlayersByCategory('4');
      final cuerpoTecnico = await ApiService.getPlayersByCategory('5');
      
      if (mounted) {
        setState(() {
          _allPlayers = [
            ...porteros,
            ...defensas,
            ...centrocampistas,
            ...delanteros,
            ...cuerpoTecnico,
          ];
          _searchResults = _allPlayers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar jugadores: $e')),
        );
      }
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = _allPlayers;
      });
      return;
    }

    final results = _allPlayers.where((player) =>
        player.name.toLowerCase().contains(query.toLowerCase()) ||
        player.position.toLowerCase().contains(query.toLowerCase()) ||
        player.nationality.toLowerCase().contains(query.toLowerCase())).toList();

    setState(() {
      _searchResults = results;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Jugadores'),
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            color: Colors.green[800],
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Buscar jugador...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = _allPlayers;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Resultados de búsqueda
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'No hay jugadores disponibles'
                              : 'No se encontraron resultados',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final player = _searchResults[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Colors.green[600]!, Colors.green[900]!],
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    ApiService.getImageUrl(player.imageUrl),
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              title: Text(
                                player.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#${player.number} - ${player.position}',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  Text(
                                    player.nationality,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.arrow_forward,
                                color: Colors.green[800],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayerDetailView(
                                      playerId: player.id,
                                      player: player,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
