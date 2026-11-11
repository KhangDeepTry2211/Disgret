// 5.2 Logo DisGret. Khi nhóm có file gốc, chỉ cần thay file ảnh cùng tên.
import 'package:material_ui/material_ui.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 32, super.key});

  static const String assetPath = 'assets/branding/logo_tam.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(assetPath, width: size, height: size, semanticLabel: 'Logo DisGret');
  }
}
