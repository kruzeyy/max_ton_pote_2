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

      // Vérifier si l'utilisateur existe déjà
      final existingUser = await supabase
          .from('User')
          .select('id, avatar_url, description') // 🔹 Ajout de description
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser != null) {
        print("✅ L'utilisateur existe déjà. Avatar : ${existingUser['avatar_url']}");
        return;
      }

      // Redirection vers le formulaire
      print("❌ L'utilisateur n'existe pas, redirection vers le formulaire...");
      onUserNotFound(user);
    } catch (e) {
      print("❌ Exception lors de la connexion avec Google : $e");
    }
  }

  /// 📌 Récupérer un utilisateur spécifique
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      print("🔹 Récupération de l'utilisateur $userId...");

      final response = await supabase
          .from('User')
          .select('id, name, email, longitude, latitude, avatar_url, description') // 🔹 Ajout de description
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        print("❌ Utilisateur non trouvé.");
        return null;
      }

      print("✅ Utilisateur récupéré : ${response['name']}, Avatar : ${response['avatar_url']}, Description : ${response['description']}");
      return response;
    } catch (e) {
      print("❌ Erreur lors de la récupération de l'utilisateur : $e");
      return null;
    }
  }

  /// 📌 Enregistrer un nouvel utilisateur avec avatar et description
  Future<void> saveUserProfile({
    required String userId,
    required String name,
    required String email,
    required double longitude,
    required double latitude,
    required String? avatarFilePath,
    required String description,
  }) async {
    try {
      print("🔹 Enregistrement du profil utilisateur...");

      String? avatarUrl;
      if (avatarFilePath != null) {
        avatarUrl = await uploadAvatar(avatarFilePath, userId);
      }

      await supabase.from('User').insert({
        'id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'name': name.isNotEmpty ? name : "Utilisateur inconnu",
        'email': email,
        'longitude': longitude,
        'latitude': latitude,
        'avatar_url': avatarUrl ?? "",
        'description': description,
      });

      print("✅ Profil utilisateur enregistré avec succès !");

      // Vérifier si l'utilisateur est bien enregistré
      final user = await getUserById(userId);
      if (user != null) {
        print("🔹 Vérification Avatar URL : ${user['avatar_url']}, Description : ${user['description']}");
      }
    } catch (e) {
      print("❌ Erreur lors de l'enregistrement du profil : $e");
    }
  }

  /// 📌 Récupérer tous les utilisateurs
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      print("🔹 Requête pour récupérer les utilisateurs en cours...");
      final currentUser = supabase.auth.currentUser;
      final response = await supabase
          .from('User')
          .select('*')
          .neq('id', currentUser?.id as Object); // Exclut l'utilisateur connecté

      print("🔍 Réponse brute de Supabase : $response");

      if (response == null || response.isEmpty) {
        print("⚠️ Aucun utilisateur trouvé dans la base de données.");
        return [];
      }

      print("✅ Utilisateurs récupérés depuis Supabase : ${response.length}");
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("❌ Erreur Supabase lors de la récupération des utilisateurs : $e");
      return [];
    }
  }

  /// 📌 Uploader un avatar et mettre à jour l'URL
  Future<String?> uploadAvatar(String filePath, String userId) async {
    try {
      print("🔹 Début de l'upload de l'avatar pour $userId...");

      final file = File(filePath);
      if (!file.existsSync()) {
        print("❌ Erreur : fichier non trouvé.");
        return null;
      }

      // Génération d'un nom unique
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';

      final response = await supabase.storage.from('avatars').upload(
        'avatars/$userId/$fileName',
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      if (response.contains("error")) {
        print("❌ Erreur lors de l'upload de l'avatar : $response");
        return null;
      }

      final publicUrl = supabase.storage.from('avatars').getPublicUrl('avatars/$userId/$fileName');
      print("✅ Avatar uploadé avec succès : $publicUrl");

      // Mise à jour de l'URL de l'avatar
      await supabase.from('User').update({'avatar_url': publicUrl}).eq('id', userId);

      return publicUrl;
    } catch (e) {
      print("❌ Exception lors de l'upload de l'avatar : $e");
      return null;
    }
  }

  /// 📌 Mettre à jour le profil utilisateur
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    double? longitude,
    double? latitude,
    String? avatarFilePath,
    String? description,
  }) async {
    try {
      print("🔹 Mise à jour du profil utilisateur...");

      Map<String, dynamic> updates = {};

      if (name != null && name.isNotEmpty) updates['name'] = name;
      if (email != null && email.isNotEmpty) updates['email'] = email;
      if (longitude != null) updates['longitude'] = longitude;
      if (latitude != null) updates['latitude'] = latitude;
      if (description != null && description.isNotEmpty) updates['description'] = description;

      if (avatarFilePath != null && avatarFilePath.isNotEmpty) {
        String? newAvatarUrl = await uploadAvatar(avatarFilePath, userId);
        if (newAvatarUrl != null) {
          updates['avatar_url'] = newAvatarUrl;
        }
      }

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