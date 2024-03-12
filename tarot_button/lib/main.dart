// main.dart
import 'dart:io';
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

  void _onMeowPressed() async {
    try {
      // Ensure the controller is initialized
      await _initializeControllerFuture;

      // Take the picture
      if (_controller != null) {
        print('_onMeowPressed: Taking a picture...');
        final XFile image = await _controller!.takePicture();
        print('_onMeowPressed: Picture taken: ${image.path}');

        // Save the image in the app's directory
        final Directory extDir = await getApplicationDocumentsDirectory();
        final String dirPath = '${extDir.path}/pictures/';
        await Directory(dirPath).create(recursive: true);
        final String filePath =
            join(dirPath, '${DateTime.now().millisecondsSinceEpoch}.png');

        // Copy the file to a new path
        final File newImage = await File(image.path).copy(filePath);
        print('_onMeowPressed: Image saved at: $filePath');

        // Prepare for uploading the image
        var request = http.MultipartRequest(
            'POST', Uri.parse('https://aibutton.tech/taro'));
        request.files
            .add(await http.MultipartFile.fromPath('picture', newImage.path));

        // Send the request
        var response = await request.send();

        // Simulate the response content
        // if (response.statusCode == 200) {    // original code
        if (true) {
          // Parse the response
          String responseBody = await response.stream.bytesToString();

          // Simulate the response content
          // responseBody = "Hello, world";
          responseBody = "\nHello, $name! \n\n"
              "The image shows the Nine of Pentacles from a tarot deck, which is often associated with abundance, self-sufficiency, and financial stability. The card depicts a figure standing in a garden of grapevines, symbolizing the fruits of one's labor and the rewards of diligence and hard work. The nine pentacles arranged in a lush environment suggest a time of personal achievement and material gain.\n\n"
              "As a fortune teller interpreting this card for your luck in 2024, it would bode well for prosperity and comfort. The card indicates that through continued effort and maintaining a clear vision of your goals, you will likely find yourself in a position of both financial and personal fulfillment.\n"
              "Regarding the question about receiving an offer from Stevenson school this month, the Nine of Pentacles is a positive omen, suggesting that the outcome you are hoping for is within reach. However, remember that tarot readings are not definitive answers but rather reflections of potential outcomes based on current circumstances.\n"
              "Keep putting forth your best efforts, and stay optimistic about the opportunities ahead.\n\n"
              "这张图片显示了塔罗牌上的星币九，它通常与丰富、自给自足和财务稳定联系在一起。这张牌描绘了一个站在葡萄藤花园里的人物，象征着一个人的劳动成果以及勤奋和努力的回报。努力工作。郁郁葱葱的环境中排列的九个星币暗示着个人成就和物质收获的时期。\n\n"
              "作为一名算命师，这张牌为你解读2024年的好运，这将是繁荣和舒适的好兆头。这张牌表明，通过持续努力和保持对目标的清晰愿景，你可能会发现自己处于财务和幸福的境地，和个人成就感。\n\n"
              "关于本月收到史蒂文森学校录取通知书的问题，星币九是一个积极的预兆，表明你所希望的结果是触手可及的。但是，请记住，塔罗牌占卜并不是确定的答案，而是潜力的反映。根据当前情况得出的结果。\n\n"
              "继续尽最大努力，并对未来的机会保持乐观。\n\n";

          String title = "$name: $question";
          String imagePath = newImage.path;
          String content = responseBody;
          // Navigate to DisplayPage with the response data
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => DisplayPage(
              title: title,
              imagePath: imagePath,
              content: content,
              bluetoothManager: bluetoothManager,
            ),
          ));
        } else {
          // Handle the failure of the upload
          print('Failed to upload picture.');
        }
      }
    } catch (e) {
      // Handle any exceptions
      print(e);
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
