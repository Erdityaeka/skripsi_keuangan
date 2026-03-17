import 'package:flutter/material.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Text('AI Screen'),
      ),
      body: Center(
        child: Text('This is the AI Screen'),
      ),
    );
  }
}