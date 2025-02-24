import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SupabaseService {
  final supabase = Supabase.instance.client;

  /// 📌 Connexion avec Google et gestion de l'utilisateur
  Future<void> signInWithGoogle(Function onUserNotFound) async {
    try {
      print("🔹 Début de la connexion avec Google...");

      final response = await supabase.auth.signInWithOAuth(OAuthProvider.google);

      if (supabase.auth.currentSession == null) {
        print("❌ Erreur : session Google non récupérée.");
        return;
      }

      final user = supabase.auth.currentUser;
      if (user == null) {
        print("❌ Erreur : utilisateur introuvable après connexion.");
        return;
      }

      print("✅ Utilisateur connecté avec Google : ${user.email}");

      // Vérifier si l'utilisateur existe déjà dans la base `User`
      final existingUser = await supabase
          .from('User')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser != null) {
        print("✅ L'utilisateur existe déjà dans la base.");
        return;
      }

      // Si l'utilisateur n'existe pas, déclencher la redirection vers le formulaire
      print("❌ L'utilisateur n'existe pas, redirection vers le formulaire...");
      onUserNotFound(user);
    } catch (e) {
      print("❌ Exception lors de la connexion avec Google : $e");
    }
  }

  /// 📌 Enregistrer un nouvel utilisateur dans la base `User`
  Future<void> saveUserProfile({
    required String userId,
    required String name,
    required String email,
    required double longitude,
    required double latitude,
    required String avatarUrl,
  }) async {
    try {
      print("🔹 Enregistrement du profil utilisateur...");

      await supabase.from('User').insert({
        'id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'name': name.isNotEmpty ? name : "Utilisateur inconnu",
        'email': email,
        'longitude': longitude,
        'latitude': latitude,
        'avatar_url': avatarUrl,
      });

      print("✅ Profil utilisateur enregistré avec succès !");
    } catch (e) {
      print("❌ Erreur lors de l'enregistrement du profil : $e");
    }
  }

  /// 📌 Récupérer tous les utilisateurs de la base `User`
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      print("🔹 Récupération de tous les utilisateurs...");

      final response = await supabase.from('User').select('id, name, email, longitude, latitude, avatar_url');

      if (response.isEmpty) {
        print("❌ Aucun utilisateur trouvé.");
        return [];
      }

      print("✅ Utilisateurs récupérés : ${response.length}");
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("❌ Exception lors de la récupération des utilisateurs : $e");
      return [];
    }
  }

  /// 📌 Uploader un avatar sur Supabase Storage et mettre à jour l'URL
  Future<String?> uploadAvatar(String filePath, String userId) async {
    try {
      print("🔹 Début de l'upload de l'avatar pour $userId...");

      final file = File(filePath);
      if (!file.existsSync()) {
        print("❌ Erreur : fichier non trouvé.");
        return null;
      }

      final response = await supabase.storage.from('avatars').upload(
        'avatars/$userId/avatar.png',
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      if (response.contains("error")) {
        print("❌ Erreur lors de l'upload de l'avatar : $response");
        return null;
      }

      final publicUrl = supabase.storage.from('avatars').getPublicUrl('avatars/$userId/avatar.png');
      print("✅ Avatar uploadé avec succès : $publicUrl");

      // Mise à jour de l'URL de l'avatar dans la base de données
      await supabase.from('User').update({'avatar_url': publicUrl}).eq('id', userId);

      return publicUrl;
    } catch (e) {
      print("❌ Exception lors de l'upload de l'avatar : $e");
      return null;
    }
  }

  /// 📌 Mettre à jour les informations du profil utilisateur
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    double? longitude,
    double? latitude,
    String? avatarUrl,
  }) async {
    try {
      print("🔹 Mise à jour du profil utilisateur...");

      Map<String, dynamic> updates = {};
      if (name != null && name.isNotEmpty) updates['name'] = name;
      if (email != null && email.isNotEmpty) updates['email'] = email;
      if (longitude != null) updates['longitude'] = longitude;
      if (latitude != null) updates['latitude'] = latitude;
      if (avatarUrl != null && avatarUrl.isNotEmpty) updates['avatar_url'] = avatarUrl;

      if (updates.isEmpty) {
        print("❌ Aucun champ à mettre à jour.");
        return;
      }

      await supabase.from('User').update(updates).eq('id', userId);

      print("✅ Profil utilisateur mis à jour !");
    } catch (e) {
      print("❌ Erreur lors de la mise à jour du profil : $e");
    }
  }

  /// 📌 Supprimer un utilisateur
  Future<void> deleteUser(String userId) async {
    try {
      print("🔹 Suppression de l'utilisateur $userId...");

      await supabase.from('User').delete().eq('id', userId);
      print("✅ Utilisateur supprimé avec succès.");
    } catch (e) {
      print("❌ Erreur lors de la suppression de l'utilisateur : $e");
    }
  }
}