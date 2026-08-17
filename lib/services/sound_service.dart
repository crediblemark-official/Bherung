import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;

  SoundService._internal() {
    _initPlayer();
  }

  AudioPlayer? _player;
  bool _isSoundEnabled = true;
  bool _isHapticEnabled = true;

  bool get isSoundEnabled => _isSoundEnabled;
  bool get isHapticEnabled => _isHapticEnabled;

  void setSoundEnabled(bool enabled) {
    _isSoundEnabled = enabled;
  }

  void setHapticEnabled(bool enabled) {
    _isHapticEnabled = enabled;
  }

  void _initPlayer() {
    try {
      _player = AudioPlayer();
      _player?.setReleaseMode(ReleaseMode.stop);
      _player?.setPlayerMode(PlayerMode.lowLatency);
    } catch (e) {
      if (kDebugMode) {
        print('SoundService init error: $e');
      }
    }
  }

  /// Memutar bunyi Beep POS Scanner dan getaran haptic saat barcode berhasil terdeteksi
  Future<void> playScanBeep() async {
    // 1. Getaran Haptic
    if (_isHapticEnabled) {
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
    }

    // 2. Bunyi Beep Scanner
    if (_isSoundEnabled) {
      try {
        // Mainkan sound asset scanner beep
        if (_player == null) {
          _initPlayer();
        }
        await _player?.stop();
        await _player?.play(AssetSource('sounds/beep.wav'), volume: 1.0);
      } catch (e) {
        // Fallback ke sistem sound bawaan jika gagal memutar asset
        try {
          SystemSound.play(SystemSoundType.click);
        } catch (_) {}
      }
    }
  }

  /// Bunyi notifikasi sukses (misal: pembayaran / simpan data)
  Future<void> playSuccess() async {
    if (_isHapticEnabled) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    }
    if (_isSoundEnabled) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  /// Bunyi notifikasi error / peringatan
  Future<void> playAlert() async {
    if (_isHapticEnabled) {
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
    }
    if (_isSoundEnabled) {
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  void dispose() {
    try {
      _player?.dispose();
    } catch (_) {}
  }
}
