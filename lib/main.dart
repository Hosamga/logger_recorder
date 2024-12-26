import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

final _rootLogger = Logger('root');

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Logging Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Logging Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    _startLogging();
    _startRecordingLogs();
    super.initState();
  }

  Future<void> _startLogging() async{
    final directory = await getApplicationDocumentsDirectory();
    final logsDirectory = Directory('${directory.path}/logs');
    if(logsDirectory.existsSync()){
      logsDirectory.deleteSync(recursive: true);
    }

    Timer.periodic(const Duration(seconds: 5), (_) {
      final currentTimestamp = DateTime.now();
      _rootLogger.info('Current timestamp is $currentTimestamp \n');
    });
  }

  void _startRecordingLogs() {
    Logger.root.onRecord.listen((log) async {
      final message = log.message;
      final level = log.level;

      final latestFile = await _getLatestFile();
      latestFile.writeAsStringSync('New message ($level): $message',
          mode: FileMode.append);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: FutureBuilder(
        future: _getFiles(),
        builder: (context, snapshot) {
          final list = snapshot.data;

          if (list != null) {
            if (list.isNotEmpty) {
              return Column(
                children: list
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child:

                        ListTile(
                          title: Text(f.path),
                          onTap: (){
                            OpenFile.open(f.path);
                          },
                        ),
                      ),
                    )
                    .toList(),
              );
            }

            return Center(child: Text('No logs yet.'));
          }
          return Center(
            child: const Text('Loading...'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {});
        },
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  final _maxFileSize = 500000000;
  Future<File> _getLatestFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final logsDirectory = Directory('${directory.path}/logs');

    if(logsDirectory.existsSync()){
    final files = logsDirectory.listSync()
        .whereType<File>()
        .toList();
    files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

    var latest = files.lastOrNull;
    if (latest != null && latest.lengthSync() < _maxFileSize) {
    return latest;
    }
    }

    final newDir = logsDirectory..create();
    return File('${newDir.path}/${DateTime.now().toUtc()}.txt')
      ..createSync(recursive: true);
  }

  Future<List<File>> _getFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final logsDirectory = Directory('${directory.path}/logs');
    if(logsDirectory.existsSync()){
      return   logsDirectory.listSync()
        .whereType<File>()
        .toList();

    }

    return [];
  }
}
