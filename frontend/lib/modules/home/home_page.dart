import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiaojia_ledger/core/constants.dart';
import 'package:xiaojia_ledger/core/router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小佳记账'),
      ),
      body: const Center(
        child: Text(
          '首页',
          style: TextStyle(fontSize: 24, color: Color(0xFFAAA098)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFD4794A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
