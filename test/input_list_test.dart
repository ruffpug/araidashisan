import 'package:araidashisan/input.dart';
import 'package:flutter_test/flutter_test.dart';

const _exampleUserInput1 = '''
#入力例1

入力A:
- 値A1
''';

const _exampleUserInput2 = '''
#入力例2

入力A:
- 値A1
- 値A2
''';

const _exampleUserInput3 = '''
入力A:
- 値A1
- 値A2
- 値A3
''';

const _exampleUserInput4 = '''
入力A:
- 値A1
入力B:
- 値B1
''';

const _exampleUserInput5 = '''
入力A:
- 値A1
- 値A2
入力B:
- 値B1
''';

const _exampleUserInput6 = '''
入力A:
- 値A1
- 値A2
入力B:
- 値B1
- |-
  値B2
  改行あり
- 値B3
入力C:
- 値C
''';

const _exampleUserInput7 = '''
入力A:
- 0
- 1

入力B:
- ゼロ
- イチ

入力C:
- 零

入力D:
- 10
''';

const _exampleUserInput8 = '''
入力A:
- 0x00
- 0x01
- 0xFF
入力B:
- 010
- 0o10
''';

const _exampleUserInput9 = '''
# 入力名が重複しているケース
入力A:
- 値
入力A:
- 値
''';

const _exampleUserInput10 = '''
# 構文の文法がおかしいケース
[ }
''';

const _exampleUserInput11 = '''
# コロンがない場合
入力A
''';

const _exampleUserInput12 = '''
# 初手から配列の要素となっている場合
- 値A1
''';

const _exampleUserInput13 = '''
# コメントのみ
# コメントのみ
# コメントのみ
''';

const _exampleUserInput14 = '''
# 値がdouble型の場合
入力:
- 1.1
''';

const _exampleUserInput15 = '''
# 値がbool型の場合
入力:
- true
''';

const _exampleUserInput16 = '''
# 値がネストした連想配列の場合
入力:
- 値:
  - 値2
''';

const _exampleUserInput17 = '';

void main() {
  group('入力リストのテスト', () {
    test('パースに成功するケースのテスト', () {
      //  各ケースをテストする。
      void test(String userInput, Map<String, List<String>> expectedInputList) {
        //  パースに成功するはず。
        final InputParserResult parseResult = InputParser.parse(userInput);
        expect(parseResult, isA<InputParserResultValid>());

        //  パース結果の入力リストの入力数が予期したものであるはず。
        final InputList inputList =
            (parseResult as InputParserResultValid).inputList;
        expect(inputList.inputList, hasLength(expectedInputList.length));

        //  各入力を見ていく。
        for (int i = 0; i < expectedInputList.length; i++) {
          final Input actualInput = inputList.inputList[i];
          final MapEntry<String, List<String>> expectedInput =
              expectedInputList.entries.elementAt(i);

          //  入力名が予期したものであるはず。
          expect(actualInput.name, equals(expectedInput.key));

          //  入力選択値が予期したものと一致するはず。
          expect(
            actualInput.values.map((v) => v.value),
            orderedEquals(expectedInput.value),
          );
        }
      }

      //  ケース1: 1つ入力で1つの選択値を持つ場合
      test(
        _exampleUserInput1,
        {
          '入力A': ['値A1'],
        },
      );

      //  ケース2: 1つ入力で2つの選択値を持つ場合
      test(
        _exampleUserInput2,
        {
          '入力A': ['値A1', '値A2'],
        },
      );

      //  ケース3: 1つ入力で3つの選択値を持つ場合
      test(
        _exampleUserInput3,
        {
          '入力A': ['値A1', '値A2', '値A3'],
        },
      );

      //  ケース4: 2つ入力でそれぞれ[1つ, 1つ]の選択値を持つ場合
      test(
        _exampleUserInput4,
        {
          '入力A': ['値A1'],
          '入力B': ['値B1'],
        },
      );

      //  ケース5: 2つ入力でそれぞれ[2つ, 1つ]の選択値を持つ場合
      test(
        _exampleUserInput5,
        {
          '入力A': ['値A1', '値A2'],
          '入力B': ['値B1'],
        },
      );

      //  ケース6: 改行のある値が含まれている場合
      test(
        _exampleUserInput6,
        {
          '入力A': ['値A1', '値A2'],
          '入力B': ['値B1', '値B2\n改行あり', '値B3'],
          '入力C': ['値C'],
        },
      );

      //  ケース7: 整数が含まれている場合
      test(
        _exampleUserInput7,
        {
          '入力A': ['0', '1'],
          '入力B': ['ゼロ', 'イチ'],
          '入力C': ['零'],
          '入力D': ['10'],
        },
      );

      //  ケース8: 16進数・8進数の整数が含まれている場合
      test(
        _exampleUserInput8,
        {
          '入力A': ['0', '1', '255'],
          '入力B': ['10', '8'],
        },
      );
    });

    test('パース処理で例外が発生するケースのテスト', () {
      //  各ケースをテストする。
      void test(String userInput) {
        //  パースに失敗するはず。
        final InputParserResult parseResult = InputParser.parse(userInput);
        expect(parseResult, isA<InputParserResultInvalid>());

        //  例外発生によるエラーであるはず。
        final InvalidResultErrorMessage errorMessage =
            (parseResult as InputParserResultInvalid).errorMessage;
        expect(errorMessage, isA<InvalidResultErrorMessageExceptionOccurred>());
      }

      //  ケース9: 入力名 (連想配列のキー) が重複している場合
      test(_exampleUserInput9);

      //  ケース10: YAMLの文法がおかしい場合
      test(_exampleUserInput10);
    });

    test('パース処理でトップレベルの構文エラーが発生するケースのテスト', () {
      //  各ケースをテストする。
      void test(String userInput) {
        //  パースに失敗するはず。
        final InputParserResult parseResult = InputParser.parse(userInput);
        expect(parseResult, isA<InputParserResultInvalid>());

        //  トップレベルの構文エラーであるはず。
        final InvalidResultErrorMessage errorMessage =
            (parseResult as InputParserResultInvalid).errorMessage;
        expect(
          errorMessage,
          isA<InvalidResultErrorMessageTopLevelSyntaxError>(),
        );
      }

      //  ケース11: 入力名のコロンがなく、連想配列のキーとして認識されない場合
      test(_exampleUserInput11);

      //  ケース12: 初手から配列の要素が記述されている場合
      test(_exampleUserInput12);

      //  ケース13: コメントのみの文字列の場合
      test(_exampleUserInput13);
    });

    test('パース処理で連想配列の値部分の構文エラーが発生するケースのテスト', () {
      //  各ケースをテストする。
      void test(String userInput) {
        //  パースに失敗するはず。
        final InputParserResult parseResult = InputParser.parse(userInput);
        expect(parseResult, isA<InputParserResultInvalid>());

        //  連想配列の値部分の構文エラーであるはず。
        final InvalidResultErrorMessage errorMessage =
            (parseResult as InputParserResultInvalid).errorMessage;
        expect(
          errorMessage,
          isA<InvalidResultErrorMessageMapValuesSyntaxError>(),
        );
      }

      //  ケース14: 値がdouble型の場合
      test(_exampleUserInput14);

      //  ケース15: 値がbool型の場合
      test(_exampleUserInput15);

      //  ケース16: 値がネストした連想配列の場合
      test(_exampleUserInput16);
    });

    test('パース結果が空っぽであると判定されるケースのテスト', () {
      //  各ケースをテストする。
      void test(String userInput) {
        //  パース結果にて空っぽであると判定されるはず。
        final InputParserResult parseResult = InputParser.parse(userInput);
        expect(parseResult, isA<InputParserResultEmpty>());
      }

      //  ケース17: 空っぽの文字列の場合
      test(_exampleUserInput17);
    });
  });
}
