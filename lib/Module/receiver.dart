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
  Process? _flaskProcess;
  String? _localIp;
  int? _port;

  Duration _remaining = Duration(minutes: 10);
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startServerAndShowQr().then((_) {
      _startCountdownTimer(); // start the 10-min countdown timer here
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _killFlaskProcess();
    _countdownTimer?.cancel();
    super.dispose();
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

  Future<void> _startServerAndShowQr() async {
    _localIp = await _getLocalIp();
    _port = await _findFreePort(5000);

    if (_localIp == null || _port == null) {
      print("Could not determine IP or port.");
      return;
    }

    String pythonPath = 'python';
    String flaskScriptPath =
        'C:\\Coding\\phone_drop\\lib\\app.py'; // run as py installer

    try {
      _flaskProcess = await runProcess(pythonPath, [
        flaskScriptPath,
        _port.toString(),
      ]);
      print('Flask server started on $_localIp:$_port');
      setState(() {});
    } catch (e) {
      print('Failed to start Flask server: $e');
    }
  }

  Future<void> _refreshServer() async {
    print("🔄 Refreshing Flask server...");
    await _killFlaskProcess();
    await _startServerAndShowQr();
    _startCountdownTimer(); // restart timer
  }

  Future<void> _downloadFile() async {
    if (_localIp == null || _port == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Server not ready yet!')));
      return;
    }

    final url = 'http://$_localIp:$_port/download'; // Your Flask endpoint

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

  Future<void> _killFlaskProcess() async {
    if (_flaskProcess != null) {
      try {
        print("Killing Flask server process...");
        _flaskProcess!.kill(ProcessSignal.sigterm);
        final exitCode = await _flaskProcess!.exitCode.timeout(
          Duration(seconds: 5),
          onTimeout: () {
            print("Process didn't exit, forcing kill...");
            _flaskProcess!.kill(
              ProcessSignal.sigkill,
            ); // force kill if not exiting
            return -1;
          },
        );
        print("Flask server exited with code $exitCode");
      } catch (e) {
        print("Error killing Flask process: $e");
      } finally {
        _flaskProcess = null;
      }
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

  @override
  Widget build(BuildContext context) {
    final url = (_localIp != null && _port != null)
        ? 'http://$_localIp:$_port'
        : 'Starting server...';
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
                  Text('Scan with phone to download shared file:'),
                  SelectableText(
                    url,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _refreshServer();
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

Future<Process> runProcess(String executable, List<String> args) {
  return Process.start(executable, args);
}
