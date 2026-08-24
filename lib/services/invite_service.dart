import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class InviteService {
  static const _uuid = Uuid();
  static const _tokensKey = 'sangam_invite_tokens';

  static Future<String> generateInviteLink({required String staffName, required String shopId}) async {
    final staffId = staffName.toLowerCase().replaceAll(' ', '_');
    final token = _uuid.v4().replaceAll('-', '').substring(0, 16);
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_tokensKey) ?? '{}';
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    map[token] = {'staffId': staffId, 'shopId': shopId, 'staffName': staffName};
    await p.setString(_tokensKey, jsonEncode(map));
    return 'sangam://invite?staff_id=$staffId&shop_id=$shopId&token=$token';
  }

  static Future<Map<String, String>?> validateToken(String token) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_tokensKey) ?? '{}';
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    final v = map[token];
    if (v == null) return null;
    return {
      'staffId': v['staffId'].toString(),
      'shopId': v['shopId'].toString(),
      'staffName': v['staffName'].toString(),
    };
  }
}
