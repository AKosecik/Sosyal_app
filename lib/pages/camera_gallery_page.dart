import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:photo_manager/photo_manager.dart';
import 'add_post_page.dart';
import '../services/supabase_service.dart';

class CameraGalleryPage extends StatefulWidget {
  final bool isStoryMode;
  const CameraGalleryPage({super.key, this.isStoryMode = false});

  @override
  State<CameraGalleryPage> createState() => _CameraGalleryPageState();
}

class _CameraGalleryPageState extends State<CameraGalleryPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  
  List<AssetEntity> _mediaList = [];
  bool _isLoadingGallery = true;

  final SupabaseService _supabaseService = SupabaseService();
  bool _isUploading = false;

  late String _selectedContentType;
  late final List<String> _contentTypes;

  @override
  void initState() {
    super.initState();
    if (widget.isStoryMode) {
      _contentTypes = ['hikaye'];
      _selectedContentType = 'hikaye';
    } else {
      _contentTypes = ['post', 'reel'];
      _selectedContentType = 'post';
    }
    _initCamera();
    _fetchGallery();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Kamera baslatilamadi: $e");
    }
  }

  Future<void> _fetchGallery() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth || ps.hasAccess) {
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(onlyAll: true, type: RequestType.image);
      if (albums.isNotEmpty) {
        List<AssetEntity> media = await albums[0].getAssetListPaged(page: 0, size: 60);
        if (mounted) {
          setState(() {
            _mediaList = media;
            _isLoadingGallery = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingGallery = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingGallery = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_cameraController!.value.isTakingPicture) return;

    try {
      final XFile picture = await _cameraController!.takePicture();
      _handleSelectedMedia(File(picture.path));
    } catch (e) {
      debugPrint("Fotoğraf çekilirken hata oluştu: $e");
    }
  }

  Future<void> _pickFromGallery(AssetEntity entity) async {
    final File? file = await entity.file;
    if (file != null) {
      _handleSelectedMedia(file);
    }
  }

  Future<void> _handleSelectedMedia(File file) async {
    try {
      if (_selectedContentType == 'hikaye') {
        setState(() => _isUploading = true);
        await _supabaseService.createStory(file);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("\nHİKAYE başarıyla paylaşıldı!")));
          Navigator.pop(context, true); // Geri dön
        }
      } else {
        // Post veya Reel için Açıklama/Paylaşım sayfasına geçiş
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddPostPage(initialType: _selectedContentType, initialImage: file),
            ),
          ).then((value) {
            // Eğer AddPostPage içerisinden paylaşım yapılıp dönülmüşse (true), galeriyi de kapat
            if (value == true && mounted) {
              Navigator.pop(context, true);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Yükleme Hatası: $e")));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isUploading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text("İçerik Yükleniyor...", style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Üst Bar: Kapat Butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  // Flash veya Kamera Çevirme eklenebilir
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 28),
                    onPressed: () async {
                      if (_cameras == null || _cameras!.length < 2) return;
                      final currentIndex = _cameras!.indexOf(_cameraController!.description);
                      final nextIndex = (currentIndex + 1) % _cameras!.length;
                      
                      await _cameraController?.dispose();
                      _cameraController = CameraController(
                        _cameras![nextIndex],
                        ResolutionPreset.high,
                        enableAudio: false,
                      );
                      await _cameraController!.initialize();
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
            ),
            
            // Kamera Görünümü
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey[900],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_cameraController != null && _cameraController!.value.isInitialized)
                      CameraPreview(_cameraController!)
                    else
                      const Center(child: CircularProgressIndicator(color: Colors.white)),
                    
                    // Alt Kısımda Kamera Çekim Butonu ve Konum Seçimi
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          if (_contentTypes.length > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: _contentTypes.map((type) {
                                final isSelected = _selectedContentType == type;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedContentType = type),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      type.toUpperCase(),
                                      style: TextStyle(
                                        color: isSelected ? Colors.black : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          if (_contentTypes.length > 1) const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: _takePhoto,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 55,
                                    height: 55,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Alt Kısım: Galeri
            Expanded(
              flex: 4,
              child: _isLoadingGallery
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _mediaList.isEmpty
                      ? const Center(child: Text("Galeride resim bulunamadı.", style: TextStyle(color: Colors.white54)))
                      : GridView.builder(
                          padding: const EdgeInsets.all(2),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                          ),
                          itemCount: _mediaList.length,
                          itemBuilder: (context, index) {
                            final asset = _mediaList[index];
                            return GestureDetector(
                              onTap: () => _pickFromGallery(asset),
                              child: AssetThumbnail(asset: asset),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class AssetThumbnail extends StatelessWidget {
  const AssetThumbnail({
    Key? key,
    required this.asset,
  }) : super(key: key);

  final AssetEntity asset;

  @override
  Widget build(BuildContext context) {
    // Resmi thumbnail olarak yukle
    return FutureBuilder<List<int>?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
      builder: (_, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return Container(color: Colors.grey[800]);
        }
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.cover,
        );
      },
    );
  }
}
