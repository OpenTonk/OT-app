import 'package:flutter/material.dart';
import 'package:wifi_configuration/wifi_configuration.dart';
import 'package:udp/udp.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'dart:io';
import 'dart:convert';

void main() {
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
  String ssid = "OpenTank-AP";
  String pass = "UltimateTonk";

  bool isConnected = false;
  UDP udp;
  Endpoint endpoint =
      Endpoint.multicast(InternetAddress("192.168.4.1"), port: Port(4200));

  Offset right0point;
  Offset left0point;
  double usableHeight = 0.4;

  num rightSpeed = 0;
  num leftSpeed = 0;

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

      right(speed);
    } else {
      speed = (this.left0point.dy - details.position.dy) /
          ((usableHeight * h) / 2) *
          100;
      speed = speed.clamp(-99, 99).toInt();

      left(speed);
    }
  }

  void right(num speed) {
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

    this.udp.send(msg.codeUnits, this.endpoint);
  }

  void left(num speed) {
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

    this.udp.send(msg.codeUnits, this.endpoint);
  }

  void onConnectBtn() async {
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
        Fluttertoast.showToast(msg: "Not allowed");
        break;
    }

    if (this.isConnected) {
      this.udp = await UDP.bind(Endpoint.any());
      print('connected');

      Fluttertoast.showToast(
          msg: "Connection established", backgroundColor: Colors.green);
    } else {
      print('not connected');
      Fluttertoast.showToast(
          msg: "Failed to connect", backgroundColor: Colors.red);
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
