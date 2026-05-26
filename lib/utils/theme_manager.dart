import 'package:flutter/foundation.dart';
import 'constants.dart';

/// Session-scoped chat theme manager.
///
/// The theme is stored in a [ValueNotifier] so any widget can listen to it.
/// The theme is reset to [ChatTheme.classicDark] whenever [reset] is called
/// (typically when the user leaves a chat room).
class ThemeManager {
  ThemeManager._();
  static final ThemeManager instance = ThemeManager._();

  final ValueNotifier<ChatTheme> current =
      ValueNotifier<ChatTheme>(ChatTheme.classicDark);

  ChatThemeData get data => kChatThemes[current.value]!;

  void setTheme(ChatTheme theme) {
    current.value = theme;
  }

  /// Call this when the user leaves a room to restore the default theme.
  void reset() {
    current.value = ChatTheme.classicDark;
  }
}
