import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';

class AddPostPage extends StatefulWidget {
  final String initialType;
  final Map<String, dynamic>? quotedPost; // Alıntılanan post
  final File? initialImage;

  const AddPostPage({Key? key, this.initialType = 'post', this.quotedPost, this.initialImage}) : super(key: key);

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final TextEditingController _contentController = TextEditingController();
  File? _selectedImage;
  late String _selectedType;
  bool _isLoading = false;

  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.quotedPost != null ? 'quote' : widget.initialType;
    if (widget.initialImage != null) {
      _selectedImage = widget.initialImage;
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _sharePost() async {
    if (_contentController.text.trim().isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bir resim seçin veya içerik yazın.")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _supabaseService.createPost(
        content: _contentController.text.trim(),
        imageFile: _selectedImage,
        type: _selectedType,
        quotedPostId: widget.quotedPost?['id'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Başarıyla paylaşıldı!")));
        Navigator.pop(context, true); // True dönerek kameranın da kapanmasını tetikle
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        title: const Text("Yeni Paylaşım", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _sharePost,
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2))
                : const Text("Paylaş", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.quotedPost != null) ...[
              // Alıntılanan postun önizlemesi
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: Border.all(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "@${widget.quotedPost!['profiles']?['username'] ?? 'Kullanıcı'}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.quotedPost!['content'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white54),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Gönderi Tipi Seçimi (Yalnızca normal post atılırken)
              Row(
                children: [
                  const Text("Tür:", style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _selectedType,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    items: const [
                      DropdownMenuItem(value: 'post', child: Text("Gönderi (Post)")),
                      DropdownMenuItem(value: 'reel', child: Text("Video (Reel)")),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // İçerik / Açıklama Alanı
            TextField(
              controller: _contentController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Neler düşünüyorsun?",
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 20),
            
            // Resim/Medya Seçim Alanı
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 60, color: Colors.grey[600]),
                          const SizedBox(height: 8),
                          Text("Galeri'den Seç", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
