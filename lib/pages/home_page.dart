import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import 'login_page.dart';
import 'add_post_page.dart';
import 'chat_page.dart';
import 'edit_profile_page.dart';
import 'camera_gallery_page.dart'; // Yeni kamera ve galeri ekranı import edildi
import '../services/supabase_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = Supabase.instance.client.auth.currentUser;
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _picker = ImagePicker();
  
  // 0: Ana Sayfa, 1: Bildirimler, 2: Mesajlar, 3: Profil
  int _currentIndex = 0;

  // Ana Sayfadaki Hikayeler Barı
  Widget _buildStoriesBar() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _supabaseService.getStories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)));
        }

        final stories = snapshot.data ?? [];
        
        // Kendi profilimiz (Listenin her zaman en başında)
        final List<Map<String, dynamic>> finalStories = [
          {
            "isMe": true, 
            "name": "Sen", 
            "avatar": "https://picsum.photos/100/100", // Kendi Avatarımız (Profilden çekilebilir)
          }
        ];
        
        // Geri kalan hikayeler
        for (var s in stories) {
          if (s['user_id'] == user?.id) continue;
          final p = s['profiles'] ?? {};
          finalStories.add({
            "isMe": false,
            "name": p['username'] ?? "Kullanıcı",
            "avatar": s['image_url'], // Hikaye resmini avatar gibi gösterdik şimdilik yuvarlakta, isterseniz profil resmi alınabilir (p['avatar_url'])
            "storyUrl": s['image_url'],
          });
        }

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: finalStories.length,
            itemBuilder: (context, index) {
              final story = finalStories[index];
              final bool isMe = story['isMe'];

              return GestureDetector(
                onTap: () {
                  if (isMe) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraGalleryPage(isStoryMode: true)));
                  } else {
                    // İleride Hikaye Görüntüleme Ekranı açılabilir
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${story['name']} adlı kişinin hikayesi açılıyor...")));
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 14.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isMe ? Colors.grey[700]! : Colors.blueAccent,
                                width: 2.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(story['avatar']),
                              ),
                            ),
                          ),
                          if (isMe)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 14),
                              ),
                            )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        story['name'],
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _uploadStory(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hikaye yükleniyor...")));
      
      await _supabaseService.createStory(File(image.path));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hikaye başarıyla eklendi!")));
        setState(() {}); // Ekranı yenile
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  void _showStoryOptionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Hikaye Ekle", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blueAccent),
                title: const Text("Cihazdaki Resimler", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _uploadStory(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                title: const Text("Kamera", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _uploadStory(ImageSource.camera);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Sahte (Mock) gönderi verisi - rating bilgisi için alan var (Daha fazla eklendi)
  final List<Map<String, dynamic>> mockPosts = [
    {
      "id": 1,
      "username": "ahmet_yılmaz",
      "content": "Bugün hava çok güzel, yürüyüşe çıktım! 🚶‍♂️☀️",
      "time": "2 saat önce",
      "imageUrl": "https://picsum.photos/400/300?random=1",
      "rating": null,
    },
    {
      "id": 2,
      "username": "ayse_kaya",
      "content": "Yeni başladığım kitap harika, herkese tavsiye ederim. 📚",
      "time": "4 saat önce",
      "imageUrl": "https://picsum.photos/400/300?random=2",
      "rating": null,
    },
    {
      "id": 3,
      "username": "mehmet_demir",
      "content": "Flutter öğrenmek gerçekten çok keyifli! 💻🚀",
      "time": "5 saat önce",
      "imageUrl": "https://picsum.photos/400/300?random=3",
      "rating": null,
    },
    {
      "id": 4,
      "username": "canan_yıldız",
      "content": "Kahve olmadan güne başlayamayanlar burada mı? ☕",
      "time": "6 saat önce",
      "imageUrl": "https://picsum.photos/400/300?random=4",
      "rating": null,
    },
    {
      "id": 5,
      "username": "mustafa_can",
      "content": "Hafta sonu planları yapıldı bile! 🎉",
      "time": "7 saat önce",
      "imageUrl": "https://picsum.photos/400/300?random=5",
      "rating": null,
    },
    {
      "id": 6,
      "username": "zeynep_aydın",
      "content": "Yeni tarif denedim, harika oldu 🍕",
      "time": "8 saat önce",
      "imageUrl": "https://picsum.photos/400/300?random=6",
      "rating": null,
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  void _showAddContentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Koyu tema eklentisi
          title: const Text("Ne Paylaşmak İstersin?", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: Colors.white),
                title: const Text("Post Paylaş", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context); // Dialogu kapat
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPostPage(initialType: 'post')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_collection, color: Colors.white),
                title: const Text("Reels Paylaş", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context); // Dialogu kapat
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPostPage(initialType: 'reel')));
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Koyu Tema Arka Plan
      extendBody: true,
      body: Stack(
        children: [
          // Ana İçerik Sayfası (Geçerli sekmeye göre değişir)
          _buildCurrentPage(),

          // Hikayeler Barı (Sadece Ana Ekranda Görünecek)
          if (_currentIndex == 0)
            Positioned(
              top: 110, // AppBar'ın altına yerleşecek şekilde (Aşağı alındı)
              left: 0,
              right: 0,
              child: _buildStoriesBar(),
            ),

          // Üst Kısım AppBar (Şeffaf bir banner şeklinde veya standart olabilir, postların üstünde durabilir)
          if (_currentIndex == 0 || _currentIndex == 1)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              // Sol taraftaki bildirimler sağa alındığı için leading boş bırakıldı (isteğe bağlı logo konulabilir, biz varsayılan başlığın hizalanmasına bırakıyoruz)
              automaticallyImplyLeading: false, 
              title: const Text(
                "sosyal_app",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
              ),
              actions: [
                // Mesaj Simgesi
                IconButton(
                  icon: const Icon(Icons.message_outlined, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                  onPressed: () {
                    setState(() {
                      _currentIndex = 5; // Mesajlar sayfasının yeni index numarası
                    });
                  },
                ),
                // Bildirimler (Eski çıkış butonu yerine)
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bildirimler açılıyor...")));
                  },
                )
              ],
            ),
          ),

          // Özel Şeffaf Ada (Island) Alt Menü
          Positioned(
            bottom: 30, // Alttan biraz yukarıda ada görünümü
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Blur artırıldı
                child: Container(
                  height: 70,
                  color: Colors.black.withOpacity(0.3), // Daha şeffaf yapıldı (0.6 -> 0.3)
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(Icons.home, 0), // Ana Sayfa
                      _buildNavItem(Icons.video_collection_outlined, 1), // Reels
                      
                      // Orta Taraf: Kamera Simgesi (Yeni Kamera Sayfasını açar)
                      IconButton(
                        icon: const Icon(Icons.camera_alt_outlined),
                        color: Colors.white54,
                        iconSize: 32,
                        onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraGalleryPage(isStoryMode: false)));
                        },
                      ),

                      _buildNavItem(Icons.search, 3), // Arama
                      _buildProfileNavItem(4), // Profil
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 0: Anasayfa, 1: Reels, 3: Arama, 4: Profil, 5: Mesajlar
  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeFeed(); 
      case 1:
        return _buildReelsFeed(); 
      case 3:
        return _buildSearchPage(); 
      case 4:
        return _buildProfilePage(); 
      case 5:
        return _buildMessagesPage(); 
      default:
        return _buildHomeFeed();
    }
  }

  // Arama Sayfası (Kullanıcı bulma)
  Widget _buildSearchPage() {
    return SearchFeedPage(
      onUserTap: (String searchUsername) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _buildProfilePage(username: searchUsername, isCurrentUser: false)),
        );
      },
    );
  }

  // Mesajlar Sayfası Tasarımı
  Widget _buildMessagesPage() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Mesajlar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white, size: 28), onPressed: () {}),
          IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent, size: 28), onPressed: () {}),
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white, size: 28),
              onPressed: logout,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _supabaseService.getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          }
          
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text("Sohbet edilecek kişi bulunamadı.", style: TextStyle(color: Colors.white)));
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 100), // Alt navigasyon çubuğu için boşluk
            itemCount: users.length,
            separatorBuilder: (context, index) => Divider(color: Colors.grey[900], height: 1, indent: 76),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage(user["avatar_url"] ?? "https://picsum.photos/100/100"),
                ),
                title: Text(
                  user["username"] ?? "Kullanıcı",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Text(
                    "Sohbet etmek için tıkla...",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(otherUser: user)));
                },
              );
            },
          );
        },
      ),
    );
  }

  // Detaylı Profil Sayfası
  Widget _buildProfilePage({String? username, bool isCurrentUser = true}) {
    final String currentUsername = user?.userMetadata?['username'] ?? user?.email?.split('@').first ?? "Gizli_Kullanıcı";
    final String targetUsername = username ?? currentUsername;

    Future<Map<String, dynamic>> fetchProfileAndStats() async {
      try {
        final profile = isCurrentUser 
            ? await _supabaseService.getCurrentUserProfile() 
            : await _supabaseService.getProfileByUsername(targetUsername);
            
        if (profile == null) return {'profile': {}};
        
        final userId = profile['id'];

        final results = await Future.wait([
          _supabaseService.getFollowerCount(userId),
          _supabaseService.getFollowingCount(userId),
          _supabaseService.getPostCount(userId, type: 'post'),
          _supabaseService.getPostCount(userId, type: 'reel'),
          _supabaseService.getPostCount(userId, type: 'quote'),
          _supabaseService.getSavedPostCount(userId),
          isCurrentUser ? Future.value(false) : _supabaseService.isFollowing(userId),
        ]);

        return {
          'profile': profile,
          'followers': results[0],
          'following': results[1],
          'posts': results[2],
          'reels': results[3],
          'quotes': results[4],
          'saves': results[5],
          'isFollowing': results[6],
        };
      } catch (e) {
        debugPrint("Profil verileri çekilirken hata oluştu: $e");
        return {'profile': {}};
      }
    }

    return DefaultTabController(
      length: isCurrentUser ? 4 : 3, // Reels, Postlar, Alıntılar, (Kaydedilenler sadece sana özel)
      child: Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder<Map<String, dynamic>>(
          future: fetchProfileAndStats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
            }
            
            final data = snapshot.data ?? {'profile': {}};
            final profileData = data['profile'] ?? {};
            
            final int followers = data['followers'] ?? 0;
            final int following = data['following'] ?? 0;
            final int points = profileData['points'] ?? 0;
            final int postsCount = data['posts'] ?? 0;
            final int reelsCount = data['reels'] ?? 0;
            final int quotesCount = data['quotes'] ?? 0;
            final int savesCount = data['saves'] ?? 0;
            final bool isFollowing = data['isFollowing'] ?? false;
            
            final String? dbAvatar = profileData['avatar_url'];
            final String? dbCover = profileData['cover_url'];
            
            final String? avatarUrl = (dbAvatar != null && !dbAvatar.contains('picsum.photos')) ? dbAvatar : null;
            final String? coverUrl = (dbCover != null && !dbCover.contains('picsum.photos')) ? dbCover : null;
            
            final String? realFullName = profileData['full_name'];
            final fullName = (realFullName != null && realFullName.trim().isNotEmpty) ? realFullName : "";
            final realUsername = profileData['username'] ?? targetUsername;
            final bio = profileData['bio']?.isNotEmpty == true ? profileData['bio'] : "Henüz bir biyografi eklenmedi.";

            return NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                backgroundColor: Colors.black,
                expandedHeight: isCurrentUser ? 400 : 450, // Takip Et butonu için ekstra alan
                pinned: true,
                actions: [
                  if (isCurrentUser)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      color: Colors.grey[900],
                      onSelected: (value) async {
                        if (value == 'settings') {
                          final profileData = await _supabaseService.getCurrentUserProfile();
                          if (mounted) {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EditProfilePage(initialData: profileData ?? {})),
                            );
                            if (result == true) {
                              setState(() {});
                            }
                          }
                        } else if (value == 'logout') {
                          logout();
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'settings',
                          child: Text('Hesap Ayarları', style: TextStyle(color: Colors.white)),
                        ),
                        const PopupMenuItem<String>(
                          value: 'logout',
                          child: Text('Çıkış Yap', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                ],
                leading: !isCurrentUser
                    ? Container(
                        margin: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5), // Belirgin yuvarlak arka plan
                          shape: BoxShape.circle,
                        ),
                        child: const BackButton(color: Colors.white),
                      )
                    : null,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Kapak Resmi
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[900], // Boş ise gri duracak
                          image: coverUrl != null ? DecorationImage(
                            image: NetworkImage(coverUrl), // Veritabanından gelen kapak
                            fit: BoxFit.cover,
                          ) : null,
                        ),
                        child: coverUrl == null 
                            ? const Center(child: Icon(Icons.photo_size_select_actual, color: Colors.white24, size: 50))
                            : null,
                      ),
                      // Kapak Resminin altına koyu degrade ekleyerek belirginliği artırma
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.6)],
                          ),
                        ),
                      ),
                      // Kapak Fotoğrafını Değiştir Butonu
                      if (isCurrentUser)
                        Positioned(
                          top: 150,
                          right: 16,
                          child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kapak fotoğrafı değiştiriliyor...")));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_a_photo, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      // Profil Resmi (Kapak resminin biraz üzerine ve altına taşıyor)
                      Positioned(
                        top: 150, // Kapak resminin bitimine yakın bir yerden başlar
                        left: 20,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 4), // Profil resmi etrafına siyah çerçeve
                              ),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.grey[800],
                                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                child: avatarUrl == null ? const Icon(Icons.person, size: 50, color: Colors.white54) : null,
                              ),
                            ),
                            // Profil Fotoğrafı Değiştir Butonu
                            if (isCurrentUser)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil fotoğrafı değiştiriliyor...")));
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black, width: 2),
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Kullanıcı Bilgileri (İsim, Soyisim, Nickname, Biyografi ve İstatistikler)
                      Positioned(
                        top: 250,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    fullName, // İsim Soyisim
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "@$realUsername", // Nickname
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              bio, // Biyografi
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // İstatistikler: Takipçi, Takip, Toplam Puan
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatColumn(followers.toString(), "Takipçi"),
                                _buildStatColumn(following.toString(), "Takip"),
                                _buildStatColumn("$points\u2B50", "Puan"),
                              ],
                            ),
                            if (!isCurrentUser) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFollowing ? Colors.grey[800] : Colors.blueAccent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () async {
                                    try {
                                      if (isFollowing) {
                                        await _supabaseService.unfollowUser(profileData['id']);
                                      } else {
                                        await _supabaseService.followUser(profileData['id']);
                                      }
                                      setState(() {});
                                    } catch (e) {
                                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
                                    }
                                  },
                                  child: Text(
                                    isFollowing ? "Takiptesin" : "Takip Et",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // TabBar Alanı (Menüler)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    indicatorColor: Colors.blueAccent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(reelsCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Text("Reels", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(postsCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Text("Postlar", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(quotesCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Text("Alıntılar", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      if (isCurrentUser) 
                        Tab(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(savesCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Text("Kaydedilenler", style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ];
          },
          // İçerik Alanı - Her Tab için farklı Grid/Liste
          body: TabBarView(
            children: [
              _buildProfileGridGallery(username: realUsername, isReels: true),
              _buildProfileGridGallery(username: realUsername, isReels: false),
              _buildProfileGridGallery(username: realUsername, isReels: false),
              if (isCurrentUser) _buildProfileGridGallery(username: realUsername, isReels: false, isSaved: true),
            ],
          ),
        );
      },
    ),
      ),
    );
  }

  // Profil sekmeleri içerisindeki resim/video grid (ızgara) yapısı
  Widget _buildProfileGridGallery({required String username, required bool isReels, bool isSaved = false}) {
    // Reels is 9:16 aspect ratio (dikey), post is 1:1
    double childAspectRatio = isReels ? 0.56 : 1.0; 

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: isSaved ? _supabaseService.getSavedPosts() : _supabaseService.getPostsByUsername(username, type: isReels ? 'reel' : 'post'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text("Burada henüz bir şey yok.", style: TextStyle(color: Colors.grey)));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2.0).copyWith(bottom: 120), // Alttaki ada menü için boşluk
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Yan yana 3 öğe
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final imageUrl = item['image_url'];

            return Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null)
                  Image.network(imageUrl, fit: BoxFit.cover)
                else
                  Container(color: Colors.grey[800], child: const Icon(Icons.image, color: Colors.white54)),
                
                // Reels ise üzerine bir "play" ikonu ekleyebiliriz
                if (isReels)
                  const Positioned(
                    bottom: 8,
                    left: 8,
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // İstatistik Sütunları (Takipçi, Takip vb.) İçin Yardımcı Metod
  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _currentIndex == index;
    return IconButton(
      icon: Icon(icon),
      color: isSelected ? Colors.white : Colors.white54,
      iconSize: 30,
      onPressed: () {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }

  Widget _buildProfileNavItem(int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: const CircleAvatar(
          radius: 14,
          backgroundImage: NetworkImage("https://picsum.photos/100/100"), // Örnek profil resmi
        ),
      ),
    );
  }

  // Ortak Placeholder Ekranı
  Widget _buildPlaceholderPage(String title, IconData icon) {
    return Container(
      color: Colors.grey[900], // Siyah/Koyu arka plan
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white54, size: 80),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 24)),
          ],
        ),
      ),
    );
  }

  // Ana Sayfa Post Akışı (Kart şeklinde)
  Widget _buildHomeFeed() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _supabaseService.getPosts(type: 'post'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Hata: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
        }
        
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const Center(child: Text("Henüz gönderi yok. İlk sen paylaş!", style: TextStyle(color: Colors.white, fontSize: 16)));
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final row = posts[index];
            final profile = row['profiles'] ?? {};
            final postData = {
              "id": row['id'],
              "username": profile['username'] ?? "Kullanıcı",
              "content": row['content'] ?? "",
              "imageUrl": row['image_url'],
              "time": "Şimdi",
            };
            return _buildPostCard(postData);
          },
        );
      },
    );
  }

  // Reels Akışı (Tam sayfa şeklinde)
  Widget _buildReelsFeed() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _supabaseService.getPosts(type: 'reel'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Hata: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
        }
        
        final reels = snapshot.data ?? [];
        if (reels.isEmpty) {
          return const Center(child: Text("Henüz reel yok. Kaydırmaya başla!", style: TextStyle(color: Colors.white, fontSize: 16)));
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: reels.length,
          itemBuilder: (context, index) {
            final row = reels[index];
            final profile = row['profiles'] ?? {};
            final postData = {
              "id": row['id'],
              "username": profile['username'] ?? "Kullanıcı",
              "content": row['content'] ?? "",
              "imageUrl": row['image_url'],
              "time": "Şimdi",
            };
            return _buildFullScreenReelsCard(postData);
          },
        );
      },
    );
  }

  // Eski Usul Kart Tasarımı (Ana Sayfa İçin)
  Widget _buildPostCard(Map<String, dynamic> post) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Arka Planda Flue (Bulanık) Resim
        if (post["imageUrl"] != null)
          Image.network(
            post["imageUrl"],
            fit: BoxFit.cover,
          ),
        if (post["imageUrl"] != null)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
        
        // Asıl Kart İçeriği
        Center(
          child: Card(
            color: Colors.grey[900]?.withOpacity(0.85), // Kart arka planını biraz şeffaflaştırdık
            // Kartın yüksekliği/büyüklüğü ayarlandı (hikaye barının altında kalmaması için top artırıldı)
            margin: const EdgeInsets.only(left: 16, right: 16, top: 195, bottom: 90),
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil, İsim ve Paylaş Butonu (Kartın Sağ Üst Alanı)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => _buildProfilePage(username: post["username"], isCurrentUser: false),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blueAccent.shade700,
                            child: Text(
                              post["username"][0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post["username"],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                post["time"],
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Yeni: Sağ üst alana direkt mesaj/paylaş butonu
                        IconButton(
                          icon: const Icon(Icons.send_outlined, color: Colors.blueAccent),
                          tooltip: "Direkt Mesaj Gönder",
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Direkt mesaj veya paylaşım açılıyor...")));
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Paylaşım Görseli (Resim) - Yüksekliği dengelendi
                  if (post["imageUrl"] != null)
                    Image.network(
                      post["imageUrl"],
                      width: double.infinity,
                      height: 290, // Ekrana daha iyi sığması için küçültüldü
                      fit: BoxFit.cover,
                    ),

                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Puanlama (Değerlendirme) - Resmin Hemen Altında
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildHorizontalStarRating(post, 1, Colors.redAccent),
                            _buildHorizontalStarRating(post, 2, Colors.orangeAccent),
                            _buildHorizontalStarRating(post, 3, Colors.amber),
                            _buildHorizontalStarRating(post, 4, Colors.lightGreen),
                            _buildHorizontalStarRating(post, 5, Colors.green),
                          ],
                        ),
                        const Divider(color: Colors.grey), 
                        const SizedBox(height: 8),

                        // Açıklama - Değerlendirmenin Hemen Altında
                        Text(
                          post["content"],
                          style: const TextStyle(fontSize: 15, color: Colors.white), // Yazı boyutu hafif büyütüldü
                        ),

                        // Alıntılanan Gönderi (Eğer Varsa)
                        if (post["quoted_post"] != null)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[800]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.format_quote, color: Colors.blueAccent, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      "@${post['quoted_post']['profiles']?['username'] ?? 'Kullanıcı'}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  post['quoted_post']['content'] ?? '',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                                ),
                                if (post['quoted_post']['image_url'] != null) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(post['quoted_post']['image_url'], height: 120, width: double.infinity, fit: BoxFit.cover),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.grey),

                        // Etkileşim İkonları (Yorum, Alıntı, Kaydet) - Açıklamadan Sonra
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Yorumlar açılıyor...")),
                                );
                              },
                              icon: const Icon(Icons.chat_bubble_outline, color: Colors.blueAccent),
                              label: const Text("Yorum Yap", style: TextStyle(color: Colors.blueAccent)),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AddPostPage(quotedPost: post)),
                                );
                              },
                              icon: const Icon(Icons.format_quote, color: Colors.blueAccent),
                              label: const Text("Alıntıla", style: TextStyle(color: Colors.blueAccent)),
                            ),
                            SaveButtonWidget(postId: post['id'], supabaseService: _supabaseService),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Yatay dizilmiş yıldızlar (Kart tasarımı için)
  Widget _buildHorizontalStarRating(Map<String, dynamic> post, int ratingValue, Color iconColor) {
    int currentRating = post["rating"] ?? 0;
    bool isFilled = ratingValue <= currentRating;
    
    return InkWell(
      onTap: () {
        setState(() {
          post["rating"] = ratingValue;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$ratingValue yıldız puanı verdiniz!")),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Icon(
          isFilled ? Icons.star : Icons.star_border, 
          color: isFilled ? iconColor : Colors.grey,
          size: 32,
        ),
      ),
    );
  }


  // Tam Ekran Post/Reels Kartı (Sadece Reels Sekmesinde)
  Widget _buildFullScreenReelsCard(Map<String, dynamic> post) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Arka Plan Görseli
          if (post["imageUrl"] != null)
            Image.network(
              post["imageUrl"],
              fit: BoxFit.cover,
            ),
          
          // Arka planı koyulaştıran bir gradient (yazıların okunması için)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Sağ Alt Taraf - Etkileşimler (Yıldızlar, Yorum, Paylaş)
          Positioned(
            bottom: 120, // Alt menünün (island) üstünde kalması için boşluk
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSideStarRating(post, 1, Colors.redAccent),
                _buildSideStarRating(post, 2, Colors.orangeAccent),
                _buildSideStarRating(post, 3, Colors.amber),
                _buildSideStarRating(post, 4, Colors.lightGreen),
                _buildSideStarRating(post, 5, Colors.green),
                const SizedBox(height: 24),
                _buildSideActionIcon(Icons.chat_bubble_outline, "Yorum", () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yorumlar açılıyor...")));
                }),
                const SizedBox(height: 20),
                _buildSideActionIcon(Icons.format_quote, "Alıntıla", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddPostPage(quotedPost: post)),
                  );
                }),
                const SizedBox(height: 20),
                SaveReelButtonWidget(postId: post['id'], supabaseService: _supabaseService),
              ],
            ),
          ),

          // Sol Alt Taraf - Kullanıcı ve Açıklama
          Positioned(
            bottom: 140, // Alt menünün (island) üstünde kalması için boşluk
            left: 16,
            right: 80, // Sağdaki ikonların üzerine binmemesi için
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _buildProfilePage(username: post["username"], isCurrentUser: false),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blueAccent.shade100,
                        child: Text(
                          post["username"][0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "@${post["username"]}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      post["time"],
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  post["content"],
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideActionIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  // Dikey dizilmiş yıldızlar
  Widget _buildSideStarRating(Map<String, dynamic> post, int ratingValue, Color iconColor) {
    int currentRating = post["rating"] ?? 0;
    bool isFilled = ratingValue <= currentRating;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          post["rating"] = ratingValue;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$ratingValue yıldız verdiniz!")),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Icon(
          isFilled ? Icons.star : Icons.star_border, 
          color: isFilled ? iconColor : Colors.white,
          size: 32,
          shadows: isFilled ? [Shadow(color: iconColor, blurRadius: 10)] : [Shadow(color: Colors.black, blurRadius: 5)],
        ),
      ),
    );
  }
}

// TabBar'ın (Reels, Post vs. menülerinin) yukarı kaydırırken tepede sabit kalması (pinned)
// işlemini sağlayan Custom Delegate Sınıfı
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height + 10;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 10;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black, // Menülerin arka planı siyah kalsın
      child: Center(child: _tabBar),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class SaveButtonWidget extends StatefulWidget {
  final String postId;
  final SupabaseService supabaseService;

  const SaveButtonWidget({Key? key, required this.postId, required this.supabaseService}) : super(key: key);

  @override
  State<SaveButtonWidget> createState() => _SaveButtonWidgetState();
}

class _SaveButtonWidgetState extends State<SaveButtonWidget> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    final status = await widget.supabaseService.isSaved(widget.postId);
    if (mounted) setState(() { _isSaved = status; });
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        setState(() => _isSaved = !_isSaved);
        try {
          if (_isSaved) await widget.supabaseService.savePost(widget.postId);
          else await widget.supabaseService.unsavePost(widget.postId);
        } catch (e) {
          if (mounted) setState(() => _isSaved = !_isSaved);
        }
      },
      icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: _isSaved ? Colors.white : Colors.blueAccent),
      label: Text(_isSaved ? "Kaydedildi" : "Kaydet", style: TextStyle(color: _isSaved ? Colors.white : Colors.blueAccent)),
    );
  }
}

class SaveReelButtonWidget extends StatefulWidget {
  final String postId;
  final SupabaseService supabaseService;

  const SaveReelButtonWidget({Key? key, required this.postId, required this.supabaseService}) : super(key: key);

  @override
  State<SaveReelButtonWidget> createState() => _SaveReelButtonWidgetState();
}

class _SaveReelButtonWidgetState extends State<SaveReelButtonWidget> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    final status = await widget.supabaseService.isSaved(widget.postId);
    if (mounted) setState(() { _isSaved = status; });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        setState(() => _isSaved = !_isSaved);
        try {
          if (_isSaved) await widget.supabaseService.savePost(widget.postId);
          else await widget.supabaseService.unsavePost(widget.postId);
        } catch (e) {
          if (mounted) setState(() => _isSaved = !_isSaved);
        }
      },
      child: Column(
        children: [
          Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.white, size: 30),
          const SizedBox(height: 4),
          const Text("Kaydet", style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

// Arama Sayfası (SearchFeedPage)
class SearchFeedPage extends StatefulWidget {
  final Function(String) onUserTap;
  const SearchFeedPage({Key? key, required this.onUserTap}) : super(key: key);

  @override
  State<SearchFeedPage> createState() => _SearchFeedPageState();
}

class _SearchFeedPageState extends State<SearchFeedPage> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String _lastQuery = '';

  void _performSearch(String query) async {
    final tQuery = query.trim();
    if (tQuery.isEmpty) {
      if (mounted) setState(() { _searchResults = []; _lastQuery = ''; });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await _supabaseService.searchUsers(tQuery);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _lastQuery = tQuery;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Kullanıcı Ara... (Örn: ahmet)",
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: Colors.white54),
            fillColor: Colors.grey[900],
            filled: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onChanged: _performSearch,
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
        : _searchResults.isEmpty && _lastQuery.isNotEmpty
          ? const Center(child: Text("Böyle bir kullanıcı bulamadık.", style: TextStyle(color: Colors.white54)))
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 110, top: 10),
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) => Divider(color: Colors.grey[900], indent: 70),
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                final String avatarUrl = user['avatar_url'] ?? "https://picsum.photos/100/100";
                final String username = user['username'] ?? "Kullanıcı";
                final String fullName = user['full_name'] ?? "";
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(avatarUrl),
                    radius: 25,
                  ),
                  title: Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: fullName.isNotEmpty ? Text(fullName, style: const TextStyle(color: Colors.white54, fontSize: 13)) : null,
                  onTap: () {
                    widget.onUserTap(username);
                  },
                );
              },
            ),
    );
  }
}
