import 'package:araidashisan/logger.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:yaml/yaml.dart';

part 'input.freezed.dart';

/// 入力一覧
@freezed
class InputList with _$InputList {
  const factory InputList({
    /// 入力一覧
    required List<Input> inputList,
  }) = _InputList;
}

/// 入力
@freezed
class Input with _$Input {
  const factory Input({
    required String name,
    required List<InputSelectionValue> values,
  }) = _Input;
}

/// 入力選択値
@freezed
class InputSelectionValue with _$InputSelectionValue {
  const factory InputSelectionValue({
    /// 入力選択値
    required String value,
  }) = _InputSelectionValue;
}

/// 入力パーサ
abstract final class InputParser {
  static const String _tag = 'InputParser';

  /// パースを行う。
  static InputParserResult parse(String text) {
    try {
      logger.d('$_tag#パース: $text');

      //  空入力の場合
      if (text.isEmpty) {
        logger.d('$_tag#パース 空: $text');
        return InputParserResult.empty(source: text);
      }

      //  入力をYAMLにパースする。
      final dynamic yaml = loadYaml(text);
      logger.d('$_tag#パース 型: ${yaml.runtimeType}');

      //  パース結果がYamlMap (連想配列) である場合
      if (yaml is YamlMap) {
        logger.d('$_tag#パース YamlMap型');
        final List<Input> inputList = List<Input>.empty(growable: true);

        //  各入力を見ていく。
        for (MapEntry entry in yaml.entries) {
          //  入力名とその入力選択値リストを取得する。
          final dynamic inputName = entry.key;
          final dynamic inputSelectionValues = entry.value;
          logger.d('$_tag#パース 入力名: ${inputName.runtimeType}, $inputName');
          logger.d(
            '$_tag#パース 入力選択値リスト: '
            '${inputSelectionValues.runtimeType}, $inputSelectionValues',
          );

          //  入力値が文字列、かつ、入力選択値リストがリストである場合
          if (inputName is String && inputSelectionValues is YamlList) {
            logger.d('$_tag#パース 入力名・入力選択値リスト 型有効');
            final List<InputSelectionValue> inputValueList =
                List<InputSelectionValue>.empty(growable: true);

            //  各入力選択値を見ていく。
            for (dynamic selectionValue in inputSelectionValues.value) {
              //  NOTE: double型やbool型の場合はエラーとする。
              //   小数の丸め誤差や表記揺れを避けるため、エスケープを促す方針とする。
              logger.d('$_tag#パース 入力選択値 型: ${selectionValue.runtimeType}');

              //  入力選択値が文字列である場合
              if (selectionValue is String) {
                logger.d('$_tag#パース 入力選択値 文字列型: $selectionValue');

                //  有効な入力選択値として保持する。
                final inputValue = InputSelectionValue(value: selectionValue);
                inputValueList.add(inputValue);
              }

              //  入力選択値が整数である場合
              else if (selectionValue is int) {
                logger.d('$_tag#パース 入力選択値 整数型: $selectionValue');

                //  有効な入力選択値として保持する。
                final inputValue =
                    InputSelectionValue(value: selectionValue.toString());
                inputValueList.add(inputValue);
              }

              //  入力選択値がそれ以外の型であるない場合
              else {
                logger.d('$_tag#パース 入力選択値 非文字列型: $selectionValue');

                //  NOTE: 連想配列の値部分が文字列 or 整数 (String型 or int型) ではない場合が該当する。
                //   発生例: 値部分でさらにネストした連想配列を記述した場合
                const errorMessage =
                    InvalidResultErrorMessage.mapValuesSyntaxError();
                return InputParserResultInvalid(
                  errorMessage: errorMessage,
                  source: text,
                );
              }
            }

            //  有効な入力として保持する。
            final input = Input(name: inputName, values: inputValueList);
            inputList.add(input);
          }

          //  入力値、あるいは、入力選択値リストの型が無効である場合
          else {
            logger.d('$_tag#パース 入力名・入力選択値リスト 型無効');

            //  NOTE: 値部分がリスト (YamlList型) ではない場合が該当する。
            //   発生例: 連想配列の値部分が単一要素である場合 (YamlList型ではなくString型)
            const errorMessage =
                InvalidResultErrorMessage.mapValuesSyntaxError();
            return InputParserResultInvalid(
              errorMessage: errorMessage,
              source: text,
            );
          }
        }

        //  すべての入力が有効である場合、パース成功結果を返す。
        return InputParserResultValid(
          inputList: InputList(inputList: inputList),
          source: text,
        );
      }

      //  パース結果がそれ以外である場合
      else {
        logger.d('$_tag#パース YamlMap型以外: ${yaml.runtimeType}');

        //  NOTE: 連想配列 (YamlMap型) ではなく、リスト (YamlList型) や無効入力 (Null型) や文字列 (String型) である場合が該当する。
        //   トップレベルの書き出し部分が間違っている (連想配列のキーの構文が無効等) ことが疑われる。
        const errorMessage = InvalidResultErrorMessage.topLevelSyntaxError();
        return InputParserResultInvalid(
          errorMessage: errorMessage,
          source: text,
        );
      }
    }

    //  例外が発生した場合
    catch (e, stack) {
      logger.d('$_tag#パース 例外', error: e, stackTrace: stack);

      //  YAMLパーサが例外をthrowした場合が該当する。
      //   例: 連想配列に重複したキーが存在する場合
      final errorMessage = InvalidResultErrorMessage.exceptionOccurred(
        exceptionMessage: e.toString(),
      );
      return InputParserResultInvalid(errorMessage: errorMessage, source: text);
    }
  }
}

/// 入力パーサの結果
@freezed
sealed class InputParserResult with _$InputParserResult {
  /// 有効
  const factory InputParserResult.valid({
    /// 入力リスト
    required InputList inputList,

    /// ユーザ入力
    required String source,
  }) = InputParserResultValid;

  /// 無効
  const factory InputParserResult.invalid({
    /// エラーメッセージ
    required InvalidResultErrorMessage errorMessage,

    /// ユーザ入力
    required String source,
  }) = InputParserResultInvalid;

  /// 空
  const factory InputParserResult.empty({
    /// ユーザ入力
    required String source,
  }) = InputParserResultEmpty;
}

/// 無効結果のエラーメッセージ
@freezed
sealed class InvalidResultErrorMessage with _$InvalidResultErrorMessage {
  /// 例外が発生した場合
  const factory InvalidResultErrorMessage.exceptionOccurred({
    /// 例外メッセージ
    required String exceptionMessage,
  }) = InvalidResultErrorMessageExceptionOccurred;

  /// トップレベルの連想配列構文で構文エラーが発生している場合
  const factory InvalidResultErrorMessage.topLevelSyntaxError() =
      InvalidResultErrorMessageTopLevelSyntaxError;

  /// 連想配列の各エントリの値部分において構文エラーが発生している場合
  const factory InvalidResultErrorMessage.mapValuesSyntaxError() =
      InvalidResultErrorMessageMapValuesSyntaxError;
}
