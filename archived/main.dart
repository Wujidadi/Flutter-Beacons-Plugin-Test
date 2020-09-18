import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:beacons_plugin/beacons_plugin.dart';

void main() {
    runApp(MyApp());
}

class MyApp extends StatefulWidget {
    @override
    _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
    String _beaconResult = 'Not Scanned Yet.';
    int _nrMessagesReceived = 0;
    var isRunning = false;

    final StreamController<String> beaconEventsController = StreamController<String>.broadcast();

    @override
    void initState() {
        super.initState();
        initPlatformState();
    }

    @override
    void dispose() {
        beaconEventsController.close();
        super.dispose();
    }

    // Platform messages are asynchronous, so we initialize in an async method.
    Future<void> initPlatformState() async {
        BeaconsPlugin.listenToBeacons(beaconEventsController);

        // await BeaconsPlugin.addRegion('BeaconType1', '909c3cf9-fc5c-4841-b695-380958a51a5a');
        // await BeaconsPlugin.addRegion('BeaconType2', '6a84c716-0f2a-1ce9-f210-6a63bd873dd9');

        beaconEventsController.stream.listen((data) {
            if (data.isNotEmpty) {
                String json = data.replaceAll(RegExp(r'^Received: '), '');
                Map<String, dynamic> object = jsonDecode(json);
                setState(() {
                    _beaconResult = object['macAddress'];
                    _nrMessagesReceived++;
                });
                print(object);
                // print("Beacons DataReceived: " + data);
                // print(_nrMessagesReceived);
            }
        },
        onDone: () {},
        onError: (error) {
            print("Error: $error");
        });

        // Send 'true' to run in background
        await BeaconsPlugin.runInBackground(true);

        if (Platform.isAndroid) {
            BeaconsPlugin.channel.setMethodCallHandler((call) async {
                if (call.method == 'scannerReady') {
                    await BeaconsPlugin.startMonitoring;
                    setState(() {
                        isRunning = true;
                    });
                }
            });
        } else if (Platform.isIOS) {
            await BeaconsPlugin.startMonitoring;
            setState(() {
                isRunning = true;
            });
        }

        if (!mounted) return;
    }

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
                appBar: AppBar(
                    title: const Text('Beacon 列表'),
                ),
                body: Center(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                            Text('$_beaconResult'),
                            Padding(
                                padding: EdgeInsets.all(10.0),
                            ),
                            Text('$_nrMessagesReceived'),

                            /* 掃描中可見 */
                            Visibility(
                                visible: isRunning,
                                child: SizedBox(
                                    height: 20.0,
                                ),
                            ),
                            Visibility(
                                visible: isRunning,
                                child: RaisedButton(
                                    child: Text('Stop Scanning', style: TextStyle(fontSize: 20)),
                                    onPressed: () async {
                                        if (Platform.isAndroid) {
                                            await BeaconsPlugin.stopMonitoring;

                                            setState(() {
                                                isRunning = false;
                                            });
                                        }
                                    },
                                ),
                            ),

                            /* 未掃描或停止掃描時可見 */
                            Visibility(
                                visible: !isRunning,
                                child: SizedBox(
                                    height: 20.0,
                                ),
                            ),
                            Visibility(
                                visible: !isRunning,
                                child: RaisedButton(
                                    child: Text('Start Scanning', style: TextStyle(fontSize: 20)),
                                    onPressed: () async {
                                        initPlatformState();
                                        await BeaconsPlugin.startMonitoring;

                                        setState(() {
                                            isRunning = true;
                                        });
                                    },
                                ),
                            )
                        ],
                    ),
                ),
            ),
        );
    }
}