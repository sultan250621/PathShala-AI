import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:onenm_local_llm/onenm_local_llm.dart';

enum DoubtSource { model, bookExplanation, unavailable }

class DoubtResult {
  final String text;
  final DoubtSource source;
  final Duration? elapsed;
  DoubtResult(this.text, this.source, [this.elapsed]);
}

/// Offline Doubt Solver.
/// Runs a small on-device model when the phone can handle it, otherwise
/// falls back to the book explanation stored in the question bank.
/// ask() never throws, so the UI can never crash because of the model.
class DoubtSolverService {
  DoubtSolverService._();
  static final DoubtSolverService instance = DoubtSolverService._();

  // Change only this line to test another model:
  // OneNmModel.tinyllama, OneNmModel.tinyllama, OneNmModel.gemma2b
  static final _model = OneNmModel.tinyllama;
  static const Duration _timeout = Duration(seconds: 60);

  /// Live status text (download / loading progress) for the UI.
  final ValueNotifier<String> statusText = ValueNotifier<String>('');

  OneNm? _ai;
  bool _ready = false;
  bool _busy = false;
  bool? _capable;

  static const String _systemPrompt =
      'You are a friendly maths tutor for Bangladeshi Class 6 students '
      '(NCTB curriculum). Reply in simple Bengali. Use at most 4 short '
      'sentences. The correct answer given to you is verified, so never '
      'change it. Explain the steps simply and do not invent facts.';

  Future<bool> _canRunModel() async {
    if (_capable != null) return _capable!;
    bool ok = false;
    try {
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        final has64 = info.supported64BitAbis.contains('arm64-v8a');
        final ramOk = info.physicalRamSize >= 3500; // MB, 4 GB phone ~3.7 GB
        ok =
            has64 && ramOk && !info.isLowRamDevice && info.version.sdkInt >= 24;
      }
    } catch (_) {
      ok = false;
    }
    _capable = ok;
    return ok;
  }

  Future<bool> _ensureReady() async {
    if (_ready) return true;
    try {
      _ai ??= OneNm(
        model: _model,
        settings: GenerationSettings(
          temperature: 0.3,
          topK: 40,
          topP: 0.9,
          maxTokens: 160,
          repeatPenalty: 1.1,
        ),
        onProgress: (msg) => statusText.value = msg,
        onRetryRequired: (message) async => false,
      );
      await _ai!.initialize();
      _ready = true;
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  DoubtResult _fallback(String? bookExplanation) {
    final t = (bookExplanation ?? '').trim();
    if (t.isEmpty) {
      return DoubtResult(
        'এই ফোনে Doubt Solver এখন চালু করা যাচ্ছে না।',
        DoubtSource.unavailable,
      );
    }
    return DoubtResult(t, DoubtSource.bookExplanation);
  }

  String _buildPrompt({
    required String questionText,
    required List<String> options,
    required String correctOption,
    String? bookExplanation,
    String? studentDoubt,
  }) {
    const letters = ['A', 'B', 'C', 'D'];
    final idx = letters.indexOf(correctOption.trim().toUpperCase());
    final correctText = (idx >= 0 && idx < options.length)
        ? options[idx]
        : correctOption;
    final opts = StringBuffer();
    for (var i = 0; i < options.length && i < 4; i++) {
      opts.writeln('${letters[i]}) ${options[i]}');
    }
    final doubt = (studentDoubt == null || studentDoubt.isEmpty)
        ? 'Explain why this answer is correct.'
        : studentDoubt;
    return 'Question: $questionText\n'
        'Options:\n$opts'
        'Correct answer: ${correctOption.toUpperCase()}) $correctText\n'
        'Book explanation: ${bookExplanation ?? '-'}\n'
        'Student doubt: $doubt';
  }

  Future<DoubtResult> ask({
    required String questionText,
    required List<String> options,
    required String correctOption,
    String? bookExplanation,
    String? studentDoubt,
  }) async {
    if (_busy) {
      return DoubtResult(
        'আগের উত্তর তৈরি হচ্ছে, একটু অপেক্ষা করো।',
        DoubtSource.unavailable,
      );
    }
    if (!await _canRunModel()) return _fallback(bookExplanation);

    _busy = true;
    final sw = Stopwatch()..start();
    Future<String>? work;
    try {
      if (!await _ensureReady()) return _fallback(bookExplanation);
      _ai!.clearHistory(); // each doubt is independent (saves memory/time)
      work = _ai!.chat(
        _buildPrompt(
          questionText: questionText,
          options: options,
          correctOption: correctOption,
          bookExplanation: bookExplanation,
          studentDoubt: studentDoubt,
        ),
        systemPrompt: _systemPrompt,
      );
      // Stay "busy" until the native call really finishes, even after timeout.
      unawaited(work.then((_) => _busy = false, onError: (_) => _busy = false));
      final reply = (await work.timeout(_timeout)).trim();
      if (reply.isEmpty) return _fallback(bookExplanation);
      return DoubtResult(reply, DoubtSource.model, sw.elapsed);
    } catch (_) {
      return _fallback(bookExplanation);
    } finally {
      if (work == null) _busy = false;
    }
  }

  /// Frees the model from memory (optional, for low-RAM phones).
  Future<void> release() async {
    try {
      await _ai?.dispose();
    } catch (_) {}
    _ai = null;
    _ready = false;
  }
}
