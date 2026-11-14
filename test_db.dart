import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://gsacsibqjyjdzcqxeugu.supabase.co';
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdzYWNzaWJxanlqZHpjcXhldWd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM1ODkwNjIsImV4cCI6MjA4OTE2NTA2Mn0.bVoXgzgOPjKSwzLjULiQNMxNxXwCUV5WCkWt0j6JEls';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    final data = await client.from('profiles').select();
    print("ALL PROFILES DATA IN DB:");
    for (var row in data) {
      print("${row['id']} | username=${row['username']} | full_name=${row['full_name']}");
    }
  } catch (e) {
    print("Error: $e");
  }
}
