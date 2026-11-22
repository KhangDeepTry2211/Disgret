// F2 Kiểm thử đăng nhập và đồng bộ, KHÔNG gọi Firebase thật: luật gộp, kiểm tra tên đăng nhập,
// xoá mềm trong HiveRepository, migrate dữ liệu cũ, xoá toàn bộ khi đã đăng nhập.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/hive_boxes.dart';
import 'package:focus_app/data/local_store.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/blocked_apps_repository.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/providers/app_providers.dart';
import 'package:focus_app/services/auth_service.dart';
import 'package:focus_app/services/sync_merge.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import 'test_helpers.dart';

Map<String, dynamic> _record(int updatedAt, {bool deleted = false, String title = 'A'}) => {
  'id': 'g1',
  'title': title,
  'reason': 'R',
  SyncFields.updatedAt: updatedAt,
  SyncFields.deleted: deleted,
};

void main() {
  group('Luật gộp: bản mới hơn thắng', () {
    test('Local mới hơn thì giữ local', () {
      expect(SyncMerge.pick(_record(200), _record(100)), MergeWinner.local);
    });

    test('Remote mới hơn thì lấy remote', () {
      expect(SyncMerge.pick(_record(100), _record(200)), MergeWinner.remote);
    });

    test('Bằng nhau thì giữ local', () {
      expect(
        SyncMerge.pick(_record(100, title: 'máy'), _record(100, title: 'mây')),
        MergeWinner.local,
      );
    });

    test('Chỉ một bên có thì bên đó thắng', () {
      expect(SyncMerge.pick(null, _record(1)), MergeWinner.remote);
      expect(SyncMerge.pick(_record(1), null), MergeWinner.local);
    });

    test('Xoá mềm mới hơn thì xoá thắng', () {
      expect(SyncMerge.pick(_record(100), _record(200, deleted: true)), MergeWinner.remote);
      expect(SyncMerge.pick(_record(200, deleted: true), _record(100)), MergeWinner.local);
    });

    test('Sửa sau khi xoá thì bản sửa thắng (xoá cũ hơn thì thua)', () {
      expect(SyncMerge.pick(_record(300), _record(200, deleted: true)), MergeWinner.local);
      expect(SyncMerge.pick(_record(200, deleted: true), _record(300)), MergeWinner.remote);
    });

    test('Gộp cả box: phần nào ghi xuống máy, phần nào đẩy lên mây', () {
      final plan = SyncMerge.plan(
        {
          'chi_may': _record(1),
          'may_moi': _record(500),
          'may_cu': _record(100),
          'bang': _record(300),
        },
        {
          'chi_may_tren_may': _record(5),
          'may_moi': _record(400),
          'may_cu': _record(200, deleted: true),
          'bang': _record(300),
        },
      );
      expect(plan.toApply.keys.toSet(), {'chi_may_tren_may', 'may_cu'});
      expect(plan.toApply['may_cu']![SyncFields.deleted], isTrue);
      expect(plan.toPush, {'chi_may', 'may_moi'});
    });
  });

  group('Tên đăng nhập và mật khẩu', () {
    test('Chuẩn hoá: chữ thường, bỏ khoảng trắng', () {
      expect(AuthRules.normalizeUsername(' Khang Tran '), 'khangtran');
      expect(AuthRules.emailFor('Khang_2007'), 'khang_2007@disgret.app');
      expect(AuthRules.usernameFromEmail('khang_2007@disgret.app'), 'khang_2007');
    });

    test('Tên hợp lệ: 3–20 ký tự a–z, số, _ và .', () {
      expect(AuthRules.usernameError('khang'), isNull);
      expect(AuthRules.usernameError('K.H_2007'), isNull);
      expect(AuthRules.usernameError('ab'), isNotNull);
      expect(AuthRules.usernameError('a' * 21), isNotNull);
      expect(AuthRules.usernameError('khang@'), isNotNull);
      expect(AuthRules.usernameError('khăng'), isNotNull, reason: 'Không nhận chữ có dấu');
      expect(
        AuthRules.usernameError('a b'),
        isNotNull,
        reason: 'Bỏ khoảng trắng còn "ab", quá ngắn',
      );
      expect(AuthRules.usernameError('a b c'), isNull, reason: 'Bỏ khoảng trắng còn "abc", đủ 3');
    });

    test('Mật khẩu ít nhất 6 ký tự', () {
      expect(AuthRules.passwordError('12345'), isNotNull);
      expect(AuthRules.passwordError('123456'), isNull);
    });

    test('Lỗi Firebase đổi sang câu tiếng Việt', () {
      const wrong = 'Sai tên đăng nhập hoặc mật khẩu';
      expect(AuthRules.messageForCode('invalid-credential'), wrong);
      expect(AuthRules.messageForCode('wrong-password'), wrong);
      expect(AuthRules.messageForCode('user-not-found'), wrong);
      expect(AuthRules.messageForCode('email-already-in-use'), 'Tên đăng nhập đã có người dùng');
      expect(AuthRules.messageForCode('weak-password'), contains('yếu'));
      expect(AuthRules.messageForCode('network-request-failed'), contains('mạng'));
      expect(AuthRules.messageForCode('too-many-requests'), contains('quá nhiều'));
    });

    test('Firebase chưa sẵn sàng thì báo "Không kết nối được máy chủ"', () async {
      await expectLater(
        AuthService().signIn('khang', '123456'),
        throwsA(isA<AuthFailure>().having((f) => f.message, 'message', AuthRules.noServer)),
      );
      // Nhập sai thì báo lỗi nhập trước, chưa cần tới máy chủ.
      await expectLater(
        AuthService().signUp('k', '123456'),
        throwsA(isA<AuthFailure>().having((f) => f.message, 'message', contains('3–20'))),
      );
    });
  });

  group('Lưu trữ có đánh dấu đồng bộ', () {
    final clock = DateTime.utc(2026, 11, 22, 8);

    setUp(() async {
      await openMemoryBoxes();
      LocalStore.clock = () => clock;
    });

    tearDown(() async {
      LocalStore.clock = DateTime.now;
      await Hive.close();
    });

    test('save gán updatedAtMs, deleted = false, và báo thay đổi cho đồng bộ', () async {
      final changes = <LocalChange>[];
      final subscription = LocalStore.changes.listen(changes.add);
      addTearDown(subscription.cancel);

      await GoalRepository().save(const Goal(id: 'g1', title: 'A', reason: 'B'));
      await Future<void>.delayed(Duration.zero);

      final raw = GoalRepository().getAllRaw()['g1']!;
      expect(raw[SyncFields.updatedAt], clock.millisecondsSinceEpoch);
      expect(raw[SyncFields.deleted], isFalse);
      expect(changes, [(box: HiveBoxes.goals, id: 'g1')]);
    });

    test('delete là xoá mềm: getAll / getById không trả về, bản ghi vẫn trong box', () async {
      final goals = GoalRepository();
      await goals.save(const Goal(id: 'g1', title: 'A', reason: 'B'));
      await goals.save(const Goal(id: 'g2', title: 'C', reason: 'D'));
      LocalStore.clock = () => clock.add(const Duration(minutes: 1));

      await goals.delete('g1');

      expect(goals.getAll().map((goal) => goal.id), ['g2']);
      expect(goals.getById('g1'), isNull);
      final raw = goals.getAllRaw()['g1']!;
      expect(raw[SyncFields.deleted], isTrue);
      expect(
        raw[SyncFields.updatedAt],
        clock.add(const Duration(minutes: 1)).millisecondsSinceEpoch,
      );
      expect(Hive.box<dynamic>(HiveBoxes.goals).length, 2);
    });

    test('Lưu lại cùng id sau khi xoá thì sống lại', () async {
      final goals = GoalRepository();
      await goals.save(const Goal(id: 'g1', title: 'A', reason: 'B'));
      await goals.delete('g1');
      await goals.save(const Goal(id: 'g1', title: 'A2', reason: 'B'));
      expect(goals.getById('g1')?.title, 'A2');
    });

    test('applyRemote ghi xuống máy nhưng không báo thay đổi (không đẩy ngược lên)', () async {
      final changes = <LocalChange>[];
      final subscription = LocalStore.changes.listen(changes.add);
      addTearDown(subscription.cancel);

      await GoalRepository().applyRemote('g9', _record(123, title: 'Từ mây')..['id'] = 'g9');
      await Future<void>.delayed(Duration.zero);

      expect(GoalRepository().getById('g9')?.title, 'Từ mây');
      expect(GoalRepository().getAllRaw()['g9']![SyncFields.updatedAt], 123);
      expect(changes, isEmpty);
    });

    test('purgeAll xoá thật khỏi box', () async {
      await GoalRepository().save(const Goal(id: 'g1', title: 'A', reason: 'B'));
      await GoalRepository().purgeAll();
      expect(Hive.box<dynamic>(HiveBoxes.goals).isEmpty, isTrue);
    });

    test('Migrate: bản ghi cũ thiếu updatedAtMs / deleted được bổ sung', () async {
      await Hive.box<dynamic>(HiveBoxes.goals)
          .put('cu', {'id': 'cu', 'title': 'Mục tiêu cũ', 'reason': 'R'});
      await HiveBoxes.migrate();

      final raw = GoalRepository().getAllRaw()['cu']!;
      expect(raw[SyncFields.updatedAt], clock.millisecondsSinceEpoch);
      expect(raw[SyncFields.deleted], isFalse);
      expect(GoalRepository().getById('cu')?.title, 'Mục tiêu cũ');
    });

    test('Migrate: hồ sơ, app chặn, cờ onboarding ở khoá cũ được chuyển sang chỗ mới', () async {
      final profileBox = Hive.box<dynamic>(HiveBoxes.profile);
      await profileBox.put('user', {
        'motivationTypes': ['career'],
        'preferredReelLength': 30,
      });
      await profileBox.put('blocked_packages', ['com.android.chrome']);
      await profileBox.put('onboarding_done', true);
      await profileBox.put('celebrated_level', 3);

      await HiveBoxes.migrate();

      final profiles = ProfileRepository();
      expect(profiles.profile?.motivationTypes, [MotivationType.career]);
      expect(profiles.isOnboardingDone, isTrue);
      expect(profiles.celebratedLevel, 3);
      expect(BlockedAppsRepository().packages, {'com.android.chrome'});
      expect(profileBox.keys.toSet(), {
        ProfileRepository.profileId,
        BlockedAppsRepository.recordId,
      });
      expect(Hive.box<dynamic>(HiveBoxes.device).get('onboarding_done'), isTrue);
    });

    test('Xoá toàn bộ khi đã đăng nhập: đánh dấu xoá mềm để đồng bộ, không xoá thật', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await ProfileRepository().completeOnboarding(
        const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
      );
      await GoalRepository().save(const Goal(id: 'g1', title: 'A', reason: 'B'));

      await container.read(appDataActionsProvider).clearAll(syncDeletion: true);

      expect(GoalRepository().getAll(), isEmpty);
      expect(GoalRepository().getAllRaw()['g1']![SyncFields.deleted], isTrue);
      expect(ProfileRepository().profile, isNull);
      expect(ProfileRepository().isOnboardingDone, isFalse);
      expect(container.read(goalsProvider), isEmpty);
    });

    test('Xoá toàn bộ khi chưa đăng nhập: xoá thật như cũ', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await GoalRepository().save(const Goal(id: 'g1', title: 'A', reason: 'B'));

      await container.read(appDataActionsProvider).clearAll();

      expect(GoalRepository().getAllRaw(), isEmpty);
    });
  });

  group('Mục Tài khoản trong Cài đặt', () {
    setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
    setUp(openMemoryBoxes);
    tearDown(() async => Hive.close());

    testWidgets('Không có Firebase (như khi test) thì báo không kết nối, app vẫn chạy', (
      tester,
    ) async {
      await ProfileRepository().completeOnboarding(
        const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
      );
      await pumpApp(tester);
      await tapAndSettle(tester, find.byTooltip('Cài đặt'));

      expect(find.text('Tài khoản'), findsOneWidget);
      expect(find.textContaining(AuthRules.noServer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
