// Stub untuk platform non-web (Android, iOS, Desktop).
// Di mobile, download CSV ditangani via share_plus di TransactionProvider.
void triggerWebDownload(List<int> bytes, String filename) {
  throw UnsupportedError('triggerWebDownload hanya bisa dipanggil di web.');
}
