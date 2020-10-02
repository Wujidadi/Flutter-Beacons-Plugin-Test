import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:beacons_plugin_test/pages/mainPage.dart';

void main()
{
    WidgetsFlutterBinding.ensureInitialized();

    /* 視覺輔助排版工具 */
    debugPaintSizeEnabled = false;

    /* 主程式進入點 */
    runApp(BeaconScannerApp());
}

class BeaconScannerApp extends StatefulWidget
{
    @override
    _BeaconScannerAppState createState() => _BeaconScannerAppState();
}

class _BeaconScannerAppState extends State<BeaconScannerApp>
{
    @override
    Widget build(BuildContext context)
    {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: MainPage()
        );
    }
}
