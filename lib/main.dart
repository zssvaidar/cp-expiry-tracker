import 'package:flutter/material.dart';

void main() {
  runApp(const ExpiryTrackerApp());
}

/// Root widget of the CP Expiry Tracker application.
class ExpiryTrackerApp extends StatelessWidget {
  const ExpiryTrackerApp({super.key});

  static const String title = 'CP Expiry Tracker';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

/// Landing screen. Shows an empty state until item tracking is implemented.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String emptyMessage = 'No items tracked yet';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        title: const Text(ExpiryTrackerApp.title),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(emptyMessage, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
