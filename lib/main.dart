import 'package:araidashisan/di.dart';
import 'package:araidashisan/logger.dart';
import 'package:araidashisan/my_app.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //  Loggerを初期化する。
  await initializeLogger();

  //  DIコンテナのセットアップを行う。
  await setupDi();

  //  アプリを起動する。
  logger.i('アプリ起動');
  run App(const MyApp());

  //  ↑ わざとビルドが通らないようにしてみる。
}
