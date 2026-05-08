import 'dart:io';
import 'dart:convert';

void main() async {
  final envFile = File('.env');
  final envLines = envFile.readAsLinesSync();
  String? supabaseUrl;
  String? supabaseKey;

  for (var line in envLines) {
    if (line.contains('=')) {
      final parts = line.split('=');
      final key = parts[0].trim();
      final value = parts.sublist(1).join('=').trim();
      if (key == 'SUPABASE_URL') supabaseUrl = value;
      if (key == 'SUPABASE_ANON_KEY') supabaseKey = value;
    }
  }

  final client = HttpClient();
  final villageId = 'adc06bce-b9fd-4f7f-99d7-2f46b408441c'; // Cilangkap

  try {
    print('Testing Posyandu fetch for Cilangkap...');
    
    // Test the exact query used in the app
    final url = '$supabaseUrl/rest/v1/posyandus?select=*,rws!inner(*)&rws.village_id=eq.$villageId&order=name';
    final req = await client.getUrl(Uri.parse(url));
    req.headers.set('apikey', supabaseKey!);
    req.headers.set('Authorization', 'Bearer $supabaseKey');
    
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    print('Response Status: ${res.statusCode}');
    print('Response Body: $body');

    final List data = jsonDecode(body);
    print('Found ${data.length} posyandus');
    for (var item in data) {
      print(' - ${item['name']} (RW ID: ${item['rw_id']})');
    }

  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
