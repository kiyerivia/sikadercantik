import 'dart:convert';
import 'dart:io';

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
    final req = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/posyandus?limit=1'));
    req.headers.set('apikey', supabaseKey!);
    req.headers.set('Authorization', 'Bearer $supabaseKey');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    print('Columns in posyandus: ${jsonDecode(body)[0].keys.toList()}');
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
