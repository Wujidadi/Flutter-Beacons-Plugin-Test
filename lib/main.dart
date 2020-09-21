import 'dart:async';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:beacons_plugin/beacons_plugin.dart';
import 'package:ansicolor/ansicolor.dart';
import 'package:beacons_plugin_test/data/beacon.dart';
import 'package:beacons_plugin_test/widgets/gestureable_app_bar.dart';

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

    var isRunning = true;

    final String myUuid = '0a4d8b73-7f74-4a83-b2ca-4fe84e870427';

    final Duration period = const Duration(seconds: 1);

    final StreamController<String> beaconEventsController = StreamController<String>.broadcast();

    /// 初始化
    @override
    void initState() {
        super.initState();
        initPlatformState();
    }

    /// 銷毀
    @override
    void dispose() {
        beaconEventsController.close();
        super.dispose();
    }

    /// Beacon 資料列表
    List<Beacon> beacons = List<Beacon>.empty(growable: true);

    /// Beacon MAC Address 列表，用於篩選
    List<String> beaconMacAddr = List<String>.empty(growable: true);

    /// Platform 訊息皆為非同步，故以非同步方法初始化
    Future<void> initPlatformState() async {

        /* 設定 dubug 訊息等級 */
        BeaconsPlugin.setDebugLevel(1);

        /* 開啟 App 時便開始掃描 */
        await BeaconsPlugin.startMonitoring;

        /* 掃描 beacon */
        BeaconsPlugin.listenToBeacons(beaconEventsController);

        await BeaconsPlugin.addRegion('BeaconType1', myUuid);
        // await BeaconsPlugin.addRegion('BeaconType2', '6a84c716-0f2a-1ce9-f210-6a63bd873dd9');

        beaconEventsController.stream.listen((data) {
            if (data.isNotEmpty) {
                /* 將字串型態的 device data 轉為物件 */
                String json = data.replaceAll(RegExp(r'^Received: '), '');
                Map<String, dynamic> map = jsonDecode(json);
                setState(() {
                    // if (map['uuid'].toLowerCase() == myUuid) {
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
                    // }
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

    /// Stream 化的 isRunning 旗標
    Stream<bool> isScanning() {
        return Stream.value(isRunning);
    }

    /// ListView 化的 Beacon 資料
    ListView beaconList(List<Beacon> beacon) {

        /* 依 minor 排序 beacon */
        beacon.sort((a, b) {
            return a.minor.compareTo(b.minor) * 1;
        });

        /* 返回 ListView */
        return ListView.builder(
            itemCount: beacon.length,
            itemBuilder: (context, index) {
                return Row(
                    children: <Widget>[
                        /* 左邊的藍牙圖示 */
                        Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                                Container(
                                    child: Icon(
                                        Icons.bluetooth,
                                        color: Colors.blue
                                    ),
                                    padding: EdgeInsets.all(12)
                                )
                            ]
                        ),

                        /* Beacon 資訊 */
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
                                                    /* 預設樣式 */
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey
                                                    ),
                                                    children: <TextSpan>[
                                                        /* Beacon MAC address */
                                                        TextSpan(
                                                            text: '${beacon[index].mac}',
                                                            style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.black
                                                            )
                                                        ),
                                                        TextSpan(text: '\n'),   // 換行

                                                        /* 區隔 MAC Address 與其他資訊的空行 */
                                                        TextSpan(
                                                            text: ' \n',
                                                            style: TextStyle(
                                                                height: 0.5
                                                            )
                                                        ),

                                                        /* Beacon UUID，單列一行 */
                                                        TextSpan(text: 'UUID: '),
                                                        TextSpan(
                                                            text: '${beacon[index].uuid}'.toUpperCase(),
                                                            style: TextStyle(
                                                                fontWeight: FontWeight.bold
                                                            )
                                                        ),
                                                        TextSpan(text: '\n'),   // 換行

                                                        /* Beacon Major */
                                                        TextSpan(
                                                            style: TextStyle(
                                                                color: Colors.amber[600]
                                                            ),
                                                            children: <TextSpan>[
                                                                TextSpan(text: 'Major: '),
                                                                TextSpan(
                                                                    text: '${beacon[index].major}',
                                                                    style: TextStyle(
                                                                        fontWeight: FontWeight.bold
                                                                    )
                                                                )
                                                            ]
                                                        ),
                                                        TextSpan(text: ',  '),  // 空格

                                                        /* Beacon Minor */
                                                        TextSpan(
                                                            style: TextStyle(
                                                                color: Colors.green[600]
                                                            ),
                                                            children: <TextSpan>[
                                                                TextSpan(text: 'Minor: '),
                                                                TextSpan(
                                                                    text: '${beacon[index].minor}',
                                                                    style: TextStyle(
                                                                        fontWeight: FontWeight.bold
                                                                    )
                                                                )
                                                            ]
                                                        ),
                                                        TextSpan(text: ',  '),  // 空格

                                                        /* Beacon RSSI */
                                                        TextSpan(
                                                            style: TextStyle(
                                                                color: Colors.red[600]
                                                            ),
                                                            children: <TextSpan>[
                                                                TextSpan(text: 'RSSI: '),
                                                                TextSpan(
                                                                    text: '${beacon[index].rssi}',
                                                                    style: TextStyle(
                                                                        fontWeight: FontWeight.bold
                                                                    )
                                                                )
                                                            ]
                                                        ),
                                                        TextSpan(text: ',  '),  // 空格

                                                        /* Beacon 距離 */
                                                        TextSpan(
                                                            style: TextStyle(
                                                                color: Colors.blue[700]
                                                            ),
                                                            children: <TextSpan>[
                                                                TextSpan(text: '距離: '),
                                                                TextSpan(
                                                                    text: '${beacon[index].distance}m',
                                                                    style: TextStyle(
                                                                        fontWeight: FontWeight.bold
                                                                    )
                                                                )
                                                            ]
                                                        ),
                                                        TextSpan(text: '\n'),   // 換行,

                                                        /* Beacon 資訊更新時間，單列一行 */
                                                        TextSpan(
                                                            style: TextStyle(
                                                                color: Colors.cyan
                                                            ),
                                                            children: <TextSpan>[
                                                                TextSpan(text: '時間: '),
                                                                TextSpan(
                                                                    text: '${beacon[index].time}',
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
            }
        );
    }

    /// 依 isRunning 的值決定 Scan 按鈕樣式及狀態的 StreamBuilder
    StreamBuilder<bool> scanningButton(Stream<bool> status) {
        return StreamBuilder<bool>(
            stream: status,
            initialData: false,
            builder: (c, snapshot) {
                if (snapshot.data) {
                    return FloatingActionButton(
                        child: Icon(Icons.stop),
                        backgroundColor: Colors.red,
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
                        backgroundColor: Colors.blue,
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
        );
    }

    /// 基於 ansicolor 套件，在 console 中印出金色字體訊息
    String goldMsg(String msg) {
        AnsiPen pen = AnsiPen()..rgb(r: 1.0, g: 0.843, b: 0);
        return pen(msg);
    }

    /// 基於 ansicolor 套件，在 console 中印出青綠色字體訊息
    String greenMsg(String msg) {
        AnsiPen pen = AnsiPen()..rgb(r: 0, g: 1, b: 0);
        return pen(msg);
    }

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: WillPopScope(
                onWillPop: () async => false,
                child: Scaffold(
                    appBar: GestureableAppBar(
                        appBar: AppBar(
                            title: Text('Beacon 列表 (${beacons.length})'),
                            centerTitle: true,
                        ),
                        onTap: () {
                            print(greenMsg('isRunning = $isRunning'));
                        }
                    ),
                    body: Center(
                        child: beaconList(beacons)
                    ),
                    floatingActionButton: scanningButton(isScanning())
                )
            )
        );
    }
}