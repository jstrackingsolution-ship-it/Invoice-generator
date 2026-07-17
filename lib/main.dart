import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/company_profile_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/receipt_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SjTrackingSolutionApp());
}

class SjTrackingSolutionApp extends StatelessWidget {
  const SjTrackingSolutionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seedColor = const Color(0xFF2F6FED);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProfileProvider()),
        ChangeNotifierProvider(create: (_) => ReceiptProvider()),
      ],
      child: MaterialApp(
        title: 'SJ TRACKING SOLUTION',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: seedColor,
            foregroundColor: Colors.white,
            centerTitle: false,
            elevation: 0,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F6FA),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
