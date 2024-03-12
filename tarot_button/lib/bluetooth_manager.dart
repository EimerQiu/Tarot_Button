// bluetooth_manager.dart
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/services.dart'; // For rootBundle
import 'dart:convert'; // For base64Encode
import 'package:image/image.dart' as img;

class BluetoothManager {
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;
  bool _isConnected = false;
  StreamSubscription?
      _scanSubscription; // Declare a variable for the subscription

  bool get isConnected => _isConnected;

  void startScanAndConnect(
      Function onConnected, Function onDisconnected) async {
    String opId =
        Random().nextInt(999999).toString(); // Unique operation identifier
    developer.log('[$opId] startScanAndConnect: Starting Bluetooth scan...');

    if (_isConnected) {
      await disconnectBluetooth(onDisconnected);
    } else {
      developer.log('startScanAndConnect:Starting Bluetooth scan...');
      bluetoothPrint.startScan(timeout: Duration(seconds: 4));

      _scanSubscription = bluetoothPrint.scanResults.listen((devices) async {
        for (BluetoothDevice device in devices) {
          developer.log(
              'startScanAndConnect:Found device: ${device.name} - ${device.address}');
          if (device.address == "DC:0D:30:64:97:38") {
            // Assuming this is your target device
            developer.log(
                'startScanAndConnect:Target device found. Attempting connection...');
            bool result = await bluetoothPrint.connect(device);
            if (result) {
              developer.log('Connected to Printer_9738_BLE successfully');
              _isConnected = true;
              onConnected();

              await _scanSubscription?.cancel();
              _scanSubscription =
                  null; // Reset the subscription to allow future scans

              // Then wait for 5 seconds before continuing
              await Future.delayed(Duration(seconds: 5), () async {
                developer.log('printInitMessage');
                await printInitMessage(); // Print initialization message upon successful connection
              });

              break; // Exit the loop since the target device has been found and processed
            } else {
              developer.log(
                  'Failed to connect to Printer_9738_BLE DC:0D:30:64:97:38');
            }
          }
        }
      });
    }
  }

  Future<void> disconnectBluetooth(Function onDisconnected) async {
    developer.log('Disconnecting from Bluetooth device...');
    await bluetoothPrint.disconnect();
    developer.log('Disconnected.');
    _isConnected = false;
    onDisconnected();
  }

  Future<void> printInitMessage() async {
    Map<String, dynamic> config = {}; // Your printer configuration (if needed)
    List<LineText> messageList = [
      LineText(
          type: LineText.TYPE_TEXT,
          content: '************ https://aibutton.tech ************',
          align: LineText.ALIGN_CENTER,
          linefeed: 1),
    ];

    // Log the data being sent for printing
    developer.log(
        'printInitMessage:Preparing to print message: ${messageList.map((m) => m.toJson()).toList()}');

    try {
      // Log the attempt to print
      developer.log('printInitMessage:Sending message to printer...');

      await bluetoothPrint
          .printReceipt(config, messageList) // Corrected this line
          .then((result) {
        // Log the successful print attempt
        developer.log('printInitMessage:Message printing result: $result');
      }).catchError((error) {
        // Log any errors encountered during the print attempt
        developer.log('printInitMessage:Error printing message: $error',
            level: 1000);
      });
    } catch (e) {
      // Catch any errors not handled by `catchError`
      developer.log('printInitMessage:Exception in printing message: $e',
          level: 1000);
    }
  }

  // This function should be adjusted to process the image according to your printer's specifications
  Future<Uint8List?> processImageForPrinting(Uint8List imageBytes) async {
    try {
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage != null &&
          originalImage.width > 0 &&
          originalImage.height > 0) {
        // Ensure new dimensions are positive
        int newWidth = 384; // Example width, adjust as necessary
        int newHeight =
            (originalImage.height * (newWidth / originalImage.width)).round();
        if (newWidth > 0 && newHeight > 0) {
          img.Image resizedImage =
              img.copyResize(originalImage, width: newWidth, height: newHeight);
          Uint8List processedImageBytes =
              Uint8List.fromList(img.encodePng(resizedImage));
          return processedImageBytes;
        }
      }
    } catch (e) {
      developer.log('Error processing image: $e', level: 1000);
    }
    return null;
  }

  void printContent({
    String title = "Default Title",
    String imagePath = "",
    String content = "",
  }) async {
    List<LineText> printList = [];
    Map<String, dynamic> config = {};

    developer.log(
        "printContent: Printing title: $title, imagePath: $imagePath, content length: ${content.length}");

    printList.add(LineText(
        type: LineText.TYPE_TEXT,
        content: title,
        align: LineText.ALIGN_CENTER,
        weight: 1,
        size: 2,
        linefeed: 1));

    if (imagePath.isNotEmpty) {
      try {
        File imageFile = File(imagePath);
        Uint8List imageBytes = await imageFile.readAsBytes();
        developer.log('Image loaded, size: ${imageBytes.length} bytes');

        Uint8List? processedImageBytes =
            await processImageForPrinting(imageBytes);
        if (processedImageBytes != null) {
          String base64Image = base64Encode(processedImageBytes);
          developer.log('Image processed and converted to Base64');

          printList
              .add(LineText(type: LineText.TYPE_IMAGE, content: base64Image));
        } else {
          developer.log('Image processing failed.', level: 1000);
        }
      } catch (e) {
        developer.log('Error processing image: $e', level: 1000);
      }
    }

    if (content.isNotEmpty) {
      developer.log('printContent: Printing content');
      printList.add(LineText(
          type: LineText.TYPE_TEXT,
          content: content,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
    }

    if (printList.isNotEmpty) {
      try {
        await bluetoothPrint.printReceipt(config, printList);
        developer.log('printContent: Printing successful');
      } catch (e) {
        developer.log('printContent: Error during printing: $e', level: 1000);
      }
    } else {
      developer.log('printContent: No content to print', level: 1000);
    }
  }
}
