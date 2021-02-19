import 'package:blocks_app/pages/program.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProgramEntry extends StatefulWidget {

  @override
  _ProgramEntryState createState() => _ProgramEntryState();
}

class _ProgramEntryState extends State<ProgramEntry> {
  @override
  Widget build(BuildContext context) {

    return Container(
      color: Color.fromRGBO(53, 62, 79, 1.0),
      child: Container(
          child: Stack(
        children: <Widget>[
          _programArea(),
        ],
      )),
    );
  }

  Widget _programArea() {
    return Positioned(
      left: ScreenUtil().setWidth(100.0),
      right: ScreenUtil().setWidth(60.0),
      top: ScreenUtil().setHeight(200.0),
      height: ScreenUtil().setHeight(300.0),
      child: Container(
          child: Row(
        children: <Widget>[
          _addBtn(),
        ],
      )),
    );
  }

  Widget _addBtn() {
    return GestureDetector(
      onTap: _addClick,
      child: Container(
        margin: EdgeInsets.only(right: 20),
        width: ScreenUtil().setHeight(300.0),
        height: ScreenUtil().setHeight(300.0),
        child: Icon(
          Icons.add,
          size: ScreenUtil().setHeight(200),
          color: Colors.grey,
        ),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ScreenUtil().setWidth(20.0)),
            color: Colors.white),
      ),
    );
  }
  void _addClick() async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ProgramPage(
      );
    }));
  }
}
