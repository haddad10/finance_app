// Stub untuk web — platform mobile tidak menggunakan file ini.
// Fungsi ini tidak akan pernah dipanggil di web karena dikontrol via kIsWeb.

Future<String> getTempPath() async => '';

Future<void> saveAndShareCsv(List<int> bytes) async {
  throw UnsupportedError('saveAndShareCsv tidak tersedia di web.');
}
