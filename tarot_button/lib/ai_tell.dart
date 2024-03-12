// ai_tell.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'bluetooth_manager.dart'; 
class DisplayPage extends StatelessWidget {
  final String title;
  final String imagePath;
  final String content;
  final BluetoothManager bluetoothManager; 

  const DisplayPage({
    Key? key,
    required this.title,
    required this.imagePath,
    required this.content,
    required this.bluetoothManager, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Response')),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Image.file(File(imagePath)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(content),
            ),
            ElevatedButton(
              onPressed: () async {
                // Call printContent of BluetoothManager
                bluetoothManager.printContent(
                  title: title,
                  // imagePath: imagePath, //有bug，先不传图片
                  content: content,
                );
              },
              child: Text('Print'),
            ),
          ],
        ),
      ),
    );
  }
}
