import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  int replacedCount = 0;

  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;

    // Old Blue colors to New Dark Blue (0xFF10365F)
    final blueReplacements = [
      '0xFF1F618D',
      '0xFF154360',
      '0xFF005B9F',
      '0xFF003049',
      '0xFF2C3E50',
    ];

    for (final hex in blueReplacements) {
      if (content.contains(hex)) {
        content = content.replaceAll(hex, '0xFF10365F');
        changed = true;
      }
    }

    // Secondary Blue replacements (Light blue 0xFF29B6F6)
    if (content.contains('0xFF1976D2')) {
      content = content.replaceAll('0xFF1976D2', '0xFF29B6F6');
      changed = true;
    }

    // Light backgrounds to New Background (0xFFF4F8FA)
    final bgReplacements = [
      '0xFFF8FBFF',
      '0xFFE8F4FA',
      '0xFFD4E6F1',
      '0xFFF4F6F9',
      '0xFFF8F9F9',
    ];

    for (final hex in bgReplacements) {
      if (content.contains(hex)) {
        content = content.replaceAll(hex, '0xFFF4F8FA');
        changed = true;
      }
    }

    // Greens to New Primary Green (0xFF68B744)
    final greenReplacements = [
      '0xFF1D7423',
      '0xFF82E0AA',
      '0xFF2E7D32', // Wait, maybe keep this for dark green? The vest is dark green. Let's keep 2E7D32.
      '0xFF388E3C', // Change to primary green
    ];

    for (final hex in greenReplacements) {
      if (hex == '0xFF2E7D32') continue; // Skip dark green
      if (content.contains(hex)) {
        content = content.replaceAll(hex, '0xFF68B744');
        changed = true;
      }
    }

    if (changed) {
      file.writeAsStringSync(content);
      replacedCount++;
      print('Updated: ${file.path}');
    }
  }

  print('Total files updated: $replacedCount');
}
