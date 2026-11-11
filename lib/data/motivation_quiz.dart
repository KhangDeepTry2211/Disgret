// 1.1 Hồ sơ động lực – nội dung quiz và cách tính điểm.
// Câu nào cũng có đủ 5 loại động lực để loại nào cũng có cơ hội được điểm như nhau.
import 'models/motivation_type.dart';

class QuizAnswer {
  const QuizAnswer(this.text, this.type);

  final String text;

  /// Chọn đáp án này thì loại động lực này được cộng 1 điểm.
  final MotivationType type;
}

class QuizQuestion {
  const QuizQuestion(this.text, this.answers);

  final String text;
  final List<QuizAnswer> answers;
}

const List<QuizQuestion> motivationQuestions = [
  QuizQuestion('Điều gì khiến bạn muốn cố gắng nhất?', [
    QuizAnswer('Có thu nhập tốt, không phải lo chuyện tiền', MotivationType.money),
    QuizAnswer('Làm người thân tự hào và yên tâm', MotivationType.family),
    QuizAnswer('Có công việc mình thật sự muốn làm', MotivationType.career),
    QuizAnswer('Chứng minh rằng mình làm được', MotivationType.proveYourself),
    QuizAnswer('Được tự quyết định cuộc sống của mình', MotivationType.freedom),
  ]),
  QuizQuestion('Bạn hình dung mình 5 năm nữa thế nào?', [
    QuizAnswer('Làm việc ở đâu, lúc nào là do mình chọn', MotivationType.freedom),
    QuizAnswer('Đang ở đúng vị trí mình mơ ước', MotivationType.career),
    QuizAnswer('Lo được cho gia đình', MotivationType.family),
    QuizAnswer('Trở thành người mà trước đây ít ai tin', MotivationType.proveYourself),
    QuizAnswer('Tự chủ tài chính, có khoản tiết kiệm riêng', MotivationType.money),
  ]),
  QuizQuestion('Khi sắp bỏ cuộc, điều gì kéo bạn quay lại?', [
    QuizAnswer('Không muốn thua chính mình', MotivationType.proveYourself),
    QuizAnswer('Nghĩ tới mức sống mình muốn có', MotivationType.money),
    QuizAnswer('Không muốn cả đời làm theo ý người khác', MotivationType.freedom),
    QuizAnswer('Nhớ tới những người đang tin mình', MotivationType.family),
    QuizAnswer('Nghĩ tới nghề mình đang theo đuổi', MotivationType.career),
  ]),
  QuizQuestion('Học tốt hơn sẽ mang lại cho bạn điều gì?', [
    QuizAnswer('Một bước tiến trong sự nghiệp', MotivationType.career),
    QuizAnswer('Nhiều lựa chọn hơn cho tương lai', MotivationType.freedom),
    QuizAnswer('Cơ hội có mức lương cao hơn', MotivationType.money),
    QuizAnswer('Niềm tin rằng mình làm được', MotivationType.proveYourself),
    QuizAnswer('Bớt gánh nặng cho gia đình', MotivationType.family),
  ]),
];

/// Lấy 2 loại động lực điểm cao nhất từ các đáp án đã chọn.
/// Bằng điểm thì ưu tiên loại được chọn sớm hơn, vì câu đầu hỏi trực tiếp nhất.
List<MotivationType> topMotivationTypes(List<MotivationType> answers) {
  final scores = <MotivationType, int>{}; // Map của Dart giữ thứ tự thêm vào.
  for (final type in answers) {
    scores[type] = (scores[type] ?? 0) + 1;
  }

  final firstChosen = scores.keys.toList();
  final ranked = [...firstChosen]
    ..sort((a, b) {
      final byScore = scores[b]!.compareTo(scores[a]!);
      return byScore != 0 ? byScore : firstChosen.indexOf(a).compareTo(firstChosen.indexOf(b));
    });
  return ranked.take(2).toList();
}
