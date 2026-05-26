import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/constants.dart';
import 'screens/home_screen.dart';
import 'services/room_manager.dart';

void main() {
  // Start the background timer that purges empty / expired rooms every minute.
  RoomManager.instance.startCleanupTimer();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AnonymousChatApp());
}

class AnonymousChatApp extends StatelessWidget {
  const AnonymousChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnnoChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        useMaterial3: true,
        splashFactory: NoSplash.splashFactory,
        primaryColor: AppColors.neonCyan,
        scaffoldBackgroundColor: AppColors.backgroundSpace,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        cardTheme: CardThemeData(
          color: AppColors.glassSurface,
          elevation: 0,
          shadowColor: AppColors.glassShadow,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.glassStroke),
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.neonCyan,
          secondary: AppColors.neonPurple,
          surface: AppColors.cardDark,
          background: AppColors.backgroundSpace,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.glassSurface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.glassStroke),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.neonCyan),
          ),
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.75)),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.neonCyan,
          selectionColor: AppColors.neonPurple,
          selectionHandleColor: AppColors.neonCyan,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
