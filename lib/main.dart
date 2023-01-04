import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:highlight/languages/dart.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:path_provider_linux/path_provider_linux.dart' as pathProviderLinux;
import 'package:path_provider_windows/path_provider_windows.dart' as pathProvderWindows;
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late CodeController _codeController;
  late TabController _tabController;
  List<String> files = [];
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: "",
      language: dart,
    );
    _textController = TextEditingController(text: "");
    _tabController = TabController(length: files.length, vsync: this);
    _listOfFiles();
  }

  Future<String?> _getDirectory() async {
    String? _path = "";
    try {
      if (Platform.isIOS) {
        _path = (await path.getApplicationDocumentsDirectory()).path;
      } else if (Platform.isMacOS) {
        _path = (await path.getDownloadsDirectory())?.path;
      } else if (Platform.isWindows) {
        pathProvderWindows.PathProviderWindows pathWindows =
        pathProvderWindows.PathProviderWindows();
        _path = await pathWindows.getDownloadsPath();
      } else if (Platform.isLinux) {
        pathProviderLinux.PathProviderLinux pathLinux =
        pathProviderLinux.PathProviderLinux();
        _path = await pathLinux.getDownloadsPath();
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print("Something wemt worng while getting directories");
        print(e);
      }
    }
    return _path;
  }

  Future<String?> _getStringFromFile(String fileName) async {
    try {
      final String? directory = await _getDirectory();
      final File file = File('$directory/$fileName');
      return file.readAsString(encoding: utf8);
    } on Exception catch (_) {
      if (kDebugMode) {
        print('never reached');
      }
    }
    return null;
  }

  void _listOfFiles() async {
    final String? directory = await _getDirectory();
    setState(() {
      files = io.Directory("$directory").listSync()
          .map((e) => e.path.split("/").last)
          .where((e) => e.contains(".txt")).toList();
      _tabController = TabController(length: files.length, vsync: this);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return Container();
    }
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              color: Colors.green,
              child: Row(
                children: [
                  const SizedBox(width: 8,),
                  ElevatedButton(onPressed: () {
                    Get.dialog(
                      AlertDialog(
                        title: const Text('Tạo file mới'),
                        content: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Tên file',
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: const Text("Close"),
                            onPressed: () => Get.back(),
                          ),
                          TextButton(
                            child: const Text("Save"),
                            onPressed: () async {
                              String? appDocPath = await _getDirectory();
                              File file = File('$appDocPath/${_textController.value.text}.txt');
                              await file.create();
                              _listOfFiles();
                              Get.back();
                            },
                          ),
                        ],
                      ),
                    );
                  }, child: const Icon(Icons.add)),
                  const SizedBox(width: 8,),
                  Expanded(
                    child: TabBar(
                    isScrollable: true,
                    controller: _tabController,
                    indicatorColor: Colors.green[800],
                    tabs: files.map((e) {
                      return Tab(text: e);
                    }).toList(),
                    onTap: (i) {
                      setState(() {

                      });
                    },
                  ),
                  )
                ],
              )
            )
          ),
      ),
      body: FutureBuilder(
        future: _getStringFromFile(files[_tabController.index]),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _codeController.text = snapshot.data ?? "";
            return CodeField(
              expands: true,
              lineNumberStyle: const LineNumberStyle(background: Colors.black54),
              lineNumbers: true,
              controller: _codeController,
              textStyle: const TextStyle(fontFamily: 'CascadiaCode'),
              onChanged: (val) async {
                final String? directory = await _getDirectory();
                final File file = File('$directory/${files[_tabController.index]}');
                await file.writeAsString(val, encoding: utf8);
              },
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
