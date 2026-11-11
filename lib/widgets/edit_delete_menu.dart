// 4.1 Đặt mục tiêu – menu ba chấm "Sửa / Xoá" của mục tiêu và thói quen.
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

enum _MenuAction { edit, delete }

class EditDeleteMenu extends StatelessWidget {
  const EditDeleteMenu({
    required this.tooltip,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final String tooltip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuAction>(
      icon: const Icon(AppIcons.more),
      tooltip: tooltip,
      onSelected: (action) => action == _MenuAction.edit ? onEdit() : onDelete(),
      itemBuilder: (context) => const [
        PopupMenuItem(value: _MenuAction.edit, child: Text('Sửa')),
        PopupMenuItem(value: _MenuAction.delete, child: Text('Xoá')),
      ],
    );
  }
}
