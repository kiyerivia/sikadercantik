import 'dart:convert';
import 'package:http/http.dart' as http;

const String supabaseUrl = 'https://iyznzyqhsbjgtvxgiewe.supabase.co';
const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5em56eXFoc2JqZ3R2eGdpZXdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxMTQzMzUsImV4cCI6MjA5MjY5MDMzNX0.JaaXQd9n8uJPZwO-WQ7m06Kvf1Rw35itu07MAAOBKyQ';

final Map<String, String> headers = {
  'apikey': supabaseKey,
  'Authorization': 'Bearer $supabaseKey',
  'Content-Type': 'application/json',
};

void main() async {
  // 1. Fetch all villages
  final villagesUrl = Uri.parse('$supabaseUrl/rest/v1/villages?select=id,name');
  final villagesRes = await http.get(villagesUrl, headers: headers);
  final villages = jsonDecode(villagesRes.body) as List;

  print('Villages in DB:');
  for (var v in villages) {
    final id = v['id'];
    final name = v['name'];
    
    // Check RW count
    final rwUrl = Uri.parse('$supabaseUrl/rest/v1/rws?village_id=eq.$id&select=id');
    final rwRes = await http.get(rwUrl, headers: headers);
    final rws = jsonDecode(rwRes.body) as List;
    
    print('  ID: $id, Name: $name, RW Count: ${rws.length}');
  }
}
