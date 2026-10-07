import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

late final PocketBase pb;

/// Inicializa o PocketBase guardando a sessão no aparelho (login lembrado).
Future<void> initPb() async {
  final prefs = await SharedPreferences.getInstance();
  final store = AsyncAuthStore(
    save: (String data) async => prefs.setString('pb_auth', data),
    clear: () async => prefs.remove('pb_auth'),
    initial: prefs.getString('pb_auth'),
  );
  pb = PocketBase(kPocketBaseUrl, authStore: store);
}

bool isValidEmail(String v) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

const kDarkBlue = Color(0xFF0D2A6B);

String fileUrl(RecordModel r, String file) =>
    '$kPocketBaseUrl/api/files/${r.collectionId}/${r.id}/$file';

String fmtDate(RecordModel r) {
  final raw = r.toJson()['created']?.toString() ?? '';
  final d = DateTime.tryParse(raw.replaceFirst(' ', 'T'))?.toLocal();
  return d == null ? '' : DateFormat('dd/MM/yyyy HH:mm').format(d);
}

String errMsg(Object e) {
  if (e is ClientException) {
    final m = e.response['message'];
    final data = e.response['data'];
    if (data is Map && data.isNotEmpty) {
      final first = data.values.first;
      if (first is Map && first['message'] != null) return first['message'].toString();
    }
    if (m != null) return m.toString();
  }
  return e.toString();
}

void snack(BuildContext c, String msg) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg)));
