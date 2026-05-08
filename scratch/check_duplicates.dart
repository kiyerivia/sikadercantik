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
    print('Checking for duplicate villages...');
    final url = '$supabaseUrl/rest/v1/villages?select=id,name&name=eq.Cilangkap';
    final req = await client.getUrl(Uri.parse(url));
    req.headers.set('apikey', supabaseKey!);
    req.headers.set('Authorization', 'Bearer $supabaseKey');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    print('Cilangkap records: $body');

    final url2 = '$supabaseUrl/rest/v1/villages?select=id,name&name=eq.Tlaga';
    final req2 = await client.getUrl(Uri.parse(url2));
    req2.headers.set('apikey', supabaseKey);
    req2.headers.set('Authorization', 'Bearer $supabaseKey');
    final res2 = await req2.close();
    final body2 = await res2.transform(utf8.decoder).join();
    print('Tlaga records: $body2');

  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
