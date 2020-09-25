import 'package:flutter/material.dart';
import 'package:beacons_plugin_test/data/beacon.dart';

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
