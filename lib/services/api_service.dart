import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Response wrapper dari API
class ApiResult {
  final int statusCode;
  final Map<String, dynamic> body;
  final List<dynamic>? listBody;
  final bool isSuccess;

  ApiResult({
    required this.statusCode,
    required this.body,
    this.listBody,
  }) : isSuccess = statusCode >= 200 && statusCode < 300;

  String get errorMessage => body['error'] as String? ?? 'Terjadi kesalahan';
  String get message => body['message'] as String? ?? '';
}

/// Central HTTP client — kompatibel dengan Web & Mobile (tidak pakai dart:io).
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _client = http.Client();
  String? _token;

  void setToken(String? token) => _token = token;
  String? get token => _token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ─── GET ───────────────────────────────────────────────────────────────────

  Future<ApiResult> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    var uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    try {
      final res = await _client.get(uri, headers: _headers).timeout(
        const Duration(seconds: 15),
      );
      return _parseResponse(res);
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server. Periksa koneksi internet.');
    }
  }

  // ─── GET RAW (untuk CSV download) ─────────────────────────────────────────

  Future<http.Response> getRaw(String path) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    try {
      return await _client.get(uri, headers: _headers).timeout(
        const Duration(seconds: 30),
      );
    } catch (e) {
      throw ApiException('Gagal mengunduh file dari server.');
    }
  }

  // ─── POST ──────────────────────────────────────────────────────────────────

  Future<ApiResult> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    try {
      final res = await _client
          .post(uri, headers: _headers, body: json.encode(body))
          .timeout(const Duration(seconds: 15));
      return _parseResponse(res);
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server.');
    }
  }

  // ─── PUT ───────────────────────────────────────────────────────────────────

  Future<ApiResult> put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    try {
      final res = await _client
          .put(uri, headers: _headers, body: json.encode(body))
          .timeout(const Duration(seconds: 15));
      return _parseResponse(res);
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server.');
    }
  }

  // ─── DELETE ────────────────────────────────────────────────────────────────

  Future<ApiResult> delete(String path) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    try {
      final res = await _client
          .delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      return _parseResponse(res);
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server.');
    }
  }

  // ─── HELPER ────────────────────────────────────────────────────────────────

  ApiResult _parseResponse(http.Response res) {
    final decoded = json.decode(res.body);
    if (decoded is Map<String, dynamic>) {
      return ApiResult(statusCode: res.statusCode, body: decoded);
    }
    return ApiResult(statusCode: res.statusCode, body: {'_raw': decoded});
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}
