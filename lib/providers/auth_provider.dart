import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _tokenKey = 'jwt_token';
  static const _localPhotoKey = 'local_photo_path';

  UserModel? _user;
  String? _token;
  bool _isLoading = true;
  String? _error;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _api = ApiService();

  /// Dipanggil saat app start — restore token dari SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);
    if (savedToken != null) {
      _token = savedToken;
      _api.setToken(savedToken);
      await _fetchProfile();
      // Restore foto lokal yang disimpan di perangkat
      final localPhoto = prefs.getString(_localPhotoKey);
      if (localPhoto != null && _user != null) {
        _user = UserModel(
          id: _user!.id,
          username: _user!.username,
          email: _user!.email,
          photoUrl: localPhoto,
          createdAt: _user!.createdAt,
        );
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  // ─── REGISTER ──────────────────────────────────────────────────────────────

  Future<bool> register(String username, String email, String password) async {
    _error = null;
    try {
      final result = await _api.post('/register', {
        'username': username,
        'email': email,
        'password': password,
      });
      if (!result.isSuccess) {
        _error = result.errorMessage;
        notifyListeners();
        return false;
      }
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  // ─── LOGIN ─────────────────────────────────────────────────────────────────

  Future<bool> login(String username, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _api.post('/login', {
        'username': username,
        'password': password,
      });

      if (!result.isSuccess) {
        _error = result.errorMessage;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _token = result.body['token'] as String;
      final userJson = result.body['user'] as Map<String, dynamic>;
      _user = UserModel.fromJson(userJson);

      _api.setToken(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    notifyListeners();
  }

  // ─── SAVE LOCAL PHOTO ──────────────────────────────────────────────────────

  /// Simpan path foto lokal ke SharedPreferences agar persisten antar sesi.
  Future<void> saveLocalPhoto(String localPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localPhotoKey, localPath);
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        username: _user!.username,
        email: _user!.email,
        photoUrl: localPath,
        createdAt: _user!.createdAt,
      );
      notifyListeners();
    }
  }

  // ─── UPDATE PROFILE ────────────────────────────────────────────────────────

  Future<bool> updateProfile({String? username, String? email, String? photoUrl}) async {
    _error = null;

    // ── 1. Update lokal dulu (offline-first, langsung terasa di UI) ──
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        username: username ?? _user!.username,
        email: email ?? _user!.email,
        photoUrl: photoUrl ?? _user!.photoUrl,
        createdAt: _user!.createdAt,
      );
      notifyListeners();
    }

    // ── 2. Coba sinkron ke server (opsional, nggak bikin crash kalau mati) ──
    try {
      final body = <String, dynamic>{};
      if (username != null) body['username'] = username;
      if (email != null) body['email'] = email;
      if (photoUrl != null) body['photo_url'] = photoUrl;

      if (body.isNotEmpty) {
        final result = await _api.put('/profile', body);
        if (result.isSuccess) {
          _user = UserModel.fromJson(result.body);
          notifyListeners();
        }
      }
    } catch (_) {
      // Server tidak tersedia — perubahan lokal tetap tersimpan di session ini
    }

    return true;
  }

  // ─── PRIVATE ───────────────────────────────────────────────────────────────

  Future<void> _fetchProfile() async {
    try {
      final result = await _api.get('/profile');
      if (result.isSuccess) {
        _user = UserModel.fromJson(result.body);
      } else {
        // Token tidak valid, hapus
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
        _token = null;
        _api.setToken(null);
      }
    } catch (_) {
      // Jika gagal fetch profile, tetap logout
      _token = null;
      _api.setToken(null);
    }
  }
}
