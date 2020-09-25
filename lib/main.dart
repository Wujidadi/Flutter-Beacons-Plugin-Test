import 'dart:async';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:beacons_plugin/beacons_plugin.dart';
import 'package:ansicolor/ansicolor.dart';
import 'package:get_mac/get_mac.dart';
import 'package:beacons_plugin_test/data/beacon.dart';
import 'package:beacons_plugin_test/widgets/gestureable_app_bar.dart';

void main()
{
    /* 視覺輔助排版工具 */
    debugPaintSizeEnabled = false;

    runApp(MyApp());
}

class MyApp extends StatefulWidget
{
    @override
    _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>
{
    /// 藍牙掃描旗標
    var isRunning = true;

    /// 限定目標基站或 beacon 的 UUID
    final List<String> myUuid = <String>[
        '0a4d8b73-7f74-4a83-b2ca-4fe84e870427',    // STU
        '0a4d8b73-7f74-4a83-b2ca-4fe84e870426',    // TUT
        'b5b182c7-eab1-4988-aa99-b5c1517008d9'
    ];

    /// 執行定期動作的時間間隔
    final Duration period = const Duration(seconds: 1);

    /// Beacon 未回傳過期時限（微秒）
    final int beaconExpiredMus = 5 * 1000000;

    /// Beacon 監聽器
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
    Map<String, Beacon> beacons = Map();

    /// 手機的 MAC address
    String deviceMacAddr = 'Unknown';

    /// Platform 訊息皆為非同步，故以非同步方法初始化
    Future<void> initPlatformState() async
    {
        /* 獲取手機 MAC address */
        String _deviceMacAddre;
        try {
            _deviceMacAddre = await GetMac.macAddress;
        } on PlatformException {
            print(colorMsg(deviceMacAddr, r: 240, g: 208, b: 201));
        }
        setState(() {
            deviceMacAddr = _deviceMacAddre;
            print(colorMsg(deviceMacAddr, r: 140, g: 200, b: 50));
        });

        /* 設定 dubug 訊息等級 */
        BeaconsPlugin.setDebugLevel(1);

        /* 開啟 App 時便開始掃描 */
        await BeaconsPlugin.startMonitoring;

        /* 添加 beacon 區域 */
        for (int i = 0; i < myUuid.length; i++)
        {
            await BeaconsPlugin.addRegion("BeaconType${i + 1}", myUuid[i])
            /* .then((result) {
                print(colorMsg(result, r: 255, g: 171, b: 122));
            }) */;
        }

        /* 掃描 beacon */
        BeaconsPlugin.listenToBeacons(beaconEventsController);

        /* 掃描 beacon */
        beaconEventsController.stream.listen((data)
        {
            if (data.isNotEmpty)
            {
                /* 將字串型態的 device data 轉為物件 */
                Map<String, dynamic> map = jsonDecode(data);

                setState(()
                {
                    /* 只抓取 UUID 合乎限定的 beacon */
                    if (myUuid.contains(map['uuid'].toLowerCase()))
                    {
                        /* 新增 */
                        if (!beacons.containsKey(map['macAddress']))
                        {
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
                            beacons.putIfAbsent(map['macAddress'], () => beaconData);
                        }
                        /* 更新 */
                        else
                        {
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
                            beacons.update(map['macAddress'], (v) => beaconData);
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
        // Timer.periodic(period, (timer)
        // {
        //     if (isRunning)
        //     {
        //         beacons.forEach((b)
        //         {
        //             print(b.toJson());
        //         });
        //     }
        //     else
        //     {
        //         timer.cancel();
        //         timer = null;
        //     }
        // });

        /* 刪除最後一次掃描已超過一定時間的 beacon */
        Timer.periodic(period, (timer)
        {
            setState(()
            {
                List<String> beaconMacAddrToBeRemoved = <String>[];

                // print(colorMsg(beaconMacAddrToBeRemoved.length.toString(), r: 205, g: 127, b: 50));

                if (isRunning)
                {
                    beacons.forEach((mac, beacon)
                    {
                        DateTime now = DateTime.now();
                        DateTime when = DateTime.parse(beacon.time);
                        Duration diff = now.difference(when);
                        int diffMus = diff.inMicroseconds;
                        // print(colorMsg(diffMus.toString(), r: 205, g: 127, b: 50));
                        if (diffMus > beaconExpiredMus)
                        {
                            // print(colorMsg(mac, r: 205, g: 127, b: 50));
                            beaconMacAddrToBeRemoved.add(mac);
                        }
                    });

                    if (beaconMacAddrToBeRemoved.length > 0)
                    {
                        beacons.removeWhere((mac, beacon) => beaconMacAddrToBeRemoved.contains(mac));
                    }
                }
            });
        });

        if (Platform.isAndroid)
        {
            BeaconsPlugin.channel.setMethodCallHandler((call) async
            {
                if (call.method == 'scannerReady')
                {
                    await BeaconsPlugin.startMonitoring;
                    setState(() {
                        isRunning = true;
                    });
                }
            });
        }
        else if (Platform.isIOS)
        {
            await BeaconsPlugin.startMonitoring;
            setState(() {
                isRunning = true;
            });
        }

        if (!mounted) return;
    }

    /// Stream 化的 isRunning 旗標
    Stream<bool> isScanning()
    {
        return Stream.value(isRunning);
    }

    /// ListView 化的 Beacon 資料
    ListView beaconList(Map<String, Beacon> beacon)
    {
        /* 依 minor 排序 beacon */
        Map<String, Beacon> sortedBeacon = Map.fromEntries(beacon.entries.toList()..sort((a, b)
        {
            return int.parse(a.value.minor).compareTo(int.parse(b.value.minor)) * 1;
        }));

        /* 返回 ListView */
        return ListView.builder(
            itemCount: sortedBeacon.length,
            itemBuilder: (BuildContext context, int index)
            {
                String key = sortedBeacon.keys.elementAt(index);
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
                                                            text: '${sortedBeacon[key].mac}',
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
                                                            text: '${sortedBeacon[key].uuid}'.toUpperCase(),
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
                                                                    text: '${sortedBeacon[key].major}',
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
                                                                    text: '${sortedBeacon[key].minor}',
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
                                                                    text: '${sortedBeacon[key].rssi}',
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
                                                                    text: '${sortedBeacon[key].distance}m',
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
                                                                    text: '${sortedBeacon[key].time}',
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
    StreamBuilder<bool> scanningButton(Stream<bool> status)
    {
        return StreamBuilder<bool>(
            stream: status,
            initialData: false,
            builder: (c, snapshot)
            {
                if (snapshot.data)
                {
                    return FloatingActionButton(
                        child: Icon(Icons.stop),
                        backgroundColor: Colors.red,
                        onPressed: () async
                        {
                            // if (Platform.isAndroid)
                            // {
                                await BeaconsPlugin.stopMonitoring;
                                setState(()
                                {
                                    isRunning = false;
                                });
                            // }
                        }
                    );
                }
                else
                {
                    return FloatingActionButton(
                        child: Icon(Icons.search),
                        backgroundColor: Colors.blue,
                        onPressed: () async
                        {
                            initPlatformState();
                            await BeaconsPlugin.startMonitoring;
                            setState(()
                            {
                                isRunning = true;
                            });
                        }
                    );
                }
            }
        );
    }

    /// 基於 ansicolor 套件，在 console 中印出帶有單一色彩的訊息，顏色以 0 ~ 255 RGB 值分別指定（預設值為青綠色）
    String colorMsg(String msg, {int r = 0, int g = 255, int b = 0})
    {
        double red = r.toDouble() / 255;
        double green = g.toDouble() / 255;
        double blue = b.toDouble() / 255;

        AnsiPen pen = AnsiPen()..rgb(r: red, g: green, b: blue);

        return pen(msg);
    }

    @override
    Widget build(BuildContext context)
    {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: WillPopScope(
                onWillPop: () async => false,
                child: Scaffold
                (
                    /* 使用自建的 GestureableAppBar 以產生可響應事件的 AppBar */
                    // appBar: GestureableAppBar(
                    //     child: AppBar(
                    //         title: Text('Beacon 列表 (${beacons.length})'),
                    //         centerTitle: true
                    //     ),
                    //     onTap: ()
                    //     {
                    //         print(colorMsg('isRunning = $isRunning'));
                    //     }
                    // ),

                    appBar: AppBar
                    (
                        /* 使用 InkWell 使 AppBar 中的 title 文字部分能單獨響應事件 */
                        title: InkWell(
                            child: Text('Beacon 列表 (${beacons.length})'),
                            onTap: ()
                            {
                                print(colorMsg('isRunning = $isRunning'));
                            }
                        ),

                        /* 使用 FlatButton 使 AppBar 中的 title 文字部分能單獨響應事件 */
                        // title: FlatButton(
                        //     child: Text(
                        //         'Beacon 列表 (${beacons.length})',
                        //         style: TextStyle(
                        //             color: Colors.white,
                        //             fontSize: 20,
                        //             fontWeight: FontWeight.w500
                        //         )
                        //     ),
                        //     onPressed: ()
                        //     {
                        //         print(colorMsg('isRunning = $isRunning', r: 200, g: 255, b: 0));
                        //     }
                        // ),

                        /* 使 title 置中，iOS 毋需此行 */
                        centerTitle: true,

                        actions: <Widget>[
                            InkWell(
                                child: Container(
                                    child: Text('清空',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500
                                        )
                                    ),
                                    alignment: Alignment.center,
                                    width: 60
                                ),
                                onTap: ()
                                {
                                    beacons.clear();
                                }
                            )
                        ]
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
