import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../utils/download_helper.dart'; // web CSV download
import '../utils/mobile_saver.dart';    // mobile CSV share

class TransactionProvider extends ChangeNotifier {
  final _api = ApiService();

  List<TransactionModel> _transactions = [];
  Map<String, dynamic> _balance = {};
  Map<String, dynamic> _stats = {};

  bool _isLoading = false;
  bool _isCsvLoading = false;
  String? _error;

  // Filter state
  int? filterMonth;
  int? filterYear;
  int _page = 1;
  int _totalPages = 1;
  String sortBy = 'created_at';
  String sortOrder = 'desc';

  List<TransactionModel> get transactions => _transactions;
  Map<String, dynamic> get balance => _balance;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isCsvLoading => _isCsvLoading;
  String? get error => _error;
  bool get hasNextPage => _page < _totalPages;
  int get currentPage => _page;

  // ─── LOAD TRANSACTIONS ─────────────────────────────────────────────────────

  Future<void> loadTransactions({bool reset = true}) async {
    if (reset) _page = 1;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{
        'page': '$_page',
        'page_size': '15',
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };
      if (filterMonth != null) params['month'] = '$filterMonth';
      if (filterYear != null) params['year'] = '$filterYear';

      final result = await _api.get('/transactions', queryParams: params);
      if (result.isSuccess) {
        final data = result.body['data'] as List? ?? [];
        if (reset) {
          _transactions = data.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
        } else {
          _transactions.addAll(data.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)));
        }
        _totalPages = result.body['total_pages'] as int? ?? 1;
      } else {
        _error = result.errorMessage;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage() async {
    if (!hasNextPage || _isLoading) return;
    _page++;
    await loadTransactions(reset: false);
  }

  // ─── LOAD BALANCE ──────────────────────────────────────────────────────────

  Future<void> loadBalance() async {
    try {
      final result = await _api.get('/balance');
      if (result.isSuccess) {
        _balance = result.body;
        notifyListeners();
      }
    } catch (_) {}
  }

  // ─── LOAD STATS ────────────────────────────────────────────────────────────

  Future<void> loadStats() async {
    try {
      final result = await _api.get('/stats');
      if (result.isSuccess) {
        _stats = result.body;
        notifyListeners();
      }
    } catch (_) {}
  }

  // ─── CREATE ────────────────────────────────────────────────────────────────

  Future<bool> createTransaction({
    required String type,
    required double amount,
    required String category,
    required String note,
  }) async {
    try {
      final result = await _api.post('/transactions', {
        'type': type,
        'amount': amount,
        'category': category,
        'note': note,
      });
      if (result.isSuccess) {
        await Future.wait([loadTransactions(), loadBalance()]);
        return true;
      }
      _error = result.errorMessage;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  // ─── UPDATE ────────────────────────────────────────────────────────────────

  Future<bool> updateTransaction({
    required String id,
    String? type,
    double? amount,
    String? category,
    String? note,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (type != null) body['type'] = type;
      if (amount != null) body['amount'] = amount;
      if (category != null) body['category'] = category;
      if (note != null) body['note'] = note;

      final result = await _api.put('/transactions/$id', body);
      if (result.isSuccess) {
        await Future.wait([loadTransactions(), loadBalance()]);
        return true;
      }
      _error = result.errorMessage;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  // ─── DELETE ────────────────────────────────────────────────────────────────

  Future<bool> deleteTransaction(String id) async {
    try {
      final result = await _api.delete('/transactions/$id');
      if (result.isSuccess) {
        _transactions.removeWhere((t) => t.id == id);
        notifyListeners();
        await loadBalance();
        return true;
      }
      _error = result.errorMessage;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  // ─── EXPORT CSV ────────────────────────────────────────────────────────────

  Future<void> exportCsv(BuildContext context) async {
    _isCsvLoading = true;
    notifyListeners();

    try {
      final response = await _api.getRaw('/export/csv');
      if (response.statusCode != 200) {
        throw ApiException('Gagal export CSV (${response.statusCode})');
      }

      if (kIsWeb) {
        // ── Web (Chrome): trigger download langsung lewat browser ──────────
        triggerWebDownload(
          response.bodyBytes,
          'transactions_${DateTime.now().millisecondsSinceEpoch}.csv',
        );
      } else {
        // ── Mobile (Android/iOS): simpan ke temp dir lalu share ───────────
        await saveAndShareCsv(response.bodyBytes);
      }
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = 'Gagal mengekspor CSV: $e';
      notifyListeners();
    } finally {
      _isCsvLoading = false;
      notifyListeners();
    }
  }

  // ─── FILTER ────────────────────────────────────────────────────────────────

  void setFilter({int? month, int? year}) {
    filterMonth = month;
    filterYear = year;
    loadTransactions();
  }

  void clearFilter() {
    filterMonth = null;
    filterYear = null;
    loadTransactions();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
