// F2 Luật gộp khi đồng bộ – hàm thuần, không đụng Hive hay Firestore, nên dễ test và dễ giải thích.
//
// Luật "bản mới hơn thắng" (last-write-wins):
// - Mỗi bản ghi có updatedAtMs = thời điểm sửa cuối (millisecondsSinceEpoch, UTC).
// - So bản trên máy (local) với bản trên mây (remote) cùng id: updatedAtMs lớn hơn thì thắng.
// - Bằng nhau thì giữ bản local (không ghi gì, tránh ghi qua ghi lại vô ích).
// - Chỉ một bên có bản ghi thì bên đó thắng.
// - Xoá cũng là một bản ghi bình thường (deleted = true, có updatedAtMs riêng): xoá sau khi sửa
//   thì xoá thắng; sửa sau khi xoá (ví dụ tạo lại cùng id) thì bản sửa thắng.
import '../data/local_store.dart';

enum MergeWinner { local, remote }

/// Kết quả gộp toàn bộ một box lúc đăng nhập.
class MergePlan {
  const MergePlan({required this.toApply, required this.toPush});

  /// Bản trên mây mới hơn: ghi đè xuống máy.
  final Map<String, Map<String, dynamic>> toApply;

  /// Id các bản trên máy mới hơn (hoặc mây chưa có): đẩy lên mây.
  final Set<String> toPush;
}

class SyncMerge {
  SyncMerge._();

  /// Chọn bản thắng cho một id. Cả hai đều null không xảy ra (khi đó không có gì để gộp).
  static MergeWinner pick(Map<String, dynamic>? local, Map<String, dynamic>? remote) {
    if (remote == null) return MergeWinner.local;
    if (local == null) return MergeWinner.remote;
    return SyncFields.updatedAtOf(remote) > SyncFields.updatedAtOf(local)
        ? MergeWinner.remote
        : MergeWinner.local;
  }

  /// Gộp toàn bộ bản ghi của một box: bản nào phải ghi xuống máy, bản nào phải đẩy lên mây.
  static MergePlan plan(
    Map<String, Map<String, dynamic>> local,
    Map<String, Map<String, dynamic>> remote,
  ) {
    final toApply = <String, Map<String, dynamic>>{};
    final toPush = <String>{};
    for (final id in {...local.keys, ...remote.keys}) {
      final localRecord = local[id];
      final remoteRecord = remote[id];
      if (pick(localRecord, remoteRecord) == MergeWinner.remote) {
        toApply[id] = remoteRecord!;
      } else if (remoteRecord == null ||
          SyncFields.updatedAtOf(localRecord) > SyncFields.updatedAtOf(remoteRecord)) {
        // Bằng nhau thì không cần đẩy: hai bên đã giống nhau.
        toPush.add(id);
      }
    }
    return MergePlan(toApply: toApply, toPush: toPush);
  }
}
