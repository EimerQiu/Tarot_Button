// main.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' show join;

import 'bluetooth_manager.dart';
import 'ai_tell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tarot Button',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(camera: camera),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final CameraDescription camera;

  const MyHomePage({Key? key, required this.camera}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = 0;
  BluetoothManager bluetoothManager = BluetoothManager();
  Color bluetoothIconColor = Colors.grey; // Initial color of the Bluetooth icon

  // Define the variables for name and question
  String name = 'Eimer';
  String question = 'Will i be accepted by Stanford in the future?';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  void _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isEmpty) {
      print('No cameras are available.');
      return;
    }
    _setCurrentCamera(_currentCameraIndex);
  }

  void _setCurrentCamera(int cameraIndex) async {
    if (_cameras == null || _cameras!.length <= cameraIndex) {
      print('Selected camera is not available.');
      return;
    }

    final camera = _cameras![cameraIndex];
    _controller = CameraController(camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller?.initialize();
    await _initializeControllerFuture;
    if (mounted) {
      setState(() {});
    }
  }

  void _switchCamera() {
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    _setCurrentCamera(_currentCameraIndex);
  }

  void _onMeowPressed() async {
    try {
      print('_onMeowPressed: Ensuring controller is initialized');
      // Ensure the controller is initialized
      await _initializeControllerFuture;
      print('_onMeowPressed: Controller initialized');

      // Take the picture
      if (_controller != null) {
        print('_onMeowPressed: Starting picture-taking process');
        final XFile image = await _controller!.takePicture();
        print('_onMeowPressed: Picture taken: ${image.path}');

        // Save the image in the app's directory
        final Directory extDir = await getApplicationDocumentsDirectory();
        final String dirPath = '${extDir.path}/pictures/';
        var directory = Directory(dirPath);
        if (await directory.exists()) {
          print('_onMeowPressed: Directory already exists');
        } else {
          print('_onMeowPressed: Creating directory');
          await directory.create(recursive: true);
          print('_onMeowPressed: Directory created');
        }
        final String filePath =
            join(dirPath, '${DateTime.now().millisecondsSinceEpoch}.png');

        // Copy the file to a new path
        print('_onMeowPressed: Copying file to new path');
        final File newImage = await File(image.path).copy(filePath);
        print('_onMeowPressed: Image saved at: $filePath');

        // Prepare for uploading the image and other data
        var request = http.MultipartRequest(
            'POST', Uri.parse('https://aibutton.tech/tarot'));
        print('_onMeowPressed: Preparing HTTP request');
        request.files
            .add(await http.MultipartFile.fromPath('image', newImage.path));
        request.fields['name'] = name;
        request.fields['question'] = question;

        // Send the request
        print('_onMeowPressed: Sending HTTP request');
        var response = await request.send();
        print(
            '_onMeowPressed: HTTP request sent, status code: ${response.statusCode}');

        // Simulate the response content
        if (response.statusCode == 200) {
          String responseBody = await response.stream.bytesToString();
          print('_onMeowPressed: Response received: $responseBody');

          // Parse the JSON response
          Map<String, dynamic> jsonResponse = jsonDecode(responseBody);

          // Extract the 'message' field
          String messageContent = jsonResponse['message'];

          String title = "$name: $question";
          String imagePath = newImage.path;

          // Use the extracted message for the content
          String content = "Hello, " + name + "!\n" + messageContent;

          print('_onMeowPressed: Navigating to DisplayPage');
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => DisplayPage(
              title: title,
              imagePath: imagePath,
              content: content,
              bluetoothManager: bluetoothManager,
            ),
          ));
        } else {
          print(
              'Failed to upload picture. Status code: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('_onMeowPressed: Exception caught: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tarot Button'),
      ),
      body: SingleChildScrollView(
        // Use SingleChildScrollView to avoid overflow
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 8),
            Text(
              '$name: $question',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // Ensure the camera is initialized
                  if (_controller == null ||
                      !_controller!.value.isInitialized) {
                    return Text('Camera is not initialized');
                  }
                  return Container(
                    width: 300,
                    height: 460,
                    child: CameraPreview(_controller!),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceEvenly, // Adjust the alignment as needed
              children: <Widget>[
                // Bluetooth icon aligned to the left
                IconButton(
                  icon: Icon(
                    Icons.bluetooth,
                    color: bluetoothIconColor,
                  ),
                  onPressed: () {
                    bluetoothManager.startScanAndConnect(() {
                      setState(() => bluetoothIconColor =
                          Colors.blue); // On successful connection
                    }, () {
                      setState(() =>
                          bluetoothIconColor = Colors.grey); // On disconnection
                    });
                  },
                ),
                // Meow button
                SizedBox(
                  width: 100, // Adjust the width as needed
                  height: 100, // Adjust the height to make the button round
                  child: FloatingActionButton(
                    onPressed: _onMeowPressed,
                    child: Text('Meow'),
                    shape: CircleBorder(), // Make the button round
                  ),
                ),
                // Smaller switch camera button
                SizedBox(
                  width: 30, // Smaller width
                  height: 30, // Smaller height
                  child: FloatingActionButton(
                    onPressed: _switchCamera,
                    child: Icon(Icons.switch_camera),
                    mini: true, // Makes the button smaller
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
