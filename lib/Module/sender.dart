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
  Process? _flaskProcess;
  String? _localIp;
  int? _port;
  String? _fileName;
  String? _filePath;

  Duration _remaining = Duration(minutes: 10);
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _killFlaskProcess();
    _countdownTimer?.cancel();
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

      await _startServerAndShowQr();
      _startCountdownTimer();

      setState(() {}); // trigger rebuild
    }
  }

  Future<bool> _uploadFileToServer() async {
    if (_filePath == null || _localIp == null || _port == null) return false;

    final uri = Uri.parse('http://$_localIp:$_port/api/upload');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', _filePath!));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        print("File uploaded to Flask server.");
        return true;
      } else {
        print("Failed to upload file: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Exception uploading file: $e");
      return false;
    }
  }

  Future<void> _startServerAndShowQr() async {
    _localIp = await _getLocalIp();
    _port = await _findFreePort(5000);

    if (_localIp == null || _port == null || _fileName == null) {
      print("Missing IP, port, or file name.");
      return;
    }

    String pythonPath = 'python';
    String flaskScriptPath = 'C:\\Coding\\phone_drop\\lib\\app.py';

    try {
      _flaskProcess = await runProcess(pythonPath, [
        flaskScriptPath,
        _port.toString(),
      ]);
      print('Flask server started on $_localIp:$_port');

      // Wait a short time for server to start before upload
      await Future.delayed(Duration(seconds: 1));

      // Upload the selected file to Flask server
      bool success = await _uploadFileToServer();
      if (!success) {
        print("Upload to Flask failed.");
        await _killFlaskProcess();
        return;
      }
    } catch (e) {
      print('Failed to start Flask server: $e');
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _remaining = Duration(minutes: 10);
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds <= 0) {
        timer.cancel();
      } else {
        if (!mounted)
          return; // check if widget is still mounted before setState
        setState(() {
          _remaining = _remaining - Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _killFlaskProcess() async {
    if (_flaskProcess != null) {
      print("Killing Flask server...");
      _flaskProcess!.kill();
      await _flaskProcess!.exitCode;
      _flaskProcess = null;
    }
  }

  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Failed to get local IP: $e');
    }
    return null;
  }

  Future<int?> _findFreePort(int startPort) async {
    for (var port = startPort; port < startPort + 100; port++) {
      try {
        final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
        await server.close();
        return port;
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final url = (_localIp != null && _port != null && _fileName != null)
        ? 'http://$_localIp:$_port/download'
        : null;

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
                "Server auto-shutdown in: ${_remaining.inMinutes.toString().padLeft(2, '0')}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              QrImageView(data: url!, size: 200),
              SizedBox(height: 20),
              Text("Scan this to download file:"),
              SelectableText(
                url,
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

Future<Process> runProcess(String executable, List<String> args) {
  return Process.start(executable, args);
}
