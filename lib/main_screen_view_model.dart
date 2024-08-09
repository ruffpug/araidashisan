import 'package:araidashisan/input.dart';
import 'package:araidashisan/local_storage.dart';
import 'package:araidashisan/logger.dart';
import 'package:araidashisan/pattern_table.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

const String _tag = 'MainScreenViewModel';

/// メイン画面のViewModel
class MainScreenViewModel {
  MainScreenViewModel(this._localStorage) {
    logger.d('$_tag()');
  }

  final LocalStorage _localStorage;

  bool get _isDisposed => _subscriptions.isDisposed;
  final _subscriptions = CompositeSubscription();
  final _isInitialized = BehaviorSubject.seeded(false);
  final _userInput = BehaviorSubject.seeded('');
  final _patternTable = BehaviorSubject<PatternTable?>.seeded(null);
  final _errorMessage =
      BehaviorSubject<InvalidResultErrorMessage?>.seeded(null);
  final _displayingClipboardMessageRequested = PublishSubject<void>();

  /// 初期化済みかどうか
  late final ValueStream<bool> isInitialized = _isInitialized.stream;

  /// ユーザ入力
  late final ValueStream<String> userInput = _userInput.stream;

  /// パターンテーブル (ユーザ入力が無効な場合はnull)
  late final ValueStream<PatternTable?> patternTable = _patternTable.stream;

  /// エラーメッセージ (エラーが発生していない場合はnull)
  late final ValueStream<InvalidResultErrorMessage?> errorMessage =
      _errorMessage.stream;

  /// クリップボードメッセージの表示要求を通知するイベント
  late final Stream<void> displayingClipboardMessageRequested =
      _displayingClipboardMessageRequested.stream;

  /// 初期化を行う。
  void initialize() {
    logger.d('$_tag#initialize()');

    //  ユーザ入力の初期値を読み込む。
    _loadInitialUserInput();
  }

  /// 終了処理を行う。
  void dispose() {
    logger.d('$_tag#dispose()');
    _subscriptions.dispose();
    _isInitialized.close();
    _userInput.close();
    _patternTable.close();
    _errorMessage.close();
    _displayingClipboardMessageRequested.close();
  }

  /// ユーザ入力が変化したとき。
  void onUserInputChanged(String value) {
    logger.d('$_tag#ユーザ入力変化: $value ← ${_userInput.value}');

    //  ユーザ入力を更新する。
    _userInput.value = value;

    //  パース処理を行う。
    _parse(value);

    //  ユーザ入力を保存する。
    _localStorage.saveUserInput(value);
  }

  /// Markdownとしてコピーボタンがクリックされたとき。
  void onCopyAsMarkdownButtonClicked() {
    final PatternTable? patternTable = _patternTable.value;
    logger.i('$_tag#Markdownとしてコピーボタン押下: $patternTable');
    if (patternTable == null) return;

    //  コピーを行う。
    _copyAsMarkdown(patternTable);
  }

  /// CSVとしてコピーボタンがクリックされたとき。
  void onCopyAsCsvButtonClicked() {
    final PatternTable? patternTable = _patternTable.value;
    logger.i('$_tag#CSVとしてコピーボタン押下: $patternTable');
    if (patternTable == null) return;

    //  コピーを行う。
    _copyAsCsv(patternTable);
  }

  /// TSVとしてコピーボタンがクリックされたとき。
  void onCopyAsTsvButtonClicked() {
    final PatternTable? patternTable = _patternTable.value;
    logger.i('$_tag#TSVとしてコピーボタン押下: $patternTable');
    if (patternTable == null) return;

    //  コピーを行う。
    _copyAsTsv(patternTable);
  }

  //  ユーザ入力の初期値を読み込む。
  Future<void> _loadInitialUserInput() async {
    logger.d('$_tag#ユーザ入力初期値読み込み 開始');

    //  未初期化状態を設定する。
    _isInitialized.value = false;

    //  保存されている以前のユーザ入力を読み出す。
    final String? prevUserInput = await _localStorage.loadSavedUserInput();
    if (_isDisposed) return;
    logger.d('$_tag#ユーザ入力初期値読み込み 値: $prevUserInput');

    //  ユーザ入力の値をUIに反映させる。
    _userInput.value = prevUserInput ?? '';
    _parse(_userInput.value);

    //  初期化済み状態を設定する。
    _isInitialized.value = true;

    logger.d('$_tag#ユーザ入力初期値読み込み 終了');
  }

  //  パース処理を行う。
  void _parse(String userInputValue) {
    //  ユーザ入力をパースする。
    final String userInputValue = _userInput.value;
    final InputParserResult result = InputParser.parse(userInputValue);
    logger.d('$_tag#パース結果: $result');

    switch (result) {
      //  有効
      case InputParserResultValid():
        _handleValidResult(result);

      //  無効
      case InputParserResultInvalid():
        _handleInvalidResult(result);

      //  空
      case InputParserResultEmpty():
        _handleEmptyResult(result);
    }
  }

  //  有効なユーザ入力結果をハンドリングする。
  void _handleValidResult(InputParserResultValid result) {
    //  エラーメッセージを取り下げる。
    _errorMessage.value = null;

    //  入力リストが変化していないかを見ることにより、パターンテーブルへの変換処理をスキップすべきかどうかを判定する。
    final PatternTable? prevTable = _patternTable.value;
    final bool shouldSkip = prevTable?.inputList == result.inputList;

    //  スキップすべき場合
    if (shouldSkip) {
      logger.d('$_tag#パターンテーブル更新スキップ');
    }

    //  スキップすべきではない場合
    else {
      //  パターンテーブルに変換してUIを更新する。
      final PatternTable patternTable =
          PatternTableConverter.fromInputListToPatternTable(result.inputList);
      _patternTable.value = patternTable;
      logger.d('$_tag#パターンテーブル更新結果: $patternTable');
    }
  }

  //  無効なユーザ入力結果をハンドリングする。
  void _handleInvalidResult(InputParserResultInvalid result) {
    //  エラーメッセージを設定する。
    _errorMessage.value = result.errorMessage;
  }

  //  空のユーザ入力結果をハンドリングする。
  void _handleEmptyResult(InputParserResultEmpty result) {
    //  エラーメッセージを取り下げる。
    _errorMessage.value = null;
  }

  //  Markdownとしてコピーを行う。
  Future<void> _copyAsMarkdown(PatternTable patternTable) async {
    logger.i('$_tag#Markdownとしてコピー: $patternTable');

    //  Markdownに変換してクリップボードにコピーする。
    final String markdown =
        PatternTableConverter.fromPatternTableToMarkdownString(patternTable);
    await Clipboard.setData(ClipboardData(text: markdown));
    if (_isDisposed) return;

    //  クリップボードメッセージを表示させる。
    _displayingClipboardMessageRequested.add(null);
  }

  //  CSVとしてコピーを行う。
  Future<void> _copyAsCsv(PatternTable patternTable) async {
    logger.i('$_tag#CSVとしてコピー: $patternTable');

    //  CSVに変換してクリップボードにコピーする。
    final String tsv =
        PatternTableConverter.fromPatternTableToCsvString(patternTable);
    await Clipboard.setData(ClipboardData(text: tsv));
    if (_isDisposed) return;

    //  クリップボードメッセージを表示させる。
    _displayingClipboardMessageRequested.add(null);
  }

  //  TSVとしてコピーを行う。
  Future<void> _copyAsTsv(PatternTable patternTable) async {
    logger.i('$_tag#TSVとしてコピー: $patternTable');

    //  TSVに変換してクリップボードにコピーする。
    final String tsv =
        PatternTableConverter.fromPatternTableToTsvString(patternTable);
    await Clipboard.setData(ClipboardData(text: tsv));
    if (_isDisposed) return;

    //  クリップボードメッセージを表示させる。
    _displayingClipboardMessageRequested.add(null);
  }
}
