import 'dart:io';

import 'package:blocks_app/misc/local_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ProgramPage extends StatefulWidget {

  @override
  _ProgramPageState createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  bool isLoading = true;
  String debugLog = "debug log";

  String text = '';
  String originName = '';


  @override
  void initState() {
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/programbackground.png"),
          fit: BoxFit.fill,
        ),
      ),
      child: Container(
          child: Stack(
        children: <Widget>[
          _positionedWebviewController(),
          _returnBtn(),
        ],
      )),
    );
  }

  //返回按钮
  Widget _returnBtn() {
    return Positioned(
        left: ScreenUtil().setWidth(80.0),
        top: ScreenUtil().setHeight(60.0),
        width: ScreenUtil().setWidth(76.0),
        height: ScreenUtil().setHeight(81),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/return_btn.png'),
            ),
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop(originName);
            },
          ),
        ));
  }

  Widget _positionedWebviewController() {
    return Positioned(
        left: 0.0,
        right: 0.0,
        top: 0.0,
        bottom: 0.0,
        child: _webviewController());
  }

  Widget _webviewController() {
    String name = "index";
    String fiepath = getHtmlUrl(name);
    print('name:${name} \n filepath${fiepath}');
    fiepath = '${fiepath}.html';
    return Stack(
      children: [
        WebView(
          // initialUrl: fiepath,
          initialUrl: "http://blocklysmart.free.idcfengye.com/jimu02_0.html",
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) async {
            setState(() {
              debugLog = debugLog+"\n onWebViewCreated";
            });
          },
          javascriptChannels: <JavascriptChannel>[
            _toasterJavascriptChannel(context),
          ].toSet(),
          navigationDelegate: (NavigationRequest request) {
            print('allowing navigation to $request');
            setState(() {
              isLoading = true;
              debugLog = debugLog+"\n allowing navigation to $request";
            });
            return NavigationDecision.navigate;
          },

          onPageFinished: (String url) {
            print('Page finished loading: $url');
            setState(() {
              isLoading = false;
              debugLog = debugLog+"\n Page finished loading: $url";
            });
          },
          onWebResourceError: (WebResourceError error) {
            print(error.description);
            setState(() {
              isLoading = false;
              debugLog = debugLog+"\n error code:${error.errorCode},\n error type:${error.errorType}\n error domain:${error.domain} \n error failingUrl:${error.failingUrl} \n error description:${error.description}";
            });
          },
        ),
        isLoading
            ? Container(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : Container(),
      ],
    );
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
        });
  }
}
