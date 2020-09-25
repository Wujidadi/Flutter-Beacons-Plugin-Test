import 'dart:async';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:beacons_plugin/beacons_plugin.dart';
import 'package:get_mac/get_mac.dart';
import 'package:beacons_plugin_test/helpers/references.dart';
import 'package:beacons_plugin_test/helpers/colorMsg.dart';
import 'package:beacons_plugin_test/helpers/beaconList.dart';
import 'package:beacons_plugin_test/data/beacon.dart';
import 'package:beacons_plugin_test/widgets/gestureable_app_bar.dart';

class MainPage extends StatefulWidget
{
    @override
    _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
{
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

    /// 藍牙掃描旗標
    bool isRunning = true;

    /// Beacon 監聽器
    final StreamController<String> beaconEventsController = StreamController<String>.broadcast();

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
            /* 監聽到的 beacon 資訊非空，亦即確實掃描到了藍牙 beacon */
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

        // if (Platform.isAndroid)
        // {
        //     BeaconsPlugin.channel.setMethodCallHandler((call) async
        //     {
        //         if (call.method == 'scannerReady')
        //         {
        //             await BeaconsPlugin.startMonitoring;
        //             setState(() {
        //                 isRunning = true;
        //             });
        //         }
        //     });
        // }
        // else if (Platform.isIOS)
        // {
        //     await BeaconsPlugin.startMonitoring;
        //     setState(() {
        //         isRunning = true;
        //     });
        // }

        if (!mounted) return;
    }

    /// Stream 化的 isRunning 旗標
    Stream<bool> isScanning()
    {
        return Stream.value(isRunning);
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

    /// 清空 beacons 時跳出警告訊息框
    void clearBeaconAlert(BuildContext context)
    {
        /// 取消按鈕
        Widget cancelButton = FlatButton(
            child: Text('取消'),
            onPressed: () {
                Navigator.pop(context);
            }
        );

        /// 確定按鈕
        Widget submitButton = FlatButton(
            child: Text('確定'),
            onPressed: () {
                setState(()
                {
                    beacons.clear();
                });
                Navigator.pop(context);
            }
        );

        /// 警告訊息框
        AlertDialog alert = AlertDialog(
            title: Text('清空 Beacon'),
            content: Text('確定清空 Beacon 列表？'),
            actions: <Widget>[
                cancelButton,
                submitButton
            ]
        );

        showDialog(
            context: context,
            builder: (BuildContext context) {
                return alert;
            }
        );
    }

    @override
    Widget build(BuildContext context)
    {
        return WillPopScope(
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
                                clearBeaconAlert(context);
                                // setState(()
                                // {
                                //     beacons.clear();
                                // });
                            }
                        )
                    ]
                ),

                body: Center(
                    child: beaconList(beacons)
                ),

                floatingActionButton: scanningButton(isScanning())
            )
        );
    }
}
