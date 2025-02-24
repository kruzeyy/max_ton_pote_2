import 'package:flutter/material.dart';
import 'package:max_ton_pote_2/services/supabase_service.dart';
import 'package:flutter/material.dart';

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  /// 📌 Fonction pour récupérer les utilisateurs depuis Supabase
  Future<void> _fetchUsers() async {
    final service = SupabaseService();
    List<Map<String, dynamic>> fetchedUsers = await service.getAllUsers();
    setState(() {
      users = fetchedUsers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Liste des Utilisateurs")),
      body: users.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            title: Text(user['name'] ?? 'Utilisateur inconnu'),
            subtitle: Text(user['email'] ?? 'Email inconnu'),
          );
        },
      ),
    );
  }
}

class UserList extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final Function(Map<String, dynamic>) toggleFavorite;
  final List<Map<String, dynamic>> favorites;

  const UserList({
    super.key,
    required this.users,
    required this.toggleFavorite,
    required this.favorites,
  });

  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = widget.users;
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers =
          widget.users
              .where(
                (user) =>
                    user['name'].toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(user['imageURL']),
              ),
              const SizedBox(height: 10),
              Text(
                user['name'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "${user['age']} ans",
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 15),
              Text(
                user['description'],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Text(
                "Distance : ${user['distance'].toStringAsFixed(1)} km",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Ville : ${user['city']}",
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ), // 🔥 Ajout de la ville
              ElevatedButton.icon(
                icon: Icon(
                  widget.favorites.contains(user)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: Colors.white,
                ),
                label: Text(
                  widget.favorites.contains(user)
                      ? "Retirer des favoris"
                      : "Ajouter aux favoris",
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  widget.toggleFavorite(user);
                  Navigator.pop(context); // Fermer le modal après l'action
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Max ton pote"),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Rechercher un utilisateur",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user['imageURL']),
                  ),
                  title: Text(
                    user['name'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      widget.favorites.contains(user)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: () => widget.toggleFavorite(user),
                  ),
                  onTap: () => _showUserDetails(context, user),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
