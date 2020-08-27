import 'dart:async';

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

  Timer loopTimer;
  bool t = true;

  @override
  void initState() {
    Timer.periodic(new Duration(milliseconds: 50), (timer) {
      this.loop();
      //print(this.udp);
    });
    super.initState();
  }

  void loop() {
    //print("update");
    if (this.isConnected) {
      //print(this.rightMsg());
      if (t) {
        this.udp.send(this.rightMsg().codeUnits, this.endpoint);
      } else {
        this.udp.send(this.leftMsg().codeUnits, this.endpoint);
      }

      t = !t;
    }
  }

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

      this.rightSpeed = speed;
    } else {
      speed = (this.left0point.dy - details.position.dy) /
          ((usableHeight * h) / 2) *
          100;
      speed = speed.clamp(-99, 99).toInt();

      this.leftSpeed = speed;
    }
  }

  String rightMsg() {
    String msg = "R";

    if (this.rightSpeed >= 0) {
      msg += "+";
    } else {
      msg += "-";
    }

    if (this.rightSpeed.toString().length < 2) {
      msg += "0" + this.rightSpeed.abs().toString();
    } else {
      msg += this.rightSpeed.abs().toString();
    }

    return msg;
  }

  String leftMsg() {
    String msg = "L";

    if (this.leftSpeed >= 0) {
      msg += "+";
    } else {
      msg += "-";
    }

    if (this.leftSpeed.toString().length < 2) {
      msg += "0" + this.leftSpeed.abs().toString();
    } else {
      msg += this.leftSpeed.abs().toString();
    }

    return msg;
  }

  void onConnectBtn() async {
    if (await WifiConfiguration.isConnectedToWifi(this.ssid)) {
      this.isConnected = true;
    } else {
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
