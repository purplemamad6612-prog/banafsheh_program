import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'widgets/app_shell.dart';

class BanafshehApp extends StatelessWidget {
  const BanafshehApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF776EE8), brightness: Brightness.light);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'بنفشه | مدیریت فروش و انبار',
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF6F8FC),
        fontFamily: 'Vazirmatn',
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Color(0xFF202B43), elevation: 0),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Color(0xFFEFF1F6))),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0xFFE8EBF2))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0xFFE8EBF2))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0xFF776EE8), width: 1.5)),
          labelStyle: const TextStyle(fontSize: 10, color: Color(0xFF778198)),
          hintStyle: const TextStyle(fontSize: 10, color: Color(0xFFADB4C1)),
        ),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF776EE8), foregroundColor: Colors.white, textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
        outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(textStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(textStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600))),
        dataTableTheme: const DataTableThemeData(headingRowColor: WidgetStatePropertyAll(Color(0xFFF7F8FB)), dividerThickness: .5, dataRowMinHeight: 38, dataRowMaxHeight: 52, headingTextStyle: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF56617A))),
      ),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox.shrink()),
      home: const BenafshehHomeShell(),
    );
  }
}
