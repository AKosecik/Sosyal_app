import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditProfilePage({Key? key, required this.initialData}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _usernameController;
  late TextEditingController _fullNameController;
  late TextEditingController _bioController;

  File? _avatarFile;
  File? _coverFile;

  bool _isLoading = false;
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialData['username'] ?? '');
    _fullNameController = TextEditingController(text: widget.initialData['full_name'] ?? '');
    _bioController = TextEditingController(text: widget.initialData['bio'] ?? '');
  }

  Future<void> _pickImage(bool isAvatar) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isAvatar) {
          _avatarFile = File(image.path);
        } else {
          _coverFile = File(image.path);
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    
    try {
      await _supabaseService.updateProfile(
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        bio: _bioController.text.trim(),
        avatarFile: _avatarFile,
        coverFile: _coverFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil başarıyla güncellendi!")));
        Navigator.pop(context, true); // true = profil güncellendi
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Profili Düzenle", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isLoading ? const CircularProgressIndicator(color: Colors.blueAccent) : const Icon(Icons.check, color: Colors.blueAccent),
            onPressed: _isLoading ? null : _saveProfile,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Kapak Resmi Alanı
            Builder(
              builder: (context) {
                final String? dbCover = widget.initialData['cover_url'];
                final String? initCover = (dbCover != null && !dbCover.contains('picsum.photos')) ? dbCover : null;
                return GestureDetector(
                  onTap: () => _pickImage(false),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      image: _coverFile != null
                          ? DecorationImage(image: FileImage(_coverFile!), fit: BoxFit.cover)
                          : (initCover != null
                              ? DecorationImage(image: NetworkImage(initCover), fit: BoxFit.cover)
                              : null),
                    ),
                    child: _coverFile == null && initCover == null
                        ? const Icon(Icons.add_a_photo, color: Colors.white54, size: 40)
                        : Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(Icons.edit, color: Colors.white.withOpacity(0.8)),
                            ),
                          ),
                  ),
                );
              }
            ),
            const SizedBox(height: 20),
            
            // Profil Resmi Alanı
            Builder(
              builder: (context) {
                final String? dbAvatar = widget.initialData['avatar_url'];
                final String? initAvatar = (dbAvatar != null && !dbAvatar.contains('picsum.photos')) ? dbAvatar : null;
                return GestureDetector(
                  onTap: () => _pickImage(true),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: _avatarFile != null
                            ? FileImage(_avatarFile!) as ImageProvider
                            : (initAvatar != null ? NetworkImage(initAvatar) : null),
                        child: (_avatarFile == null && initAvatar == null)
                            ? const Icon(Icons.person, size: 50, color: Colors.white54)
                            : null,
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                );
              }
            ),
            const SizedBox(height: 30),

            // Form Alanları
            _buildTextField("Kullanıcı Adı", _usernameController),
            const SizedBox(height: 16),
            _buildTextField("Ad Soyad", _fullNameController),
            const SizedBox(height: 16),
            _buildTextField("Biyografi", _bioController, maxLines: 3),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                onPressed: _isLoading ? null : _saveProfile,
                child: const Text("Kaydet", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
