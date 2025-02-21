import 'package:flutter/material.dart';

class FavoritesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> favorites;
  final Function(Map<String, dynamic>) toggleFavorite;

  const FavoritesScreen({super.key, required this.favorites, required this.toggleFavorite});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favoris"), centerTitle: true, backgroundColor: Colors.red),
      body: favorites.isEmpty
          ? const Center(child: Text("Aucun favori ajouté.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
          : ListView.builder(
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final user = favorites[index];
          return ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(user['imageURL'])),
            title: Text(user['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            subtitle: Text("${user['age']} ans • ${user['distance'].toStringAsFixed(1)} km • ${user['city']}"),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () => toggleFavorite(user), // ❌ Retirer des favoris
            ),
          );
        },
      ),
    );
  }
}