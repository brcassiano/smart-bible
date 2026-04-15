import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/ai_prompts.dart';

enum ModelDownloadStatus { idle, downloading, complete, error }

class ModelDownloadProgress {
  const ModelDownloadProgress({
    required this.status,
    this.bytesReceived = 0,
    this.totalBytes = 0,
    this.errorMessage,
    this.modelPath,
  });

  final ModelDownloadStatus status;
  final int bytesReceived;
  final int totalBytes;
  final String? errorMessage;
  final String? modelPath;

  double get progress =>
      totalBytes > 0 ? bytesReceived / totalBytes : 0.0;
}

class ModelDownloadService {
  static const _modelPathKey = 'ai_model_path';
  static const _maxRetries = 3;
  static const _connectionTimeoutSeconds = 30;

  bool _cancelled = false;

  Future<String?> getSavedModelPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_modelPathKey);
    if (path == null) return null;
    if (!File(path).existsSync()) {
      await prefs.remove(_modelPathKey);
      return null;
    }
    return path;
  }

  void cancelDownload() {
    _cancelled = true;
  }

  Stream<ModelDownloadProgress> downloadModel({
    String url = defaultModelUrl,
    String fileName = defaultModelFileName,
  }) async* {
    _cancelled = false;
    yield const ModelDownloadProgress(status: ModelDownloadStatus.downloading);

    Exception? lastException;

    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      if (_cancelled) {
        yield const ModelDownloadProgress(
          status: ModelDownloadStatus.error,
          errorMessage: 'Download cancelado pelo usuário.',
        );
        return;
      }

      if (attempt > 1) {
        final delaySeconds = 1 << (attempt - 2); // 1s, 2s, 4s
        yield ModelDownloadProgress(
          status: ModelDownloadStatus.downloading,
          errorMessage:
              'Tentativa $attempt de $_maxRetries. Aguardando ${delaySeconds}s...',
        );
        await Future<void>.delayed(Duration(seconds: delaySeconds));
      }

      try {
        yield* _attemptDownload(url: url, fileName: fileName, attempt: attempt);
        return;
      } on Exception catch (e) {
        lastException = e;
        if (_cancelled || attempt == _maxRetries) break;
        // Continue to next retry iteration
      }
    }

    final errorMsg = _buildErrorMessage(lastException);
    yield ModelDownloadProgress(
      status: ModelDownloadStatus.error,
      errorMessage: 'Falha após $_maxRetries tentativas. $errorMsg',
    );
  }

  /// Sends a GET request following redirects manually (up to 5 hops).
  /// The Dart http package does not follow redirects for streamed requests
  /// when followRedirects is not properly handled (e.g. GitHub → Azure CDN).
  Future<http.StreamedResponse> _sendWithRedirects(
    http.Client client,
    Uri url, {
    Map<String, String>? headers,
    int existingBytes = 0,
  }) async {
    var currentUrl = url;
    for (var i = 0; i < 5; i++) {
      final request = http.Request('GET', currentUrl);
      if (headers != null) request.headers.addAll(headers);
      if (existingBytes > 0) {
        request.headers['Range'] = 'bytes=$existingBytes-';
      }
      request.followRedirects = false;

      final response = await client.send(request).timeout(
            const Duration(seconds: _connectionTimeoutSeconds),
            onTimeout: () => throw TimeoutException(
              'Conexão expirou após ${_connectionTimeoutSeconds}s.',
            ),
          );

      if (response.statusCode == 301 ||
          response.statusCode == 302 ||
          response.statusCode == 307 ||
          response.statusCode == 308) {
        final location = response.headers['location'];
        if (location == null) throw Exception('Redirect sem Location header');
        currentUrl = Uri.parse(location);
        await response.stream.drain<void>();
        continue;
      }

      return response;
    }
    throw Exception('Muitos redirects');
  }

  Stream<ModelDownloadProgress> _attemptDownload({
    required String url,
    required String fileName,
    required int attempt,
  }) async* {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(dir.path, fileName);
    final file = File(filePath);

    // Check for partial file to resume download
    var alreadyDownloaded = 0;
    if (file.existsSync()) {
      alreadyDownloaded = await file.length();
    }

    yield ModelDownloadProgress(
      status: ModelDownloadStatus.downloading,
      bytesReceived: alreadyDownloaded,
      totalBytes: kModelSizeBytes,
      errorMessage: 'Iniciando download...',
    );

    final client = http.Client();
    try {
      final response = await _sendWithRedirects(
        client,
        Uri.parse(url),
        headers: {'Accept': 'application/octet-stream'},
        existingBytes: alreadyDownloaded,
      );

      // 200 = full content, 206 = partial content (resume)
      if (response.statusCode == 404) {
        throw Exception('URL do modelo inválida ou não encontrada (404)');
      }
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception(
          'Erro HTTP ${response.statusCode}: ${response.reasonPhrase ?? "Erro desconhecido"}',
        );
      }

      // If server returned 206, we resume; otherwise start fresh
      final isResuming = response.statusCode == 206 && alreadyDownloaded > 0;
      if (!isResuming) {
        alreadyDownloaded = 0;
      }

      final contentLength = response.contentLength;
      final total = contentLength != null
          ? (isResuming ? alreadyDownloaded + contentLength : contentLength)
          : kModelSizeBytes;

      var received = alreadyDownloaded;

      // Open file in append mode if resuming, otherwise overwrite
      final sink = isResuming
          ? file.openWrite(mode: FileMode.append)
          : file.openWrite();

      try {
        await for (final chunk in response.stream) {
          if (_cancelled) {
            await sink.close();
            // Keep partial file for resume on next attempt
            yield const ModelDownloadProgress(
              status: ModelDownloadStatus.error,
              errorMessage: 'Download cancelado pelo usuário.',
            );
            return;
          }
          sink.add(chunk);
          received += chunk.length;
          yield ModelDownloadProgress(
            status: ModelDownloadStatus.downloading,
            bytesReceived: received,
            totalBytes: total,
          );
        }

        await sink.flush();
        await sink.close();
      } catch (e) {
        await sink.close();
        // Don't delete partial file — keep for resume
        rethrow;
      }
    } finally {
      client.close();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelPathKey, filePath);

    yield ModelDownloadProgress(
      status: ModelDownloadStatus.complete,
      modelPath: filePath,
    );
  }

  String _buildErrorMessage(Exception? e) {
    if (e == null) return 'Erro desconhecido.';
    if (e is SocketException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('failed host lookup') ||
          msg.contains('no address associated')) {
        return 'Servidor não encontrado. Verifique sua conexão.';
      }
      return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
    }
    if (e is TimeoutException) {
      return 'Download expirou. Tente novamente.';
    }
    final msg = e.toString();
    // Strip "Exception: " prefix for cleaner display
    return msg.startsWith('Exception: ') ? msg.substring(11) : msg;
  }
}
