import 'package:flutter/material.dart';

abstract class AppColors {
  static const navy    = Color(0xFF131921);
  static const blue    = Color(0xFF0071A2);
  static const orange  = Color(0xFFFF9900);
  static const yellow  = Color(0xFFFFD814);
  static const bg      = Color(0xFFF0F2F2);
  static const green   = Color(0xFF007600);
  static const danger  = Color(0xFFCC0C39);
  static const ink     = Color(0xFF0F1111);
  static const muted   = Color(0xFF565959);
  static const line    = Color(0xFFDDDDDD);
  static const deal    = Color(0xFFC7511F);
  static const prime   = Color(0xFF00A8E1);
  static const card    = Colors.white;
}

const kR4  = Radius.circular(4);
const kR8  = Radius.circular(8);
const kR12 = Radius.circular(12);
const kR99 = Radius.circular(99);

ThemeData buildAppTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue),
  scaffoldBackgroundColor: AppColors.bg,
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.navy,
    elevation: 0,
    centerTitle: false,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.yellow,
      foregroundColor: AppColors.ink,
      elevation: 0,
      minimumSize: const Size(88, 44),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(kR8)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(88, 44),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(kR8)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(kR8),
        borderSide: const BorderSide(color: AppColors.line)),
    enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(kR8),
        borderSide: const BorderSide(color: AppColors.line)),
    focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(kR8),
        borderSide: const BorderSide(color: AppColors.orange, width: 2)),
    errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(kR8),
        borderSide: const BorderSide(color: AppColors.danger)),
    labelStyle: const TextStyle(color: AppColors.muted),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(kR8),
        side: BorderSide(color: AppColors.line.withOpacity(0.5))),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.ink,
    contentTextStyle: const TextStyle(color: Colors.white),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(kR8)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor:           AppColors.orange,
    unselectedLabelColor: AppColors.muted,
    indicatorColor:       AppColors.orange,
    indicatorSize:        TabBarIndicatorSize.tab,
    dividerColor:         AppColors.line,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor:     Colors.white,
    selectedItemColor:   AppColors.orange,
    unselectedItemColor: AppColors.muted,
    selectedLabelStyle:  TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    unselectedLabelStyle: TextStyle(fontSize: 11),
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.orange : null),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.orange,
  ),
);
