import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Şu anki kullanıcıyı al
  User? get currentUser => _client.auth.currentUser;

  // Post veya Reel Paylaşımı
  Future<void> createPost({required String content, File? imageFile, required String type, String? quotedPostId}) async {
    if (currentUser == null) throw Exception("Lütfen önce giriş yapın.");

    String? imageUrl;

    // Resim varsa Storage'a yükle
    if (imageFile != null) {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path = '${currentUser!.id}/$fileName';

      await _client.storage.from('uploads').upload(path, imageFile);
      // Yüklenen resmin herkese açık bağlantısını al
      imageUrl = _client.storage.from('uploads').getPublicUrl(path);
    }

    // Veritabanına kaydet
    await _client.from('posts').insert({
      'user_id': currentUser!.id,
      'content': content,
      'image_url': imageUrl,
      'type': type,
      if (quotedPostId != null) 'quoted_post_id': quotedPostId,
    });
  }

  // Akış için Gönderileri Çekme (Ana sayfa için - Kendi gönderilerimizi hariç tutuyoruz)
  Future<List<Map<String, dynamic>>> getPosts({String type = 'post'}) async {
    final response = await _client
        .from('posts')
        .select('*, profiles!posts_user_id_fkey(username, full_name, avatar_url), quoted_post:posts(*, profiles!posts_user_id_fkey(username, avatar_url))')
        .eq('type', type)
        .neq('user_id', currentUser?.id ?? '')
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Belirli bir kullanıcının Gönderilerini Çekme (Profil ekranı için)
  Future<List<Map<String, dynamic>>> getPostsByUsername(String username, {String type = 'post'}) async {
    final response = await _client
        .from('posts')
        .select('*, profiles!posts_user_id_fkey!inner(username, avatar_url), quoted_post:posts(*, profiles!posts_user_id_fkey(username, avatar_url))')
        .eq('type', type)
        .eq('profiles.username', username)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Profil detayını çek
  Future<Map<String, dynamic>?> getProfileByUsername(String username) async {
    final response = await _client.from('profiles').select().eq('username', username).maybeSingle();
    return response;
  }

  // Şu anki kullanıcının profilini id ile çek
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    if (currentUser == null) return null;
    final response = await _client.from('profiles').select().eq('id', currentUser!.id).maybeSingle();
    return response;
  }

  // Profili Güncelleme
  Future<void> updateProfile({
    String? username,
    String? fullName,
    String? bio,
    File? avatarFile,
    File? coverFile,
  }) async {
    if (currentUser == null) throw Exception("Lütfen önce giriş yapın.");

    final Map<String, dynamic> updates = {};
    if (username != null && username.isNotEmpty) updates['username'] = username;
    if (fullName != null) updates['full_name'] = fullName;
    if (bio != null) updates['bio'] = bio;

    // Resimleri Storage'a Yükle
    if (avatarFile != null) {
      final ext = avatarFile.path.split('.').last;
      final path = '${currentUser!.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _client.storage.from('uploads').upload(path, avatarFile);
      updates['avatar_url'] = _client.storage.from('uploads').getPublicUrl(path);
    }

    if (coverFile != null) {
      final ext = coverFile.path.split('.').last;
      final path = '${currentUser!.id}/cover_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _client.storage.from('uploads').upload(path, coverFile);
      updates['cover_url'] = _client.storage.from('uploads').getPublicUrl(path);
    }

    // Veritabanını Güncelle veya Yoksa Oluştur (Upsert)
    updates['id'] = currentUser!.id;
    await _client.from('profiles').upsert(updates);
    
    // Auth metadata (Email provider display_name / username)
    if (username != null && username.isNotEmpty) {
      await _client.auth.updateUser(UserAttributes(data: {'username': username}));
    }
  }

  // Tüm kullanıcıları getir (Sohbet başlatmak için - Kendi profilini hariç tut)
  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await _client
        .from('profiles')
        .select()
        .neq('id', currentUser?.id ?? '');
    return List<Map<String, dynamic>>.from(response);
  }

  // Kullanıcı arama (username veya full_name içinde geçen kelime ile)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final response = await _client
        .from('profiles')
        .select()
        .or('username.ilike.%$query%,full_name.ilike.%$query%')
        .neq('id', currentUser?.id ?? '');
    return List<Map<String, dynamic>>.from(response);
  }

  // Belirli bir kullanıcıyla olan mesajların anlık akışı (Stream)
  Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    if (currentUser == null) throw Exception("Lütfen önce giriş yapın.");
    
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((maps) => maps.where((msg) =>
            (msg['sender_id'] == currentUser!.id && msg['receiver_id'] == otherUserId) ||
            (msg['sender_id'] == otherUserId && msg['receiver_id'] == currentUser!.id)
        ).toList());
  }

  // Mesaj gönderme
  Future<void> sendMessage(String receiverId, String content) async {
    if (currentUser == null) throw Exception("Lütfen önce giriş yapın.");
    
    await _client.from('messages').insert({
      'sender_id': currentUser!.id,
      'receiver_id': receiverId,
      'content': content,
    });
  }

  // Hikaye (Story) Paylaşımı
  Future<void> createStory(File imageFile) async {
    if (currentUser == null) throw Exception("Lütfen önce giriş yapın.");

    final fileExt = imageFile.path.split('.').last;
    final fileName = 'story_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final path = '${currentUser!.id}/$fileName';

    await _client.storage.from('uploads').upload(path, imageFile);
    final imageUrl = _client.storage.from('uploads').getPublicUrl(path);

    await _client.from('stories').insert({
      'user_id': currentUser!.id,
      'image_url': imageUrl,
    });
  }

  // Hikayeleri Çekme
  Future<List<Map<String, dynamic>>> getStories() async {
    final response = await _client
        .from('stories')
        .select('*, profiles(username, avatar_url)')
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // --- Profil İstatistikleri (Counts) ---
  
  // Takipçi Sayısı
  Future<int> getFollowerCount(String userId) async {
    final response = await _client.from('follows').select('follower_id').eq('following_id', userId).count(CountOption.exact);
    return response.count;
  }

  // Takip Edilen Sayısı
  Future<int> getFollowingCount(String userId) async {
    final response = await _client.from('follows').select('following_id').eq('follower_id', userId).count(CountOption.exact);
    return response.count;
  }

  // Gönderi Sayısı (post, reel, quote)
  Future<int> getPostCount(String userId, {String type = 'post'}) async {
    final response = await _client.from('posts').select('id').eq('user_id', userId).eq('type', type).count(CountOption.exact);
    return response.count;
  }

  // Kaydedilen Gönderi Sayısı
  Future<int> getSavedPostCount(String userId) async {
    final response = await _client.from('saved_posts').select('post_id').eq('user_id', userId).count(CountOption.exact);
    return response.count;
  }

  // --- Takip İşlemleri (Follow) ---
  
  // Birini takip et
  Future<void> followUser(String targetUserId) async {
    if (currentUser == null) throw Exception("Lütfen giriş yapın.");
    await _client.from('follows').insert({
      'follower_id': currentUser!.id,
      'following_id': targetUserId,
    });
  }

  // Birini takipten çık
  Future<void> unfollowUser(String targetUserId) async {
    if (currentUser == null) throw Exception("Lütfen giriş yapın.");
    await _client.from('follows').delete().eq('follower_id', currentUser!.id).eq('following_id', targetUserId);
  }

  // Takip ediliyor mu kontrol et
  Future<bool> isFollowing(String targetUserId) async {
    if (currentUser == null) return false;
    final response = await _client
        .from('follows')
        .select('created_at')
        .eq('follower_id', currentUser!.id)
        .eq('following_id', targetUserId)
        .maybeSingle();
    return response != null;
  }

  // --- Kaydetme İşlemleri (Bookmarks) ---
  
  // Postu Kaydet
  Future<void> savePost(String postId) async {
    if (currentUser == null) throw Exception("Lütfen giriş yapın.");
    await _client.from('saved_posts').upsert({
      'user_id': currentUser!.id,
      'post_id': postId,
    });
  }

  // Postu Kayıtlardan Çıkar
  Future<void> unsavePost(String postId) async {
    if (currentUser == null) throw Exception("Lütfen giriş yapın.");
    await _client.from('saved_posts').delete().eq('user_id', currentUser!.id).eq('post_id', postId);
  }

  // Post kaydedilmiş mi kontrol et
  Future<bool> isSaved(String postId) async {
    if (currentUser == null) return false;
    final response = await _client
        .from('saved_posts')
        .select('created_at')
        .eq('user_id', currentUser!.id)
        .eq('post_id', postId)
        .maybeSingle();
    return response != null;
  }

  // Kaydedilen Gönderileri Çekme (Sadece Ana Profil Sahibi İçin)
  Future<List<Map<String, dynamic>>> getSavedPosts() async {
    if (currentUser == null) return [];
    
    // saved_posts üzerinden user_id bazlı post_id eşleştirerek gönderileri çeker
    // posts tablosundaki profiles tablosunu explicitly belirtir (foreign key disambiguation)
    final response = await _client
        .from('saved_posts')
        .select('*, posts(*, profiles!posts_user_id_fkey!inner(username, full_name, avatar_url), quoted_post:posts(*, profiles!posts_user_id_fkey(username, avatar_url)))')
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);
        
    // Supabase nested joinleri map olarak döner, asıl "posts" verisini çıkartıp normal post gibi basıyoruz
    return response.map<Map<String, dynamic>>((row) => row['posts'] as Map<String, dynamic>).toList();
  }
}
