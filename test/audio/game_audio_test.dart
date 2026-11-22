import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:superhero_showdown/core/audio/game_audio.dart';

void main() {
  test('every sound and music file exists and is a valid WAV', () {
    final files = [
      for (final s in Sfx.values) s.file,
      for (final m in Music.values) m.file,
    ];
    for (final f in files) {
      final file = File('assets/audio/$f');
      expect(file.existsSync(), isTrue, reason: f);
      final bytes = file.readAsBytesSync();
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF', reason: f);
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE', reason: f);
      final rate = ByteData.sublistView(bytes).getUint32(24, Endian.little);
      expect(rate, 22050, reason: f);
    }
  });

  test('sound files stay small enough for a light APK', () {
    final total = Directory('assets/audio')
        .listSync()
        .whereType<File>()
        .fold<int>(0, (sum, f) => sum + f.lengthSync());
    expect(total, lessThan(3 * 1024 * 1024));
  });

  test('audio calls are safe before init (silent in tests)', () {
    final audio = GameAudio.instance;
    audio.play(Sfx.punch);
    audio.playMusic(Music.battle);
    audio.toggleMute();
    expect(audio.muted.value, isTrue);
    audio.toggleMute();
    audio.stopMusic();
  });
}
