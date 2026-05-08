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
    print('Checking Posyandu data types...');
    final url = '$supabaseUrl/rest/v1/posyandus?select=*&limit=1';
    final req = await client.getUrl(Uri.parse(url));
    req.headers.set('apikey', supabaseKey!);
    req.headers.set('Authorization', 'Bearer $supabaseKey');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    final List posyandus = jsonDecode(body);
    if (posyandus.isNotEmpty) {
      final p = posyandus[0];
      print('Sample Posyandu: $p');
      print('tahun_pendirian type: ${p['tahun_pendirian'].runtimeType}');
      print('nomor_hp type: ${p['nomor_hp'].runtimeType}');
    }

  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
