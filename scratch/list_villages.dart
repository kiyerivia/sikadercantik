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
    print('Listing ALL Villages:');
    final url = '$supabaseUrl/rest/v1/villages?select=id,name&order=name';
    final req = await client.getUrl(Uri.parse(url));
    req.headers.set('apikey', supabaseKey!);
    req.headers.set('Authorization', 'Bearer $supabaseKey');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    final List villages = jsonDecode(body);
    for (var v in villages) {
      print('  - ${v['name']}: ${v['id']}');
    }

  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
