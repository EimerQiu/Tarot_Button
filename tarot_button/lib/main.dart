import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

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

  // Define the variables for name and question
  String name = 'Baby';
  String question = 'Will my dreams come true?';

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

  void _onMeowPressed() {
    // Implement your functionality for the Meow button
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
      body: Column(
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
                if (_controller == null || !_controller!.value.isInitialized) {
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Meow button - larger and round
              SizedBox(
                width: 100, // Increase the width as needed
                height: 100, // Increase the height to make the button round
                child: FloatingActionButton(
                  onPressed: _onMeowPressed,
                  child: Text('Meow'),
                  shape: CircleBorder(), // Make the button round
                ),
              ),
              // Space between buttons
              SizedBox(width: 20),
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
    );
  }
}
