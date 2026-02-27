import 'package:flutter/material.dart';
import 'package:cryptyo/views/encrypt_view.dart';
import 'package:cryptyo/views/decrypt_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

    @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cryptyo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('file Cryptyo'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.lock), text: "Encrypt"),
              Tab(icon: Icon(Icons.lock_open), text: "Decrypt"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            EncryptView(),
            DecryptView(),
          ],
        ),
      ),
    );
  }
}