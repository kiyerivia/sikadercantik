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

  try {
    print('Checking Kader Profile...');
    final url = '$supabaseUrl/rest/v1/profiles?select=*&email=eq.kader@test.com';
    final req = await client.getUrl(Uri.parse(url));
    req.headers.set('apikey', supabaseKey!);
    req.headers.set('Authorization', 'Bearer $supabaseKey');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    print('Kader Profile: $body');

    print('\nChecking Admin Profile...');
    final url2 = '$supabaseUrl/rest/v1/profiles?select=*&email=eq.admin@test.com';
    final req2 = await client.getUrl(Uri.parse(url2));
    req2.headers.set('apikey', supabaseKey);
    req2.headers.set('Authorization', 'Bearer $supabaseKey');
    final res2 = await req2.close();
    final body2 = await res2.transform(utf8.decoder).join();
    print('Admin Profile: $body2');

  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
