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
  final badVillageId = 'b3a6b8a5-d984-445a-9aff-ee3b1b2898e8';
  
  print('Target ID to delete: $badVillageId');

  // 1. Delete Posyandus through RWs
  final rwUrl = Uri.parse('$supabaseUrl/rest/v1/rws?village_id=eq.$badVillageId&select=id');
  final rwRes = await http.get(rwUrl, headers: headers);
  final rws = jsonDecode(rwRes.body) as List;
  
  for (var rw in rws) {
    final rwId = rw['id'];
    final delPUrl = Uri.parse('$supabaseUrl/rest/v1/posyandus?rw_id=eq.$rwId');
    final pRes = await http.delete(delPUrl, headers: headers);
    print('Deleted Posyandus for RW $rwId: ${pRes.statusCode}');
  }

  // 2. Delete RWs
  final delRwUrl = Uri.parse('$supabaseUrl/rest/v1/rws?village_id=eq.$badVillageId');
  final rwDelRes = await http.delete(delRwUrl, headers: headers);
  print('Deleted RWs for Village $badVillageId: ${rwDelRes.statusCode}');

  // 3. Delete Village
  final delVUrl = Uri.parse('$supabaseUrl/rest/v1/villages?id=eq.$badVillageId');
  final vDelRes = await http.delete(delVUrl, headers: headers);
  print('Deleted Village $badVillageId: ${vDelRes.statusCode}');
}
