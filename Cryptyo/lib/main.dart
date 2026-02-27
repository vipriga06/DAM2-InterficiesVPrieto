import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cryptyo/views/encrypt_view.dart';
import 'package:cryptyo/views/decrypt_view.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  bool get _useCupertino =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);

  @override
  Widget build(BuildContext context) {
    if (_useCupertino) {
      return const CupertinoApp(
        title: 'Cryptyo',
        home: MainScreen(),
        debugShowCheckedModeBanner: false,
      );
    }
    return MaterialApp(
      title: 'Cryptyo',
      theme: ThemeData(useMaterial3: true),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  bool get _useCupertino =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);

  @override
  Widget build(BuildContext context) {
    if (_useCupertino) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.lock), label: 'Encrypt'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.lock_open), label: 'Decrypt'),
        ]),
        tabBuilder: (ctx, i) {
          return CupertinoPageScaffold(child: i == 0 ? const EncryptView() : const DecryptView());
        },
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Cryptyo'), bottom: const TabBar(tabs: [
          Tab(icon: Icon(Icons.lock), text: 'Encrypt'),
          Tab(icon: Icon(Icons.lock_open), text: 'Decrypt'),
        ])),
        body: const TabBarView(children: [EncryptView(), DecryptView()]),
      ),
    );
  }
}