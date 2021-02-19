import 'dart:convert';

import 'package:blocks_app/misc/local_constants.dart';
import 'package:blocks_app/pages/program_entry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orientation/orientation.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(MyApp1());
}

String html = "<!DOCTYPE html>" +
    "<html>" +
    "    <head>" +
    "        <meta charset=\"UTF-8\">" +
    "        <script>" +
    "            window.onload = function(){" +
    "                var aDiv = document.getElementsByTagName('div');" +
    "                 " +
    "                var str = \"\";" +
    "                for(var i = 0,j = 0;i<70;i++ ){" +
    "                    str += \"<div>test webview html \"+ i + \"</div>\";" +
    "                }" +
    "                document.body.innerHTML = str;" +
    "            }" +
    "        </script>" +
    "    </head>" +
    "    <body>" +
    "         " +
    "    </body>" +
    "</html>";


class MyApp1 extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('App'),),
        body: Container(
          child: WebView(
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<VerticalDragGestureRecognizer>(
                    () => VerticalDragGestureRecognizer(),
              ),
            },
            javascriptMode: JavascriptMode.unrestricted,
            initialUrl: Uri.dataFromString(html,
                mimeType: "text/html",
                encoding: Encoding.getByName("utf-8")
            ).toString(),
          ),
        ),
      ),
    );
  }
}



class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blocks App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final title;

  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]).then((_) {
      appInitialize(context);
      OrientationPlugin.forceOrientation(DeviceOrientation.landscapeRight);
    });
    ScreenUtil.init(context, designSize: Size(1334, 750));
    return Container(
        color: Colors.lightBlue,
        child: Center(
          child: ProgramEntry(),
        ));
  }
}
