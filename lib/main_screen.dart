import 'package:araidashisan/input.dart';
import 'package:araidashisan/l10n/app_localizations.dart';
import 'package:araidashisan/local_storage.dart';
import 'package:araidashisan/logger.dart';
import 'package:araidashisan/main_screen_view_model.dart';
import 'package:araidashisan/pattern_table.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';

const String _tag = 'MainScreen';

//  デフォルトのViewModelの生成処理
MainScreenViewModel _defaultViewModelFactory() {
  final LocalStorage localStorage = GetIt.I.get<LocalStorage>();

  return MainScreenViewModel(localStorage);
}

/// メイン画面
class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    this.viewModelFactory = _defaultViewModelFactory,
  });

  /// ViewModelの生成処理
  final MainScreenViewModel Function() viewModelFactory;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  //  メイン画面のViewModel
  late final MainScreenViewModel _viewModel;

  //  購読
  late final CompositeSubscription _subscriptions;

  //  ユーザ入力のコントローラ
  late final TextEditingController _userInputController;

  //  スクロールのコントローラ
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    logger.d('$_tag#initState()');

    //  ViewModelを生成する。
    _viewModel = widget.viewModelFactory();
    _subscriptions = CompositeSubscription();

    //  コントローラを初期化する。
    _userInputController = TextEditingController(text: '');
    _scrollController = ScrollController();

    //  ユーザ入力の変化を購読する。
    _viewModel.userInput.listen((String userInput) {
      //  コントローラが保持している値と異なる場合
      if (_userInputController.text != userInput) {
        //  コントローラの値を更新する。
        _userInputController.value =
            _userInputController.value.copyWith(text: userInput);
      }
    }).addTo(_subscriptions);

    //  クリップボードメッセージの表示要求を購読する。
    _viewModel.displayingClipboardMessageRequested
        .listen((_) => _showClipboardMessage())
        .addTo(_subscriptions);

    //  ViewModelを初期化する。
    _viewModel.initialize();
  }

  @override
  void dispose() {
    logger.d('$_tag#dispose()');
    _subscriptions.dispose();
    _viewModel.dispose();
    _userInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        body: StreamBuilder(
          initialData: _viewModel.isInitialized.value,
          stream: _viewModel.isInitialized,
          builder: (context, snapshot) {
            final bool isInitialized = snapshot.requireData;

            //  未初期化の場合
            if (!isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }

            //  初期化済みの場合
            return SingleChildScrollView(
              child: Column(
                children: [
                  //  上部ボタン群
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildTopButtons(),
                  ),

                  //  ユーザ入力
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 4),
                    child: _buildUserInputForm(),
                  ),

                  //  エラーアイコン
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 4, 32, 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _buildErrorIcon(),
                    ),
                  ),

                  //  テーブル
                  StreamBuilder(
                    initialData: _viewModel.patternTable.value,
                    stream: _viewModel.patternTable,
                    builder: (context, snapshot) {
                      final table = snapshot.data;

                      //  パターンテーブルが未設定の場合、何も描画させない。
                      if (table == null) return Container();

                      //  パターンテーブルが設定されている場合、描画を行う。
                      return _buildPatternTable(table);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  //  上部ボタン群を生成する。
  Widget _buildTopButtons() {
    final l10n = requireAppLocalizations(context);

    return Row(
      children: [
        //  ソースコードボタン
        TextButton(
          onPressed: _openRepositoryPage,
          child: Text(l10n.sourceCodeButton),
        ),

        //  ライセンスボタン
        TextButton(
          onPressed: _toLicensePage,
          child: Text(l10n.licenseButton),
        ),
      ],
    );
  }

  //  ユーザ入力フォームを生成する。
  Widget _buildUserInputForm() {
    return StreamBuilder(
      initialData: _viewModel.errorMessage.value != null,
      stream: _viewModel.errorMessage.map((e) => e != null).distinct(),
      builder: (context, snapshot) {
        final String hint = requireAppLocalizations(context).example;
        final bool hasError = snapshot.requireData;

        //  NOTE: エラー有無に応じてTextFormFieldの高さが頻繁に変わる挙動を避けるため、
        //   エラーアイコン自体は別Widgetとして描画させることとし、
        //   ここでは空のコンテナを渡して、エラーの有無のみを表現する。
        final Widget? errorWidget = hasError ? Container() : null;

        return TextFormField(
          controller: _userInputController,
          maxLines: null,
          decoration: InputDecoration(hintText: hint, error: errorWidget),
          onChanged: _viewModel.onUserInputChanged,
        );
      },
    );
  }

  //  エラーアイコンを設定する。
  Widget _buildErrorIcon() {
    return StreamBuilder(
      initialData: _viewModel.errorMessage.value,
      stream: _viewModel.errorMessage,
      builder: (context, snapshot) {
        final InvalidResultErrorMessage? errorMessage = snapshot.data;

        //  NOTE: エラーの有無によって高さ頻繁に変わる挙動を避けるため、非表示時も高さを保持させる。
        return Visibility(
          visible: errorMessage != null,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: IconButton(
            onPressed: () {
              if (errorMessage != null) _showErrorMessageDialog(errorMessage);
            },
            icon: const Icon(Icons.error, color: Colors.red),
          ),
        );
      },
    );
  }

  //  パターンテーブルを生成する。
  Widget _buildPatternTable(PatternTable table) {
    final l10n = requireAppLocalizations(context);
    //  FIXME: 件数が多すぎる場合のパフォーマンス改善検討

    //  見出し部分を生成する。
    final List<DataColumn> columns = table.headers
        .map((header) => DataColumn(label: Text(header.name)))
        .toList();

    //  行部分を生成する。
    final List<DataRow> rows = table.rowList.map((row) {
      return DataRow(
        cells: row.values.map((value) => DataCell(Text(value.value))).toList(),
      );
    }).toList();

    return Column(
      children: [
        //  結果表示
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(l10n.result(table.rowList.length.toString())),
        ),

        //  Markdownとしてコピーボタン
        Padding(
          padding: const EdgeInsets.all(8),
          child: ElevatedButton(
            onPressed: _viewModel.onCopyAsMarkdownButtonClicked,
            child: Text(l10n.copyAsMarkdownButton, textAlign: TextAlign.center),
          ),
        ),

        //  CSVとしてコピーボタン
        Padding(
          padding: const EdgeInsets.all(8),
          child: ElevatedButton(
            onPressed: _viewModel.onCopyAsCsvButtonClicked,
            child: Text(l10n.copyAsCsvButton),
          ),
        ),

        //  TSVとしてコピーボタン
        Padding(
          padding: const EdgeInsets.all(8),
          child: ElevatedButton(
            onPressed: _viewModel.onCopyAsTsvButtonClicked,
            child: Text(l10n.copyAsTsvButton),
          ),
        ),

        //  パターンテーブル
        Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: columns,
              rows: rows,
              dataRowMaxHeight: double.infinity,
            ),
          ),
        ),
      ],
    );
  }

  //  リポジトリページを開く。
  Future<void> _openRepositoryPage() async {
    logger.i('$_tag#リポジトリページ遷移');

    //  リポジトリのWebページを別タブで開かせる。
    final Uri uri = Uri.parse(requireAppLocalizations(context).repositoryUrl);
    const mode = LaunchMode.platformDefault;
    const windowName = '_blank';
    await launchUrl(uri, mode: mode, webOnlyWindowName: windowName);
  }

  //  ライセンスページを開く。
  Future<void> _toLicensePage() async {
    logger.i('$_tag#ライセンスページ遷移');

    //  標準のライセンスページを表示する。
    showLicensePage(context: context);
  }

  //  エラーメッセージダイアログを表示する。
  void _showErrorMessageDialog(InvalidResultErrorMessage errorMessage) {
    logger.i('$_tag#エラーメッセージダイアログ表示: $errorMessage');

    showDialog(
      context: context,
      builder: (context) {
        final l10n = requireAppLocalizations(context);
        final String message = switch (errorMessage) {
          InvalidResultErrorMessageExceptionOccurred() =>
            errorMessage.exceptionMessage,
          InvalidResultErrorMessageTopLevelSyntaxError() =>
            l10n.errorMessageDialogMessage1,
          InvalidResultErrorMessageMapValuesSyntaxError() =>
            l10n.errorMessageDialogMessage2,
        };

        return AlertDialog(
          title: Text(l10n.errorMessageDialogTitle),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.errorMessageDialogCloseButton),
            ),
          ],
        );
      },
    );
  }

  //  クリップボードメッセージを表示する。
  void _showClipboardMessage() {
    logger.i('$_tag#クリップボードメッセージ表示');

    //  SnackBarとして表示する。
    final String message = requireAppLocalizations(context).clipboardMessage;
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
