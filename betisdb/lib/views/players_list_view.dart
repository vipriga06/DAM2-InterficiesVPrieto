import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/api_service.dart';
import 'player_detail_view.dart';

class PlayersListView extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const PlayersListView({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<PlayersListView> createState() => _PlayersListViewState();
}

class _PlayersListViewState extends State<PlayersListView> {
  late Future<List<Player>> _players;

  @override
  void initState() {
    super.initState();
    _players = ApiService.getPlayersByCategory(widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      body: FutureBuilder<List<Player>>(
        future: _players,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay jugadores en esta categoría'));
          }

          final players = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      color: Colors.green[200],
                    ),
                    child: Image.network(
                      ApiService.getImageUrl(player.imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.person,
                            color: Colors.green[800],
                          ),
                        );
                      },
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
                        style: TextStyle(color: Colors.green[700]),
                      ),
                      Text(
                        player.nationality,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward, color: Colors.green[800]),
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
          );
        },
      ),
    );
  }
}
