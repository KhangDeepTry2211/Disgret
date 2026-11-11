// 1.1 Unit test nội dung quiz và cách tính điểm.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/motivation_quiz.dart';

void main() {
  const money = MotivationType.money;
  const family = MotivationType.family;
  const career = MotivationType.career;
  const prove = MotivationType.proveYourself;
  const freedom = MotivationType.freedom;

  group('Nội dung quiz', () {
    test('Có đúng 4 câu hỏi', () {
      expect(motivationQuestions, hasLength(4));
    });

    test('Câu nào cũng có đủ 5 loại động lực, mỗi loại một đáp án', () {
      for (final question in motivationQuestions) {
        final types = question.answers.map((answer) => answer.type);
        expect(types, unorderedEquals(MotivationType.values), reason: question.text);
      }
    });

    test('Thứ tự đáp án thay đổi giữa các câu để không lộ quy luật', () {
      final orders = motivationQuestions
          .map((question) => question.answers.map((answer) => answer.type.name).join(','))
          .toSet();
      expect(orders, hasLength(motivationQuestions.length));
    });
  });

  group('Tính điểm', () {
    test('Lấy 2 loại có điểm cao nhất, xếp theo điểm', () {
      expect(topMotivationTypes([money, career, career, career]), [career, money]);
    });

    test('Hai loại mỗi loại 2 điểm', () {
      expect(topMotivationTypes([family, freedom, family, freedom]), [family, freedom]);
    });

    test('Bằng điểm thì ưu tiên loại được chọn sớm hơn', () {
      expect(topMotivationTypes([freedom, prove, money, career]), [freedom, prove]);
      expect(topMotivationTypes([career, freedom, freedom, career]), [career, freedom]);
    });

    test('Điểm cao hơn thắng dù được chọn sau', () {
      expect(topMotivationTypes([money, family, career, career]), [career, money]);
    });

    test('Cả 4 câu chọn cùng một loại thì chỉ có 1 loại', () {
      expect(topMotivationTypes([prove, prove, prove, prove]), [prove]);
    });
  });
}
