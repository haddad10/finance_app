import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Simpan CSV ke temporary file lalu buka share sheet (Android/iOS).
Future<void> saveAndShareCsv(List<int> bytes) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/transactions_${DateTime.now().millisecondsSinceEpoch}.csv');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/csv')],
    subject: 'Finance Transactions Export',
  );
}
