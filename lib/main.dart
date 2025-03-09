import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ContainerDetector(),
    );
  }
}

class ContainerDetector extends StatefulWidget {
  @override
  _ContainerDetectorState createState() => _ContainerDetectorState();
}

class _ContainerDetectorState extends State<ContainerDetector> {
  File? _image;
  List<int>? _processedImage;
  final picker = ImagePicker();
  String _containerCount = "";

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _processedImage = null;
        _containerCount = "";
      });
      _sendImageToAPI(_image!);
    }
  }

  Future<void> _sendImageToAPI(File imageFile) async {
    var uri = Uri.parse('http://0.0.0.0:8000/predict/');

    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await http.Response.fromStream(response);
      var jsonResponse = json.decode(responseData.body);

      var imageBase64 = jsonResponse['image'];
      setState(() {
        _processedImage = base64Decode(imageBase64);
        _containerCount = "Container detected: ${jsonResponse['count']}";
      });
      _showModal(context, _containerCount, _processedImage!);
    } else {
      print('Request failed: ${response.statusCode}');
    }
  }

  void _showModal(BuildContext context, String containerCount, List<int> processedImage) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  containerCount,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Image.memory(Uint8List.fromList(processedImage)),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Container Detector')),
      body: Center( 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null && _processedImage == null)
              Image.file(_image!),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
          ],
        ),
      ),
    );
  }
}
