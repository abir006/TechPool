import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/Utils.dart';
import 'package:tech_pool/widgets/TextBoxField.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:multiselect_formfield/multiselect_formfield.dart';
import 'package:flutter_multiselect/flutter_multiselect.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';


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

  Future<String> initInfo2(String email) async {
    isUser = (widget.email == email)&&widget.fromProfile;
      firestore.collection("Profiles").doc(widget.email).get().then(
              (value) {
      DocumentSnapshot q = value;
      q.data().forEach((key, value) {
        myInfo.setProperty(key, value);
      });
      myInfo.setPropertyEnum(userInfoKeyEnum.email, widget.email);
      if (firstTime) {
        _nameController.text =
            myInfo.getPropertyEnum(userInfoKeyEnum.firstName) +
                " " +
                myInfo.getPropertyEnum(userInfoKeyEnum.lastName);
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
        return FirebaseStorage.instance
            .ref('uploads')
            .child(widget.email)
            .getDownloadURL().then((value) {
          imageUrl = value;
          return "ok";

        } );
      }
    });
  }

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
        _nameController.text =
            myInfo.getPropertyEnum(userInfoKeyEnum.firstName) +
                " " +
                myInfo.getPropertyEnum(userInfoKeyEnum.lastName);
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

    }
    return "success";
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _facultyController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _hobbiesController = TextEditingController();
    _aboutSelf = TextEditingController();
  }
  void saveAll(){
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
    _hobbiesController.text =saveAllFields.getPropertyEnum(userInfoKeyEnum.hobbies);
    _facultyController.text = saveAllFields.getPropertyEnum(userInfoKeyEnum.faculty);
    _phoneNumberController.text = saveAllFields.getPropertyEnum(userInfoKeyEnum.phoneNumber);
    _aboutSelf.text= saveAllFields.getPropertyEnum(userInfoKeyEnum.aboutSelf);
    payments = saveAllFields.getPropertyEnum(userInfoKeyEnum.allowedPayments);
  }
  void updateInfo() async {
    try {
      saveAll();
      firestore
          .collection('Profiles')
          .doc(widget.email)
          .update(saveAllFields.keyToValueMap);
      } catch(e){}
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
            left: sizeFrameWidth * 0.2,
            right: sizeFrameWidth * 0.2,
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

    final buttons =Container(margin: EdgeInsets.only(left: defaultSpacewidth),
        child: Center(child: Row(
            mainAxisAlignment:MainAxisAlignment.start,
            crossAxisAlignment:CrossAxisAlignment.start,
            children: [SizedBox(width: defaultSpacewidth*3),Expanded(child:DiscardUpdate),SizedBox(width: defaultSpacewidth*2),Expanded(child:acceptUpdate),SizedBox(width: defaultSpacewidth*3)])));
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
                      Center(child: Stack(children: [Container(width: MediaQuery.of(context).size.height * 0.016 * 8, height: MediaQuery.of(context).size.height * 0.016 * 8, child:CircleAvatar(radius: 18, backgroundImage: isUser? userRep.profilePicture.image:NetworkImage(imageUrl)),),
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
                                        userRep.profilePicture =  Image.file((File(pickedFile.path)));
                                      });
                                    }
                                  },
                                ),
                              )),
                        ):SizedBox(height: defaultSpace*0),
                      ])),
                      isUser? Center(child: generalInfoText(text: myInfo.getPropertyEnum(userInfoKeyEnum.email)),): SizedBox(height: defaultSpace*0),
                      SizedBox(height: defaultSpace),
                      labelText(text: "Name: "),
                      editMode ? generalInfoTextField(controllerText: _nameController, enabled: true, maxLines: 1) : generalInfoText(text: _nameController.text),
                      SizedBox(height: defaultSpace),
                      labelText(text: "Faculty: "),
                      editMode ? generalInfoTextField(controllerText: _facultyController, enabled: true, maxLines: 1) : generalInfoText(text: _facultyController.text),
                      SizedBox(height: defaultSpace),
                      labelText(text: "Phone number: "),
                      editMode ? generalInfoTextField(controllerText: _phoneNumberController, enabled: true, maxLines: 1) : generalInfoText(text: _phoneNumberController.text),
                      SizedBox(height: defaultSpace),
                      labelText(text: "Hobbies: "),
                      editMode ? generalInfoTextField(controllerText: _hobbiesController, enabled: true, maxLines: 1) : generalInfoText(text: _hobbiesController.text),
                      SizedBox(height: defaultSpace),
                      labelText(text: "About self: "),
                      editMode ? generalInfoTextField(controllerText: _aboutSelf, enabled: true, maxLenth: 185) : generalInfoText(text: _aboutSelf.text, maxElepsis: 5),
                      SizedBox(height: defaultSpace),
                      labelText(text: "Allowed Payment method: "),
                      editMode ? SizedBox(height: defaultSpace):SizedBox(height: defaultSpace*0),
                      editMode ? multi2: Stack(children:[Container(child: MultiSelectChipDisplay(textStyle: TextStyle(color: Colors.black), decoration: BoxDecoration(color: Colors.white), items:payments.map((e) => MultiSelectItem(e, e)).toList(), onTap: (value) {},),),Container(color: Colors.transparent,width: 100*defaultSpacewidth,height: 10*defaultSpace,)]),
                ]));
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        });}
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Lift Info",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body:  Consumer<UserRepository>(
          builder: (context, userRep, _) =>
            Container(
                decoration: pageContainerDecoration,
                margin: pageContainerMargin,
          //padding: EdgeInsets.only(left: defaultSpacewidth, right: defaultSpacewidth),
          child: Column(
            children: [
              Expanded(child: allInfo(userRep)),
              SizedBox(height: defaultSpace),
              isUser? (editMode ? buttons : updateProfile):SizedBox(height: defaultSpace*0),
            ],
          ))),
      drawer: widget.fromProfile? Consumer<UserRepository>(builder: (context, auth, _) => techDrawer(auth, context, DrawerSections.profile)):null,
      backgroundColor: mainColor,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _facultyController.dispose();
    _phoneNumberController.dispose();
    _hobbiesController.dispose();
    _aboutSelf.dispose();
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
