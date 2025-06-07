import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Process? _flaskProcess;
  String? _localIp;
  int? _port;

  Duration _remaining = Duration(minutes: 10);
  Timer? _countdownTimer;

  @override
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startServerAndShowQr().then((_) {
      _watchUploadsFolder();
      _startCountdownTimer(); // start the 10-min countdown timer here
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _killFlaskProcess();
    super.dispose();
  }

  void _killFlaskProcess() async {
    if (_flaskProcess != null) {
      print("Killing Flask server process...");
      _flaskProcess!.kill();
      await _flaskProcess!.exitCode;
      _flaskProcess = null;
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel(); // cancel if already running
    _remaining = Duration(minutes: 10);
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds <= 0) {
        timer.cancel();
        // Optionally you can show a message or close the app here
        print("⏰ Time is up!");
        // You might want to kill the flask server here too if you want
        // _killFlaskProcess();
      } else {
        setState(() {
          _remaining = _remaining - Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _startServerAndShowQr() async {
    _localIp = await _getLocalIp();
    _port = await _findFreePort(5000);

    if (_localIp == null || _port == null) {
      print("❌ Could not determine IP or port.");
      return;
    }

    // Start Flask server subprocess
    // Adjust path to your python executable and server.py location
    String pythonPath = 'python'; // or full path to python executable
    String flaskScriptPath =
        'C:\\Coding\\phone_drop\\lib\\app.py'; // must be relative or absolute path

    try {
      _flaskProcess = await runProcess(pythonPath, [
        flaskScriptPath,
        _port.toString(),
      ]);
      print('✅ Flask server started on $_localIp:$_port');
      setState(() {});
    } catch (e) {
      print('❌ Failed to start Flask server: $e');
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
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  List<FileSystemEntity> _uploadedFiles = [];

  void _watchUploadsFolder() {
    final uploadsDir = Directory('uploads');
    uploadsDir.createSync(); // Ensure it exists

    Timer.periodic(Duration(seconds: 2), (timer) {
      final files = uploadsDir.listSync().whereType<File>().toList();
      if (files.length != _uploadedFiles.length) {
        setState(() {
          _uploadedFiles = files;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = (_localIp != null && _port != null)
        ? 'http://$_localIp:$_port'
        : 'Starting server...';

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Phone Drop')),
        body: Center(
          child: _localIp == null
              ? CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Server auto-shutdown in: ${_remaining.inMinutes.toString().padLeft(2, '0')}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),

                    QrImageView(data: url, size: 200),
                    SizedBox(height: 20),
                    Text('Scan with phone to upload a file:'),
                    SelectableText(
                      'Server: ' + url,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 30),
                    Text('📁 Uploaded Files:', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    ..._uploadedFiles.map((file) {
                      final filename = file.path
                          .split(Platform.pathSeparator)
                          .last;
                      return ListTile(
                        title: Text(filename),
                        trailing: IconButton(
                          icon: Icon(Icons.open_in_new),
                          onPressed: () {
                            // Opens the file using default app (Windows/Mac/Linux)
                            Process.run('start', [file.path], runInShell: true);
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
        ),
      ),
    );
  }
}

Future<Process> runProcess(String executable, List<String> args) {
  return Process.start(executable, args);
}
