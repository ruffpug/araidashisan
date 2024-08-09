import 'dart:convert';

import 'package:araidashisan/input.dart';
import 'package:csv/csv.dart';
import 'package:flutter/widgets.dart';

/// パターンテーブル
@immutable
class PatternTable {
  const PatternTable._(this.inputList, this.rowList);

  /// 入力リスト
  final InputList inputList;

  /// ヘッダ一覧
  List<Input> get headers => inputList.inputList;

  /// パターンテーブル行の一覧
  final List<PatternTableRow> rowList;

  @override
  int get hashCode => inputList.hashCode;

  @override
  bool operator ==(Object other) {
    return other is PatternTable && inputList == other.inputList;
  }

  @override
  String toString() {
    return 'PatternTable(size=${rowList.length})';
  }
}

/// パターンテーブル行
class PatternTableRow {
  PatternTableRow._(this.index, this.values);

  /// インデックス
  /// (パターンテーブルの上から 0, 1, 2, ...)
  final int index;

  /// 値リスト
  /// (左から順に値が格納されている。)
  final List<InputSelectionValue> values;
}

/// パターンテーブルの変換ロジック
abstract final class PatternTableConverter {
  /// 入力リストをパターンテーブルに変換する。
  static PatternTable fromInputListToPatternTable(InputList inputList) {
    //  探索結果を格納する行リスト
    final List<PatternTableRow> resultRowList =
        List<PatternTableRow>.empty(growable: true);

    //  全パターンを探索する。
    //  (再帰呼び出しで探索していく。)
    void seek({
      int inputIndex = 0,
      List<InputSelectionValue> currentRowValues = const [],
    }) {
      //  現在着目している入力
      final Input input = inputList.inputList[inputIndex];

      //  現在着目している入力が右端 (末尾) の入力かどうか
      final bool isLastIndex = inputIndex == (inputList.inputList.length - 1);

      //  この入力の各選択値について洗い出していく。
      for (InputSelectionValue value in input.values) {
        //  右端の入力である場合
        if (isLastIndex) {
          final int rowIndex = resultRowList.length;
          final row = PatternTableRow._(rowIndex, [...currentRowValues, value]);
          resultRowList.add(row);
        }

        //  それ以外の入力である場合
        else {
          //  次の入力へ潜っていく。
          final int nextInputIndex = inputIndex + 1;
          seek(
            inputIndex: nextInputIndex,
            currentRowValues: [...currentRowValues, value],
          );
        }
      }
    }

    //  探索を行う。
    seek();

    return PatternTable._(inputList, resultRowList);
  }

  /// パターンテーブルをMarkdown文字列に変換する。
  static String fromPatternTableToMarkdownString(PatternTable patternTable) {
    const String brTag = '<br>';
    final buffer = StringBuffer();

    //  ヘッダを出力していく。
    for (int i = 0; i < patternTable.headers.length; i++) {
      //  左端である場合、始まりの「|」を加える。
      final bool isFirst = i == 0;
      if (isFirst) buffer.write('|');

      //  改行を加味して
      //  | ヘッダ名 |
      //  となるように出力する。
      final String headerName = patternTable.headers[i].name;
      buffer.write(' ');
      buffer.writeAll(LineSplitter.split(headerName), brTag);
      buffer.write(' |');
    }

    //  区切り部分を出力していく。
    buffer.writeln();
    for (int i = 0; i < patternTable.headers.length; i++) {
      //  左端である場合、始まりの「|」を加える。
      final bool isFirst = i == 0;
      if (isFirst) buffer.write('|');

      //  区切り要素を出力していく。
      buffer.write(':---|');
    }
    buffer.writeln();

    //  各行の値部分を出力していく。
    for (int rowIndex = 0; rowIndex < patternTable.rowList.length; rowIndex++) {
      //  この行の値を出力していく。
      final PatternTableRow row = patternTable.rowList[rowIndex];
      for (int valueIndex = 0; valueIndex < row.values.length; valueIndex++) {
        //  左端である場合、始まりの「|」を加える。
        final bool isFirst = valueIndex == 0;
        if (isFirst) buffer.write('|');

        //  改行を加味して
        //  | 値 |
        //  となるように出力する。
        final String value = row.values[valueIndex].value;
        buffer.write(' ');
        buffer.writeAll(LineSplitter.split(value), brTag);
        buffer.write(' |');
      }

      //  行の終わりに改行を出力する。
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// パターンテーブルをCSV文字列に変換する。
  static String fromPatternTableToCsvString(PatternTable patternTable) {
    //  出力用行リストに変換する。
    final List<List<String>> outputRows =
        _fromPatternTableToOutputRows(patternTable);

    //  CSV文字列に変換する。
    const csvConverter = ListToCsvConverter();
    final String csvString = csvConverter.convert(outputRows);
    return csvString;
  }

  /// パターンテーブルをTSV文字列に変換する。
  static String fromPatternTableToTsvString(PatternTable patternTable) {
    //  出力用行リストに変換する。
    final List<List<String>> outputRows =
        _fromPatternTableToOutputRows(patternTable);

    //  TSV文字列に変換する。
    const tsvConverter = ListToCsvConverter(fieldDelimiter: '	');
    final String tsvString = tsvConverter.convert(outputRows);
    return tsvString;
  }

  //  パターンテーブルをCSV/TSV出力用の出力行リストに変換する。
  static List<List<String>> _fromPatternTableToOutputRows(
    PatternTable patternTable,
  ) {
    final outputRows = List<List<String>>.empty(growable: true);

    //  ヘッダ行を追加する。
    final List<String> headerRow =
        patternTable.headers.map((Input header) => header.name).toList();
    outputRows.add(headerRow);

    //  各行を追加していく。
    for (final PatternTableRow row in patternTable.rowList) {
      final List<String> valuesRow =
          row.values.map((InputSelectionValue v) => v.value).toList();
      outputRows.add(valuesRow);
    }

    return outputRows;
  }
}
