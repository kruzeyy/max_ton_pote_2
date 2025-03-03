import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> favorites;
  final Function(Map<String, dynamic>) toggleFavorite;

  const FavoritesScreen({
    super.key,
    required this.favorites,
    required this.toggleFavorite,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> favoriteUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 🔍 Récupérer l'utilisateur courant et sa liste de favoris
      final response = await supabase
          .from('User')
          .select('favorites')
          .eq('email', user.email as Object)
          .single();

      if (response == null || response['favorites'] == null) {
        setState(() {
          favoriteUsers = [];
          isLoading = false;
        });
        return;
      }

      List<String> favoriteEmails = List<String>.from(response['favorites']);

      if (favoriteEmails.isEmpty) {
        setState(() {
          favoriteUsers = [];
          isLoading = false;
        });
        return;
      }

      // 🔄 Récupérer les données des utilisateurs favoris
      final usersResponse = await supabase
          .from('User')
          .select('name, email, age, city, avatar_url')
          .contains('email', favoriteEmails);
      setState(() {
        favoriteUsers = List<Map<String, dynamic>>.from(usersResponse);
        isLoading = false;
      });
    } catch (error) {
      print('Erreur lors de la récupération des favoris : $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(Map<String, dynamic> user) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      final response = await supabase
          .from('User')
          .select('favorites')
          .eq('email', currentUser.email as Object)
          .single();

      if (response == null || response['favorites'] == null) return;

      List<String> favoriteEmails = List<String>.from(response['favorites']);

      if (favoriteEmails.contains(user['email'])) {
        favoriteEmails.remove(user['email']);
      } else {
        favoriteEmails.add(user['email']);
      }

      await supabase
          .from('User')
          .update({'favorites': favoriteEmails})
          .eq('email', currentUser.email as Object);

      _fetchFavorites();
    } catch (error) {
      print('Erreur lors de la mise à jour des favoris : $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favoris"),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteUsers.isEmpty
          ? const Center(
        child: Text(
          "Aucun favori ajouté.",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      )
          : ListView.builder(
        itemCount: favoriteUsers.length,
        itemBuilder: (context, index) {
          final user = favoriteUsers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(user['avatar_url']),
            ),
            title: Text(
              user['name'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "${user['age']} ans • ${user['city']}",
            ),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () => _toggleFavorite(user),
            ),
          );
        },
      ),
    );
  }
}