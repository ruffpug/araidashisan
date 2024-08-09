import 'package:web/web.dart';

/// LocalStorageのヘルパ
final class LocalStorage {
  static const String _key = 'USER_INPUT';

  //  TODO: 処理の間引き等の検討

  /// 保存済みのユーザ入力を取得する。
  /// (保存されているものが存在しない場合はnullを返す。)
  Future<String?> loadSavedUserInput() async {
    final String? savedUserInput = window.localStorage.getItem(_key);
    return savedUserInput;
  }

  /// ユーザ入力を保存する。
  Future<void> saveUserInput(String input) async {
    window.localStorage.setItem(_key, input);
  }
}
