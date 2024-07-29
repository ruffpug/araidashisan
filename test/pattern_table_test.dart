import 'package:araidashisan/input.dart';
import 'package:araidashisan/pattern_table.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('パターンテーブルのテスト', () {
    test('パターンテーブルへの変換のテスト', () {
      //  各ケースをテストする。
      void test(
        Map<String, List<String>> inputList,
        List<List<String>> expected,
      ) {
        final PatternTable patternTable =
            PatternTableConverter.fromInputListToPatternTable(
          InputList(
            inputList: inputList.entries.map((e) {
              return Input(
                name: e.key,
                values: e.value.map((v) {
                  return InputSelectionValue(value: v);
                }).toList(),
              );
            }).toList(),
          ),
        );

        //  ヘッダ部分が予期した入力順に並んでいるはず。
        expect(
          patternTable.headers.map((h) => h.name),
          orderedEquals(inputList.keys),
        );

        //  各行が予期した出力結果となっているはず。
        expect(patternTable.rowList, hasLength(expected.length));
        for (int i = 0; i < expected.length; i++) {
          final List<String> expectedRow = expected[i];
          final PatternTableRow actualRow = patternTable.rowList[i];
          expect(
            actualRow.values.map((v) => v.value),
            orderedEquals(expectedRow),
          );
        }
      }

      //  ケース1: 1つの入力で1つの選択値を持つ場合
      test(
        {
          '入力A': ['値A1'],
        },
        [
          ['値A1'],
        ],
      );

      //  ケース2: 1つの入力で2つの選択値を持つ場合
      test(
        {
          '入力A': ['値A1', '値A2'],
        },
        [
          ['値A1'],
          ['値A2'],
        ],
      );

      //  ケース3: 2つの入力でそれぞれ[2つ, 1つ]の選択値を持つ場合
      test(
        {
          '入力A': ['値A1', '値A2'],
          '入力B': ['値B1'],
        },
        [
          ['値A1', '値B1'],
          ['値A2', '値B1'],
        ],
      );

      //  ケース4: 2つの入力でそれぞれ[1つ, 2つ]の選択値を持つ場合
      test(
        {
          '入力A': ['値A1'],
          '入力B': ['値B1', '値B2'],
        },
        [
          ['値A1', '値B1'],
          ['値A1', '値B2'],
        ],
      );

      //  ケース5: 2つの入力でそれぞれ[2つ, 2つ]の選択値を持つ場合
      test(
        {
          '入力A': ['値A1', '値A2'],
          '入力B': ['値B1', '値B2'],
        },
        [
          ['値A1', '値B1'],
          ['値A1', '値B2'],
          ['値A2', '値B1'],
          ['値A2', '値B2'],
        ],
      );

      //  ケース6: 3つの入力でそれぞれ[2つ, 2つ, 2つ]の選択値を持つ場合
      test(
        {
          '入力A': ['値A1', '値A2'],
          '入力B': ['値B1', '値B2'],
          '入力C': ['値C1', '値C2'],
        },
        [
          ['値A1', '値B1', '値C1'],
          ['値A1', '値B1', '値C2'],
          ['値A1', '値B2', '値C1'],
          ['値A1', '値B2', '値C2'],
          ['値A2', '値B1', '値C1'],
          ['値A2', '値B1', '値C2'],
          ['値A2', '値B2', '値C1'],
          ['値A2', '値B2', '値C2'],
        ],
      );

      //  ケース7: 2つの入力でそれぞれ[2つ, 3つ]の選択値を持つ場合
      test(
        {
          '入力A': ['値A1', '値A2'],
          '入力B': ['値B1', '値B2', '値B3'],
        },
        [
          ['値A1', '値B1'],
          ['値A1', '値B2'],
          ['値A1', '値B3'],
          ['値A2', '値B1'],
          ['値A2', '値B2'],
          ['値A2', '値B3'],
        ],
      );

      //  ケース8: 2つの入力でそれぞれ[3つ, 2つ]の選択値を持つ場合
      test(
        {
          '入力A': ['値A1', '値A2', '値A3'],
          '入力B': ['値B1', '値B2'],
        },
        [
          ['値A1', '値B1'],
          ['値A1', '値B2'],
          ['値A2', '値B1'],
          ['値A2', '値B2'],
          ['値A3', '値B1'],
          ['値A3', '値B2'],
        ],
      );

      //  ケース9: 2つの入力でそれぞれ[3つ, 3つ]の選択値を持つ場合
      test(
        {
          '入力A': ['値A1', '値A2', '値A3'],
          '入力B': ['値B1', '値B2', '値B3'],
        },
        [
          ['値A1', '値B1'],
          ['値A1', '値B2'],
          ['値A1', '値B3'],
          ['値A2', '値B1'],
          ['値A2', '値B2'],
          ['値A2', '値B3'],
          ['値A3', '値B1'],
          ['値A3', '値B2'],
          ['値A3', '値B3'],
        ],
      );

      //  ケース10: 3つの入力でそれぞれ[3つ, 3つ, 3つ]の選択値を持つ場合
      test(
        {
          '入力A': ['値A1', '値A2', '値A3'],
          '入力B': ['値B1', '値B2', '値B3'],
          '入力C': ['値C1', '値C2', '値C3'],
        },
        [
          ['値A1', '値B1', '値C1'],
          ['値A1', '値B1', '値C2'],
          ['値A1', '値B1', '値C3'],
          ['値A1', '値B2', '値C1'],
          ['値A1', '値B2', '値C2'],
          ['値A1', '値B2', '値C3'],
          ['値A1', '値B3', '値C1'],
          ['値A1', '値B3', '値C2'],
          ['値A1', '値B3', '値C3'],
          ['値A2', '値B1', '値C1'],
          ['値A2', '値B1', '値C2'],
          ['値A2', '値B1', '値C3'],
          ['値A2', '値B2', '値C1'],
          ['値A2', '値B2', '値C2'],
          ['値A2', '値B2', '値C3'],
          ['値A2', '値B3', '値C1'],
          ['値A2', '値B3', '値C2'],
          ['値A2', '値B3', '値C3'],
          ['値A3', '値B1', '値C1'],
          ['値A3', '値B1', '値C2'],
          ['値A3', '値B1', '値C3'],
          ['値A3', '値B2', '値C1'],
          ['値A3', '値B2', '値C2'],
          ['値A3', '値B2', '値C3'],
          ['値A3', '値B3', '値C1'],
          ['値A3', '値B3', '値C2'],
          ['値A3', '値B3', '値C3'],
        ],
      );
    });
  });
}
