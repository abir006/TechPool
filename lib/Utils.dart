import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


MaterialColor mainColor =  Colors.cyan;
Color secondColor = Color(0xff308ea1);
BorderRadius containerBorderRadius = BorderRadius.all(Radius.circular(8));

class UserRepository extends ChangeNotifier {
  final auth = FirebaseAuth.instance;
  User _user;

  set user(User value) {
    _user = value;
    notifyListeners();
  }

  User get user => _user;
}

class Drive{
  String info;
  Drive(this.info);

}

class Lift{
  String info;
  Lift(this.info);
}

class DesiredLift{
  String info;
  DesiredLift(this.info);
}

Container transformEvent(dynamic event){
  if (event is Drive) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 0.8),
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin:
      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(leading: Icon(Icons.directions_car,size: 30, color: mainColor,),
        title: Text(event?.info),
        onTap: () => print('$event tapped!'),
      ),
    );
  } else if (event is Lift) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 0.8),
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin:
      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(leading: Transform.rotate(angle: 0.8,child: Icon(Icons.thumb_up_rounded,size: 30, color: mainColor,)),
        title: Text(event?.info),
        onTap: () => print('$event tapped!'),
      ),
    );
  } else if (event is DesiredLift) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange, width: 0.8),
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin:
      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(leading: Transform.rotate(angle: 0.8,child: Icon(Icons.thumb_up_rounded,size: 30, color: mainColor,)),
        title: Text(event?.info),
        onTap: () => print('$event tapped!'),
      ),
    );
  }
  else{
    return null;
  }
}