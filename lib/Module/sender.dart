import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class Sender extends StatefulWidget {
  const Sender({super.key});

  @override
  State<Sender> createState() => _SenderState();
}

class _SenderState extends State<Sender> with WidgetsBindingObserver {
  String? _localIp;
  String? _fileName;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _selectAndSendFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final selectedFile = File(result.files.single.path!);
      _fileName = p.basename(selectedFile.path);

      final appDir = await getApplicationSupportDirectory();
      final shareDir = Directory('${appDir.path}/share_file');
      await shareDir.create(recursive: true);

      _filePath = '${shareDir.path}/$_fileName';
      await selectedFile.copy(_filePath!);

      final downloadUrl = await _uploadFileToServer();

      if (downloadUrl != null) {
        setState(() {
          _localIp = downloadUrl; // Store full download link in _localIp
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed. Please try again.")),
        );
      }
    }
  }

  Future<String?> _uploadFileToServer() async {
    if (_filePath == null) return null;

    final uri = Uri.parse('https://phone-drop.onrender.com/api/upload');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', _filePath!));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final downloadUrl = 'https://phone-drop.onrender.com/download';
        print("File uploaded. Download URL: $downloadUrl");
        return downloadUrl;
      } else {
        print("Upload failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _localIp;

    return Scaffold(
      appBar: AppBar(
        title: Text("Sender"),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_fileName == null) ...[
              ElevatedButton.icon(
                onPressed: _selectAndSendFile,
                icon: Icon(Icons.upload_file),
                label: Text("Select File to Send"),
              ),
            ] else ...[
              Text(
                "Selected File: $_fileName",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              if (url != null) QrImageView(data: url, size: 200),
              SizedBox(height: 20),
              Text("Scan this to download file:"),
              SelectableText(
                _localIp ?? 'Generating link...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _selectAndSendFile,
                icon: Icon(Icons.refresh),
                label: Text("Select Another File"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
