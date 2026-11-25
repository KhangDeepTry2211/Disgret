// 5.3 Màn chờ (spec 011): whether the Gret launch screen shows when DisGret opens.
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// On in the app; widget tests turn it off (`pumpApp`) so they start on the first screen.
final launchScreenProvider = Provider<bool>((ref) => true);
