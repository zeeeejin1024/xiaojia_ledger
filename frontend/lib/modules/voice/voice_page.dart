import 'package:flutter/material.dart';

class VoicePage extends StatelessWidget {
  const VoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('语音记账')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎙️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            const Text('长按说话，自动记账',
                style: TextStyle(fontSize: 16, color: Color(0xFFAAA098))),
            const SizedBox(height: 8),
            const Text('例如："午餐吃黄焖鸡花了22元"',
                style: TextStyle(fontSize: 13, color: Color(0xFFD4C5B9))),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('语音识别功能需要接入讯飞SDK')),
                );
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4794A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
