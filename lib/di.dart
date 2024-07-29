import 'package:araidashisan/local_storage.dart';
import 'package:get_it/get_it.dart';

/// DIコンテナのセットアップを行う。
Future<void> setupDi() async {
  GetIt.I.registerSingleton(LocalStorage());
}
