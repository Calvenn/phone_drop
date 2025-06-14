import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class Receiver extends StatefulWidget {
  const Receiver({super.key});

  @override
  State<Receiver> createState() => _ReceiverState();
}

class _ReceiverState extends State<Receiver> with WidgetsBindingObserver {
  String? _localIp;
  int? _port;

  Duration _remaining = Duration(minutes: 10);
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startServerAndShowQr();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _startServerAndShowQr() async {
    _port = 443; // HTTPS port
    _localIp = "phone-drop.onrender.com";

    setState(() {
      // Trigger rebuild to show QR
      print("QR Code URL: https://$_localIp"); // Debug
    });
  }

  Future<void> _downloadFile() async {
    if (_localIp == null || _port == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Server not ready yet!')));
      return;
    }

    final url = 'https://phone-drop.onrender.com/download';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Downloading file...')));

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        Directory? dir;
        if (Platform.isWindows) {
          dir = await getDownloadsDirectory();
        } else {
          dir = await getApplicationDocumentsDirectory();
        }

        if (dir == null) {
          dir = await getApplicationDocumentsDirectory();
        }

        String filename = 'downloaded_file';
        final contentDisposition = response.headers['content-disposition'];
        if (contentDisposition != null) {
          final regex = RegExp(r'filename="?(.+)"?');
          final match = regex.firstMatch(contentDisposition);
          if (match != null) {
            filename = match.group(1)!;
          }
        }

        final file = File('${dir.path}/$filename');

        await file.writeAsBytes(response.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File downloaded: ${file.path}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to download file. Status code: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error during download: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = 'https://phone-drop.onrender.com';
    return Scaffold(
      appBar: AppBar(
        title: Text('Receive File'),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Center(
        child: _localIp == null
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Share this QR code with your phone:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  QrImageView(data: url, size: 200),
                  SizedBox(height: 20),
                  Text('Scan with phone to download shared file:'),
                  SelectableText(
                    url,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      //await _refreshServer();
                    },
                    icon: Icon(Icons.refresh),
                    label: Text("Refresh QR"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _downloadFile,
                    icon: Icon(Icons.download),
                    label: Text("Download File"),
                  ),
                ],
              ),
      ),
    );
  }
}
