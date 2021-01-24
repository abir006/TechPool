import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/TechDrawer.dart';
import 'package:tech_pool/Utils.dart';
import 'package:tech_pool/main.dart';
import 'package:tech_pool/widgets/TextBoxField.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:tech_pool/appValidator.dart';
import 'package:tech_pool/pages/NotificationsPage.dart';

import 'ChatPage.dart';
import 'ChatTalkPage.dart';

class ProfilePage extends StatefulWidget {
  String email;
  bool fromProfile;

  ProfilePage({Key key, @required this.email,@required this.fromProfile}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  UserInfo myInfo = UserInfo();
  UserInfo saveAllFields = UserInfo();
  TextEditingController _firstNameController;
  TextEditingController _lastNameController;
  TextEditingController _nameController;
  TextEditingController _facultyController;
  TextEditingController _hobbiesController;
  TextEditingController _phoneNumberController;
  TextEditingController _aboutSelf;
  bool editMode = false;
  bool firstTime = true;
  bool editChoice = true;
  bool isUser = true;
  String imageUrl = "";
  final picker = ImagePicker();
  List<String> payments=[];
  List<String> payments2=[];
  List<String> paymentsItems=["Cash","PayPal","Bit","PayBox"];
  ScrollController scrollCon;
  appValidator appValid;

  ///Initialize the information about the user to all fields
  Future<String> initInfo(String email) async {
    isUser = (widget.email == email)&&widget.fromProfile;
    try {
      DocumentSnapshot q =
      await firestore.collection("Profiles").doc(widget.email).get();
      q.data().forEach((key, value) {
        myInfo.setProperty(key, value);
      });
      myInfo.setPropertyEnum(userInfoKeyEnum.email, widget.email);
      if (firstTime) {
        _firstNameController.text = myInfo.getPropertyEnum(userInfoKeyEnum.firstName);
        _lastNameController.text =  myInfo.getPropertyEnum(userInfoKeyEnum.lastName);
        _nameController.text = _firstNameController.text + " " + _lastNameController.text;
        _facultyController.text =
            myInfo.getPropertyEnum(userInfoKeyEnum.faculty);
        _phoneNumberController.text =
            myInfo.getPropertyEnum(userInfoKeyEnum.phoneNumber);
        _hobbiesController.text =
            myInfo.getPropertyEnum(userInfoKeyEnum.hobbies);
        _aboutSelf.text = myInfo.getPropertyEnum(userInfoKeyEnum.aboutSelf);
        payments =[];
        List<dynamic> e = myInfo.getPropertyEnum(
            userInfoKeyEnum.allowedPayments);
        e.forEach((element) {
          payments.add(element.toString());
        });
        imageUrl = await FirebaseStorage.instance
            .ref('uploads')
            .child(widget.email)
            .getDownloadURL();
      }
    } catch (e) {
        return Future.error(e);
    }
    return "success";
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _facultyController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _hobbiesController = TextEditingController();
    _aboutSelf = TextEditingController();
    appValid = appValidator();
    appValid.checkConnection(context);
    appValid.checkVersion(context);
  }
  void saveAll(){
    saveAllFields.setPropertyEnum(userInfoKeyEnum.firstName, _firstNameController.text);
    saveAllFields.setPropertyEnum(userInfoKeyEnum.lastName, _lastNameController.text);
    saveAllFields.setPropertyEnum(userInfoKeyEnum.hobbies, _hobbiesController.text);
    saveAllFields.setPropertyEnum(userInfoKeyEnum.faculty, _facultyController.text);
    saveAllFields.setPropertyEnum(userInfoKeyEnum.phoneNumber, _phoneNumberController.text);
    saveAllFields.setPropertyEnum(userInfoKeyEnum.aboutSelf, _aboutSelf.text);
    payments2 =[];
    payments.forEach((element) {
      payments2.add(element);
    });
    saveAllFields.setPropertyEnum(userInfoKeyEnum.allowedPayments, payments2);
  }
  void updadteAll(){
    _firstNameController.text = saveAllFields.getPropertyEnum(userInfoKeyEnum.firstName);
    _lastNameController.text = saveAllFields.getPropertyEnum(userInfoKeyEnum.lastName);
    _hobbiesController.text =saveAllFields.getPropertyEnum(userInfoKeyEnum.hobbies);
    _facultyController.text = saveAllFields.getPropertyEnum(userInfoKeyEnum.faculty);
    _phoneNumberController.text = saveAllFields.getPropertyEnum(userInfoKeyEnum.phoneNumber);
    _aboutSelf.text= saveAllFields.getPropertyEnum(userInfoKeyEnum.aboutSelf);
     payments = saveAllFields.getPropertyEnum(userInfoKeyEnum.allowedPayments);
    _nameController.text = _firstNameController.text + " " + _lastNameController.text;
  }
  void updateInfo() async {
    try {
      saveAll();
      firestore
          .collection('Profiles')
          .doc(widget.email)
          .update(saveAllFields.keyToValueMap);
      Provider.of<UserRepository>(context,listen: false)
          .changeDisplayName(_firstNameController.text + " " + _lastNameController.text);
      } catch(e){}
    _nameController.text = _firstNameController.text + " " + _lastNameController.text;
  }
  @override
  Widget build(BuildContext context) {

    var sizeFrameWidth = MediaQuery.of(context).size.width;
    double defaultSpace = MediaQuery.of(context).size.height * 0.013;
    double defaultSpacewidth = MediaQuery.of(context).size.height * 0.016;
   // Future<String> _calculation = initInfo();

    final DiscardUpdate =
    RaisedButton.icon(
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.black)),
            icon: Icon(Icons.delete_outline, color: Colors.black),
            label: Text("Discard",
                style: TextStyle(color: Colors.black, fontSize: 17)),
            onPressed: () {
              setState(() {
                updadteAll();
                editMode = false;
              });
            });

    final acceptUpdate = Container(
        child: RaisedButton.icon(
            color: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.black)),
            icon: Icon(Icons.check, color: Colors.white),
            label: Text("Accept",
                style: TextStyle(color: Colors.white, fontSize: 17)),
            onPressed: () {
              setState(() {
                updateInfo();
                editMode = false;
              });
            }));

    final updateProfile = Container(
        padding: EdgeInsets.only(
          //  left: sizeFrameWidth * 0.2,
          //  right: sizeFrameWidth * 0.2,
            bottom: defaultSpace * 2),
        height: defaultSpace * 6,
        child: RaisedButton.icon(
            color: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.black)),
            icon: Icon(Icons.edit_outlined, color: Colors.white),
            label: Text("Update profile  ",
                style: TextStyle(color: Colors.white, fontSize: 17)),
            onPressed: () {
              setState(() {
                saveAll();
                payments2=payments;
                firstTime = false;
                editMode = true;
                editChoice=true;
              });
            }));

///The multi choice selected field for allowed payments
    final multi2 = MultiSelectChipField<String>(
      initialValue: payments,
       title: Text("Allowed payments"),
      textStyle: TextStyle(color: Colors.black),
      decoration: BoxDecoration(border: Border.all(width: 1, color: mainColor),),
    chipColor: Colors.white,
    selectedTextStyle:TextStyle(color: Colors.black),
    headerColor: Colors.grey,
    showHeader: false,
    items: paymentsItems.map((e) => MultiSelectItem(e, e)).toList(),
    icon: Icon(Icons.check),
    onTap: (values) {
    payments = values;
    },
    );

///The update and discard buttons container
    final buttons =Container(
        child: Center(child: Row(
            mainAxisAlignment:MainAxisAlignment.start,
            crossAxisAlignment:CrossAxisAlignment.start,
            children: [SizedBox(width: defaultSpacewidth*3),Expanded(child:DiscardUpdate),SizedBox(width: defaultSpacewidth*1),Expanded(child:acceptUpdate),SizedBox(width: defaultSpacewidth*3)])));

    Widget allInfo (UserRepository userRep) {return FutureBuilder<void>(
        future: initInfo(userRep.user.email), // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.hasData) {
            return Container(
                child: ListView(
                  controller: scrollCon,
                    reverse: false,
                    shrinkWrap: false,
                    padding: EdgeInsets.only(
                        left: defaultSpacewidth, right: defaultSpacewidth),
                    children: [
                      SizedBox(height: defaultSpace),
                      Container(
                        child: Center(child: Stack(children: [Container(width: MediaQuery.of(context).size.height * 0.016 * 8, height: MediaQuery.of(context).size.height * 0.016 * 8,child:CircleAvatar(radius: 18, backgroundColor: secondColor ,backgroundImage: isUser? userRep.profilePicture.image:NetworkImage(imageUrl))),
                          isUser? Container(padding: EdgeInsets.only(
                              left: defaultSpacewidth * 4.8, top: defaultSpacewidth * 5.3),
                            child: ClipOval(
                                child: Material(
                                  color: Colors.white, // button color
                                  child: InkWell(
                                    splashColor: mainColor, // inkwell color
                                    child: SizedBox(
                                        width: defaultSpacewidth * 4,
                                        height: defaultSpace * 4,
                                        child: Icon(
                                          Icons.camera_alt_outlined,
                                          size: defaultSpace * 4,
                                          color: secondColor,
                                        )),
                                    onTap: () async {
                                      var pickedFile = await picker.getImage(
                                        source: ImageSource.gallery,
                                        maxHeight: 100,
                                        maxWidth: 100,
                                      );
                                      if (pickedFile != null) {
                                        String ret = await FirebaseStorage.instance
                                            .ref('uploads')
                                            .child(widget.email)
                                            .putFile(File(pickedFile.path))
                                            .then((snapshot) => snapshot.ref.getDownloadURL());
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            transaction.update(
                FirebaseFirestore.instance.collection("Profiles")
                    .doc(userRep.user.email), {
              'pic': ret,
            });
          });

                                        setState(() {
                                          userRep.profilePicture =  Image.file((File(pickedFile.path)));
                                        });
                                      }
                                    },
                                  ),
                                )),
                          ):Container(padding: EdgeInsets.only(
                              left: defaultSpacewidth * 4.8, top: defaultSpacewidth * 5.3),
                              child:ClipOval(

                              child: Material(
                                color: Colors.white, // button color
                                child: InkWell(
                                  splashColor: mainColor, // inkwell color
                                  child: SizedBox(
                                      width: defaultSpacewidth * 4,
                                      height: defaultSpace * 4,
                                      child: Icon(
                                        Icons.chat_outlined,
                                        size: defaultSpace * 3,
                                        color: secondColor,
                                      )),
                                  onTap: () async {
                                    try {
                                      QuerySnapshot q2 = await FirebaseFirestore
                                          .instance
                                          .collection("ChatFriends").doc(
                                          userRep.user?.email).collection(
                                          "Network").doc(widget.email).collection(
                                          widget.email)
                                          .get();


                                      FirebaseFirestore.instance.runTransaction((
                                          transaction) async {
                                        transaction.update(
                                          FirebaseFirestore.instance
                                              .collection("ChatFriends").doc(userRep.user?.email).collection("Network").doc(widget.email),
                                          {
                                            'read': true
                                          },
                                        );
                                        q2.docs.forEach((element) {
                                          transaction.delete(element.reference);
                                        });
                                      }).catchError((e) {
                                        return null;
                                      });
                                    }catch(e){}


                                    Navigator.push(context, MaterialPageRoute(
                                        builder: (context) => ChatTalkPage(
                                          peerId: (widget.email) ,
                                          peerAvatar: imageUrl,
                                          userId: userRep.user.email,
                                        )));
                                  },
                                ),
                              ))),
                        ])),
                      ),
                      isUser? Center(child: generalInfoText(text: myInfo.getPropertyEnum(userInfoKeyEnum.email)),): SizedBox(height: defaultSpace*0),
                      SizedBox(height: defaultSpace),
                      editMode ? SizedBox(height: 0):labelText(text: "Name: ") ,
                      editMode ? generalInfoBoxTextField(nameLabel:"First Name: ",controllerText: _firstNameController, enabled: true, maxLines: 1,maxLenth: 20) : generalInfoText(text: _nameController.text),
                      editMode ? generalInfoBoxTextField(nameLabel:"Last Name: ",controllerText: _lastNameController, enabled: true, maxLines: 1,maxLenth: 20) : SizedBox(height: 0),
                      editMode ? SizedBox(height: 0):SizedBox(height: defaultSpace),
                      editMode ? SizedBox(height: 0):labelText(text: "Faculty: ") ,
                      editMode ? generalInfoBoxTextField(nameLabel:"Faculty: ",controllerText: _facultyController, enabled: true, maxLines: 1 , maxLenth: 50) : generalInfoText(text: _facultyController.text),
                      editMode ? SizedBox(height: 0):SizedBox(height: defaultSpace),
                      editMode ? SizedBox(height: 0):labelText(text: "Phone number: ") ,
                      editMode ? generalInfoBoxTextFieldNumbers(nameLabel:"Phone number: ",controllerText: _phoneNumberController, enabled: true, maxLines: null, maxLenth: 20) : generalInfoText(text: _phoneNumberController.text),
                      editMode ? SizedBox(height: 0):SizedBox(height: defaultSpace),
                      editMode ? SizedBox(height: 0):labelText(text: "Hobbies: ") ,
                      editMode ? generalInfoBoxTextField(nameLabel:"Hobbies: ",controllerText: _hobbiesController, enabled: true, maxLines: null, scrollAddable: true) : generalInfoText(text: _hobbiesController.text),
                      editMode ? SizedBox(height: 0):SizedBox(height: defaultSpace),
                      editMode ? SizedBox(height: 0):labelText(text:"About self: ") ,
                      editMode ? generalInfoBoxTextField(nameLabel:"About self: ",controllerText: _aboutSelf, enabled: true, maxLenth: 300, scrollAddable: true) : generalInfoText(text: _aboutSelf.text),
                      editMode ? SizedBox(height: 0): SizedBox(height: defaultSpace),
                      labelText(text: "Allowed Payment methods: "),
                      editMode ? SizedBox(height: defaultSpace):SizedBox(height: defaultSpace*0),
                      editMode ? multi2: Stack(children:[Container(child: MultiSelectChipDisplay(textStyle: TextStyle(color: Colors.black), decoration: BoxDecoration(color: Colors.white), items:payments.map((e) => MultiSelectItem(e, e)).toList(), onTap: (value) {},),),Container(color: Colors.transparent,width: 100*defaultSpacewidth,height: 10*defaultSpace,)]),
                ]));
          } else {
            if(snapshot.hasError){
              return Center(child: Text("Error loading info", style: TextStyle(fontSize: 15),),);
            } else{
              return Center(
                child: CircularProgressIndicator(),);
            }
          }
        });}
    return Consumer<UserRepository>(
      builder: (context, userRep, _) =>
     Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Profile ",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          widget.fromProfile? IconButton(
              icon: StreamBuilder(
                  stream: firestore.collection("Notifications").doc(userRep.user?.email).collection("UserNotifications").where("read", isEqualTo: "false").snapshots(), // a previously-obtained Future<String> or null
                  builder: (BuildContext context, snapshot) {
                    if (snapshot.hasData) {
                      return BadgeIcon(
                        icon: Icon(Icons.notifications, size: 25),
                        badgeCount: snapshot.data.size,
                      );
                    }
                    else{
                      return BadgeIcon(
                        icon: Icon(Icons.notifications, size: 25),
                        badgeCount: 0,
                      );
                    }
                  }
              ),
              onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NotificationsPage()))
          ):Container(),
          widget.fromProfile? IconButton(
              icon: StreamBuilder(
                  stream: firestore.collection("ChatFriends").doc(userRep.user?.email).collection("UnRead").snapshots(), // a previously-obtained Future<String> or null
                  builder: (BuildContext context, snapshot) {
                    if (snapshot.hasData) {
                      //QuerySnapshot values = snapshot.data;
                      //builder: (_, snapshot) =>

                      return BadgeIcon(
                        icon: Icon(Icons.message_outlined, size: 25),
                        badgeCount: snapshot.data.size,
                      );
                    }
                    else{
                      return BadgeIcon(
                        icon: Icon(Icons.message_outlined, size: 25),
                        badgeCount: 0,
                      );
                    }
                  }
              ),
              onPressed: () async {
                QuerySnapshot q2 = await  FirebaseFirestore.instance.collection("ChatFriends").doc(userRep.user.email)
                    .collection("UnRead").get();

                FirebaseFirestore.instance.runTransaction((transaction) async {
                  q2.docs.forEach((element) {
                    transaction.delete(element.reference);
                  });
                });
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ChatPage(currentUserId: userRep.user.email, fromNotification: false,)));}
          ):Container(),
        ],
      ),
      body:  Consumer<UserRepository>(
        builder: (context, userRep, _) =>
          GestureDetector(
            onTap:() {FocusScope.of(context).requestFocus(new FocusNode());},
            child: Container(
                decoration: pageContainerDecoration,
                margin: pageContainerMargin,
        //padding: EdgeInsets.only(left: defaultSpacewidth, right: defaultSpacewidth),
        child: Column(
            children: [
              Expanded(child: allInfo(userRep)),
              SizedBox(height: defaultSpace),
              isUser? (editMode ? buttons : updateProfile):SizedBox(height: defaultSpace*0),
            ],
        )),
          )),
      drawer: widget.fromProfile? Consumer<UserRepository>(builder: (context, auth, _) => techDrawer(auth, context, DrawerSections.profile)):null,
      backgroundColor: mainColor,
    )
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nameController.dispose();
    _facultyController.dispose();
    _phoneNumberController.dispose();
    _hobbiesController.dispose();
    _aboutSelf.dispose();
    appValid.listener.cancel();
    appValid.versionListener.cancel();
    super.dispose();
  }
}



/*
void _showMultiSelect(BuildContext context) async {
    await showModalBottomSheet(
      isScrollControlled: true, // required for min/max child size
      context: context,
      builder: (ctx) {
        return  MultiSelectBottomSheet(
          items:  paymentsItems.map((e) => MultiSelectItem(e, e)).toList(),
          initialValue: payments,
          onConfirm: (values) {},
          maxChildSize: 0.8,
        );
      },
    );
  }
    final pic = Center(
        child: Stack(children: [
      Container(
          width: MediaQuery.of(context).size.height * 0.016 * 8,
          height: MediaQuery.of(context).size.height * 0.016 * 8,
          child:CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(
                imageUrl,
              ),
            ),
          ),

      Container(
        padding: EdgeInsets.only(
            left: defaultSpacewidth * 4.8, top: defaultSpacewidth * 5.3),
        child: ClipOval(
            child: Material(
          color: Colors.white, // button color
          child: InkWell(
            splashColor: mainColor, // inkwell color
            child: SizedBox(
                width: defaultSpacewidth * 4,
                height: defaultSpace * 4,
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: defaultSpace * 4,
                  color: secondColor,
                )),
            onTap: () async {
              var pickedFile = await picker.getImage(
                source: ImageSource.gallery,
                maxHeight: 150,
                maxWidth: 150,
              );
              if (pickedFile != null) {
                String ret = await FirebaseStorage.instance
                    .ref('uploads')
                    .child(widget.email)
                    .putFile(File(pickedFile.path))
                    .then((snapshot) => snapshot.ref.getDownloadURL());
                setState(() {
                  imageUrl = ret;
                });
              }
            },
          ),
        )),
      ),
    ]));
     final multi=  MultiSelectChipDisplay(
      textStyle: TextStyle(color: Colors.black),
      decoration: BoxDecoration(color: Colors.white),
      items:payments.map((e) => MultiSelectItem(e, e)).toList(),
      onTap: (value) {
        setState(() {
          payments.remove(value);
        });
      },
    );
    final multiSelec =  Container(
        child: MultiSelectDialogField(
            buttonText: Text("Allowed payments",style: TextStyle(fontSize: 17),textAlign: TextAlign.left,),
            title: Text("Allowed payments"),
            initialValue: payments,
            items: paymentsItems.map((e) => MultiSelectItem(e, e)).toList(),
            onConfirm: (values) {
              setState(() {
                editChoice = false;
                payments = values;
                if(payments.isNotEmpty) {scrollCon.animateTo(0, curve: Curves.easeOut, duration: const Duration(milliseconds: 300));}
              });
            },
            chipDisplay: MultiSelectChipDisplay(
              textStyle: TextStyle(color: Colors.black),
              decoration: BoxDecoration(color: Colors.white),
              items:payments.map((e) => MultiSelectItem(e, e)).toList(),
              onTap: (value) {
                setState(()  {
                  payments = paymentsItems;
                });
              }),
        ));
 final DisMultiSelec =  Stack(children:[Container(
      child: MultiSelectChipDisplay(
        textStyle: TextStyle(color: Colors.black),
        decoration: BoxDecoration(color: Colors.white),
        items:payments.map((e) => MultiSelectItem(e, e)).toList(),
        onTap: (value) {
        },
      ),
    ),Container(color: Colors.transparent,width: 100*defaultSpacewidth,height: 10*defaultSpace,)]);
*/
