import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:beacons_plugin/beacons_plugin.dart';
import 'package:beacons_plugin_test/data/beacon.dart';

void main() {
    /* 視覺輔助排版工具 */
    debugPaintSizeEnabled = false;

    runApp(MyApp());
}

class MyApp extends StatefulWidget {
    @override
    _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
    var isRunning = false;

    final String myUuid = '0a4d8b73-7f74-4a83-b2ca-4fe84e870427';

    final Duration period = const Duration(seconds: 1);

    final StreamController<String> beaconEventsController = StreamController<String>.broadcast();

    /* Beacon 資料列表 */
    List<Beacon> beacons = List<Beacon>.empty(growable: true);

    /* Beacon MAC Address 列表，用於篩選 */
    List<String> beaconMacAddr = List<String>.empty(growable: true);

    /* 初始化 */
    @override
    void initState() {
        super.initState();
        initPlatformState();
    }

    /* 銷毀 */
    @override
    void dispose() {
        beaconEventsController.close();
        super.dispose();
    }

    /* Platform 訊息皆為非同步，故以非同步方法初始化 */
    Future<void> initPlatformState() async {
        BeaconsPlugin.listenToBeacons(beaconEventsController);

        // await BeaconsPlugin.addRegion('BeaconType1', '909c3cf9-fc5c-4841-b695-380958a51a5a');
        // await BeaconsPlugin.addRegion('BeaconType2', '6a84c716-0f2a-1ce9-f210-6a63bd873dd9');

        beaconEventsController.stream.listen((data) {
            if (data.isNotEmpty) {
                /* 將字串型態的 device data 轉為物件 */
                String json = data.replaceAll(RegExp(r'^Received: '), '');
                Map<String, dynamic> map = jsonDecode(json);
                setState(() {
                    if (map['uuid'].toLowerCase() == myUuid) {
                        if (!beaconMacAddr.contains(map['macAddress'])) {
                            Beacon beaconData = Beacon(
                                name: map['name'],
                                uuid: map['uuid'],
                                mac: map['macAddress'],
                                major: map['major'],
                                minor: map['minor'],
                                distance: map['distance'],
                                rssi: map['rssi'],
                                txPower: map['txPower'],
                                time: map['scanTime']
                            );
                            beacons.add(beaconData);
                            beaconMacAddr.add(map['macAddress']);
                            // print(beaconData.toJson());
                        } else {
                            beacons.removeWhere((item) => item.mac == map['macAddress']);
                            Beacon beaconData = Beacon(
                                name: map['name'],
                                uuid: map['uuid'],
                                mac: map['macAddress'],
                                major: map['major'],
                                minor: map['minor'],
                                distance: map['distance'],
                                rssi: map['rssi'],
                                txPower: map['txPower'],
                                time: map['scanTime']
                            );
                            beacons.add(beaconData);
                            beaconMacAddr.add(map['macAddress']);
                            // print(beaconData.toJson());
                        }
                    }
                });
            }
        },
        onDone: () {},
        onError: (error) {
            print("Error: $error");
        });

        /* 設為 true 以背景執行 */
        await BeaconsPlugin.runInBackground(true);

        /* 定時印出 Beacons 訊息 */
        // Timer.periodic(period, (timer) {
        //     if (isRunning) {
        //         beacons.forEach((b) {
        //             print(b.toJson());
        //         });
        //     } else {
        //         timer.cancel();
        //         timer = null;
        //     }
        // });

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

    Stream<bool> isScanning() {
        return Stream.value(isRunning);
    }

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
                appBar: AppBar(
                    title: Text('Beacon 列表 (${beacons.length})'),
                    centerTitle: true
                ),
                body: Center(
                    child: ListView.builder(
                        itemCount: beacons.length,
                        itemBuilder: (context, index) {
                            return Row(
                                children: <Widget>[
                                    Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                            Container(
                                                child: Icon(
                                                    Icons.bluetooth,
                                                    color: Colors.blue
                                                ),
                                                padding: EdgeInsets.all(10)
                                            )
                                        ]
                                    ),
                                    Column(
                                        children: <Widget>[
                                            Container(
                                                padding: EdgeInsets.only(
                                                    top: 10,
                                                    bottom: 10
                                                ),
                                                child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: <Widget>[
                                                        RichText(
                                                            text: TextSpan(
                                                                style: TextStyle(
                                                                    fontSize: 12,
                                                                    color: Colors.grey
                                                                ),
                                                                children: <TextSpan>[
                                                                    TextSpan(
                                                                        text: '${beacons[index].mac}',
                                                                        style: TextStyle(
                                                                            fontSize: 14,
                                                                            fontWeight: FontWeight.bold,
                                                                            color: Colors.black
                                                                        )
                                                                    ),
                                                                    TextSpan(text: '\n'),

                                                                    /* 區隔 MAC Address 與其他資訊的空行 */
                                                                    TextSpan(
                                                                        text: ' \n',
                                                                        style: TextStyle(
                                                                            height: 0.5
                                                                        )
                                                                    ),

                                                                    TextSpan(text: 'UUID: '),
                                                                    TextSpan(
                                                                        text: '${beacons[index].uuid}'.toUpperCase(),
                                                                        style: TextStyle(
                                                                            fontWeight: FontWeight.bold
                                                                        )
                                                                    ),
                                                                    TextSpan(text: '\n'),

                                                                    TextSpan(
                                                                        style: TextStyle(
                                                                            color: Colors.amber[600]
                                                                        ),
                                                                        children: <TextSpan>[
                                                                            TextSpan(text: 'Major: '),
                                                                            TextSpan(
                                                                                text: '${beacons[index].major}',
                                                                                style: TextStyle(
                                                                                    fontWeight: FontWeight.bold
                                                                                )
                                                                            )
                                                                        ]
                                                                    ),
                                                                    TextSpan(text: ',  '),

                                                                    TextSpan(
                                                                        style: TextStyle(
                                                                            color: Colors.green[600]
                                                                        ),
                                                                        children: <TextSpan>[
                                                                            TextSpan(text: 'Minor: '),
                                                                            TextSpan(
                                                                                text: '${beacons[index].minor}',
                                                                                style: TextStyle(
                                                                                    fontWeight: FontWeight.bold
                                                                                )
                                                                            )
                                                                        ]
                                                                    ),
                                                                    TextSpan(text: ',  '),

                                                                    TextSpan(
                                                                        style: TextStyle(
                                                                            color: Colors.red[600]
                                                                        ),
                                                                        children: <TextSpan>[
                                                                            TextSpan(text: 'RSSI: '),
                                                                            TextSpan(
                                                                                text: '${beacons[index].rssi}',
                                                                                style: TextStyle(
                                                                                    fontWeight: FontWeight.bold
                                                                                )
                                                                            )
                                                                        ]
                                                                    ),
                                                                    TextSpan(text: ',  '),

                                                                    TextSpan(
                                                                        style: TextStyle(
                                                                            color: Colors.blue[700]
                                                                        ),
                                                                        children: <TextSpan>[
                                                                            TextSpan(text: '距離: '),
                                                                            TextSpan(
                                                                                text: '${beacons[index].distance}m',
                                                                                style: TextStyle(
                                                                                    fontWeight: FontWeight.bold
                                                                                )
                                                                            )
                                                                        ]
                                                                    )
                                                                ]
                                                            )
                                                        )
                                                    ]
                                                )
                                            )
                                        ]
                                    )
                                ]
                            );
                            // return ListTile(
                            //     isThreeLine: true,
                            //     leading: Icon(
                            //         Icons.bluetooth,
                            //         color: Colors.blue
                            //     ),
                            //     title: Align(
                            //         alignment: Alignment(-1.3, 0),
                            //         child: Text(beacons[index].mac)
                            //     ),
                            //     subtitle: Align(
                            //         alignment: Alignment(-50, 0),
                            //         // child: Text(beacons[index].uuid)
                            //         child: RichText(
                            //             text: TextSpan(
                            //                 style: TextStyle(
                            //                     fontSize: 12,
                            //                     color: Colors.grey
                            //                 ),
                            //                 children: <TextSpan>[
                            //                     TextSpan(text: 'UUID: '),
                            //                     TextSpan(
                            //                         text: '${beacons[index].uuid}'.toUpperCase(),
                            //                         style: TextStyle(
                            //                             fontWeight: FontWeight.bold
                            //                         )
                            //                     ),
                            //                     TextSpan(text: '\n'),

                            //                     TextSpan(
                            //                         style: TextStyle(
                            //                             color: Colors.amber[600]
                            //                         ),
                            //                         children: <TextSpan>[
                            //                             TextSpan(text: 'Major: '),
                            //                             TextSpan(
                            //                                 text: '${beacons[index].major}',
                            //                                 style: TextStyle(
                            //                                     fontWeight: FontWeight.bold
                            //                                 )
                            //                             )
                            //                         ]
                            //                     ),
                            //                     TextSpan(text: ',  '),

                            //                     TextSpan(
                            //                         style: TextStyle(
                            //                             color: Colors.green[600]
                            //                         ),
                            //                         children: <TextSpan>[
                            //                             TextSpan(text: 'Minor: '),
                            //                             TextSpan(
                            //                                 text: '${beacons[index].minor}',
                            //                                 style: TextStyle(
                            //                                     fontWeight: FontWeight.bold
                            //                                 )
                            //                             )
                            //                         ]
                            //                     ),
                            //                     TextSpan(text: ',  '),

                            //                     TextSpan(
                            //                         style: TextStyle(
                            //                             color: Colors.red[600]
                            //                         ),
                            //                         children: <TextSpan>[
                            //                             TextSpan(text: 'RSSI: '),
                            //                             TextSpan(
                            //                                 text: '${beacons[index].rssi}',
                            //                                 style: TextStyle(
                            //                                     fontWeight: FontWeight.bold
                            //                                 )
                            //                             )
                            //                         ]
                            //                     ),
                            //                     TextSpan(text: ',  '),

                            //                     TextSpan(
                            //                         style: TextStyle(
                            //                             color: Colors.blue[700]
                            //                         ),
                            //                         children: <TextSpan>[
                            //                             TextSpan(text: '距離: '),
                            //                             TextSpan(
                            //                                 text: '${beacons[index].distance}m',
                            //                                 style: TextStyle(
                            //                                     fontWeight: FontWeight.bold
                            //                                 )
                            //                             )
                            //                         ]
                            //                     )
                            //                 ]
                            //             )
                            //         )
                            //     )
                            // );
                        }
                    )
                ),
                floatingActionButton: StreamBuilder<bool>(
                    stream: isScanning(),
                    initialData: false,
                    builder: (c, snapshot) {
                        if (snapshot.data) {
                            return FloatingActionButton(
                                child: Icon(Icons.stop),
                                onPressed: () async {
                                    if (Platform.isAndroid) {
                                        await BeaconsPlugin.stopMonitoring;
                                        setState(() {
                                            isRunning = false;
                                        });
                                    }
                                }
                            );
                        } else {
                            return FloatingActionButton(
                                child: Icon(Icons.search),
                                onPressed: () async {
                                    initPlatformState();
                                    await BeaconsPlugin.startMonitoring;
                                    setState(() {
                                        isRunning = true;
                                    });
                                }
                            );
                        }
                    }
                )
            )
        );
    }
}