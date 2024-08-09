import 'package:flutter_test/flutter_test.dart';

void main() {
  group('テストグループ', () {
    test('テストケース', () {
      int calc(int x, int y) => x + y;

      //  ↓ わざとコケるようにしてみる。
      const int expected = 300;
      final int actual = calc(1, 2);

      expect(actual, equals(expected));
    });
  });
}
