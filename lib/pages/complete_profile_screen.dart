import 'package:flutter/material.dart';
import 'package:max_ton_pote_2/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CompleteProfileScreen extends StatefulWidget {
  final String userId;
  final String email;

  const CompleteProfileScreen({Key? key, required this.userId, required this.email}) : super(key: key);

  @override
  _CompleteProfileScreenState createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  String avatarUrl = '';
  File? avatarFile;
  final SupabaseService supabaseService = SupabaseService();

  /// 📌 Fonction pour enregistrer le profil
  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final longitude = double.tryParse(_longitudeController.text) ?? 0.0;
    final latitude = double.tryParse(_latitudeController.text) ?? 0.0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez entrer votre nom")),
      );
      return;
    }

    // Upload l'avatar si une image est sélectionnée
    if (avatarFile != null) {
      final uploadedUrl = await supabaseService.uploadAvatar(avatarFile!.path, widget.userId);
      if (uploadedUrl != null) {
        avatarUrl = uploadedUrl;
      }
    }

    // Enregistrer le profil dans Supabase
    await supabaseService.saveUserProfile(
      userId: widget.userId,
      name: name,
      email: widget.email,
      longitude: longitude,
      latitude: latitude,
      avatarUrl: avatarUrl,
    );

    // Retourner à l'écran précédent après l'enregistrement
    Navigator.pop(context);
  }

  /// 📌 Fonction pour choisir une photo de profil
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        avatarFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Complétez votre profil")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Nom"),
            ),
            TextField(
              controller: _longitudeController,
              decoration: InputDecoration(labelText: "Longitude"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _latitudeController,
              decoration: InputDecoration(labelText: "Latitude"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.image),
              label: Text("Choisir une photo"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }
}