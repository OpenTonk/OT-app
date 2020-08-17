import 'package:flutter/material.dart';
import 'package:wifi_configuration/wifi_configuration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'dart:io';
import 'dart:convert';

FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();
var androidSettings = AndroidInitializationSettings('');
var iosSettings = IOSInitializationSettings();
var settings = InitializationSettings(androidSettings, iosSettings);

var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'OT-n-1', 'OT-app', 'OpenTank notifications',
    importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
var iOSPlatformChannelSpecifics = IOSNotificationDetails();
var platformChannelSpecifics = NotificationDetails(
    androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

void main() {
  notificationsPlugin.initialize(settings);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TonkConnect',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainPage(title: ''),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MainPage createState() => _MainPage();
}

class _MainPage extends State<MainPage> {
  String ssid = "OpenTank";
  String pass = "UltimateTonk";

  String host = "192.168.4.1";
  int port = 4200;

  bool isConnected = false;
  Socket socket;

  Offset right0point;
  Offset left0point;
  double usableHeight = 0.6;

  num rightSpeed;
  num leftSpeed;

  void _pointerDown(PointerEvent details) {
    print({"down", details.position});

    if (details.position.dx > MediaQuery.of(context).size.width / 2) {
      this.right0point = details.position;
    } else {
      this.left0point = details.position;
    }
  }

  void _pointerMove(PointerEvent details) {
    //print({"move", details.position});

    num speed;
    double h = MediaQuery.of(context).size.height;

    if (details.position.dx > MediaQuery.of(context).size.width / 2) {
      speed = (this.right0point.dy - details.position.dy) /
          ((usableHeight * h) / 2) *
          100;
      speed = speed.clamp(-99, 99).toInt();

      if (speed != this.rightSpeed) {
        right(speed);
      }
    } else {
      speed = (this.left0point.dy - details.position.dy) /
          ((usableHeight * h) / 2) *
          100;
      speed = speed.clamp(-99, 99).toInt();

      if (speed != this.leftSpeed) {
        left(speed);
      }
    }
  }

  void right(num speed) {
    this.rightSpeed = speed;
    String msg = "R";

    if (speed >= 0) {
      msg += "+";
    } else {
      msg += "-";
    }

    if (speed.toString().length < 2) {
      msg += "0" + speed.abs().toString();
    } else {
      msg += speed.abs().toString();
    }

    print(msg);

    if (this.isConnected) {
      this.socket.add(utf8.encode(msg));
    }
  }

  void left(num speed) {
    this.leftSpeed = speed;
    String msg = "L";

    if (speed >= 0) {
      msg += "+";
    } else {
      msg += "-";
    }

    if (speed.toString().length < 2) {
      msg += "0" + speed.abs().toString();
    } else {
      msg += speed.abs().toString();
    }

    print(msg);

    if (this.isConnected) {
      this.socket.add(utf8.encode(msg));
    }
  }

  void onConnectBtn() async {
    if (!this.isConnected) {
      WifiConnectionStatus connStatus = await WifiConfiguration.connectToWifi(
          this.ssid, this.pass, "com.example.ot_app");

      switch (connStatus) {
        case WifiConnectionStatus.connected:
          this.isConnected = true;
          break;

        case WifiConnectionStatus.alreadyConnected:
          this.isConnected = true;
          break;

        case WifiConnectionStatus.notConnected:
          this.isConnected = false;
          break;

        case WifiConnectionStatus.platformNotSupported:
          print("platformNotSupported");
          break;

        case WifiConnectionStatus.profileAlreadyInstalled:
          print("profileAlreadyInstalled");
          break;

        case WifiConnectionStatus.locationNotAllowed:
          print("locationNotAllowed");
          break;
      }

      if (this.isConnected) {
        this.socket = await Socket.connect(this.host, this.port);
        print('connected');
      } else {
        await notificationsPlugin.show(0, 'Failed to connect',
            'Failed to find your OpenTank hotspot', platformChannelSpecifics);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ConstrainedBox(
        constraints: new BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
            minHeight: MediaQuery.of(context).size.height),
        child: Listener(
          onPointerDown: _pointerDown,
          onPointerMove: _pointerMove,
          child: Container(
            color: Colors.blue,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onConnectBtn,
        tooltip: 'Connect',
        child: Icon(Icons.wifi),
      ),
    );
  }
}
