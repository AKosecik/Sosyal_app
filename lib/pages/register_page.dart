import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_page.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  Future<void> register() async {
    try {
      setState(() => loading = true);

      final response = await Supabase.instance.client.auth.signUp(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
        data: {
          'full_name': nameCtrl.text.trim(),
        },
      );

      if (response.user != null && mounted) {
        // Profiles tablosuna kayıt oluştur
        final username = emailCtrl.text.trim().split('@').first;
        try {
          await Supabase.instance.client.from('profiles').upsert({
            'id': response.user!.id,
            'username': username,
            'full_name': nameCtrl.text.trim(),
          });
        } catch (profileError) {
          debugPrint("Profil oluşturma hatası (RLS olabilir): $profileError");
        }

        // Oturum varsa anasayfaya, yoksa (email doğrulama gerekiyorsa) giriş sayfasına yönlendir
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Kayıt başarılı! Lütfen e-postanızı doğrulayın ve giriş yapın.")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint("KAYIT HATASI: $e");
      debugPrint("STACK TRACE: $stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kayıt Hatası: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Yeni Hesap Oluştur",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Ad Soyad",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Mail Adresi",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Şifre",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading ? null : register,
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Kayıt Ol", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
