import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tech_pool/Utils.dart';
import 'package:tech_pool/main.dart';
import 'package:tech_pool/widgets/loading.dart';


class ChatTalkPage extends StatelessWidget {
  final String peerId;
  final String peerAvatar;
  final String userId;
  ChatTalkPage({Key key, @required this.peerId, @required this.peerAvatar, @required this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Chats',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        decoration: pageContainerDecoration,
        margin: pageContainerMargin,
        child: ChatScreen(
          peerId: peerId,
          peerAvatar: peerAvatar,
          userId: userId,
        ),
      ),
      backgroundColor: mainColor,
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerAvatar;
  final String  userId;

  ChatScreen({Key key, @required this.peerId, @required this.peerAvatar,@required this.userId})
      : super(key: key);

  @override
  State createState() =>
      ChatScreenState(peerId: peerId, peerAvatar: peerAvatar,id:userId);
}

class ChatScreenState extends State<ChatScreen>  with WidgetsBindingObserver {
  ChatScreenState({Key key, @required this.peerId, @required this.peerAvatar,@required this.id});

  String peerId;
  String peerAvatar;
  String id;

  List<QueryDocumentSnapshot> listMessage = new List.from([]);
  int _limit = 20;
  final int _limitIncrement = 20;
  String groupChatId;
  SharedPreferences prefs;
  int _lastIndexPhoto;
  AppLifecycleState _notification;
  File imageFile;
  bool isLoading;
  bool isShowSticker;
  String imageUrl;

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  _scrollListener() {
    if (listScrollController.offset >=
        listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
    if (listScrollController.offset <=
        listScrollController.position.minScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
      });
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        await   FirebaseFirestore.instance
            .collection('Profiles')
            .doc(id)
            .update({'chattingWith': peerId});
        break;
      case AppLifecycleState.inactive:
        chatTalkPage2 = true;
        FirebaseFirestore.instance
            .collection('Profiles')
            .doc(id)
            .update({'chattingWith': null});
        break;
      case AppLifecycleState.paused:
        chatTalkPage2 = true;
        FirebaseFirestore.instance
            .collection('Profiles')
            .doc(id)
            .update({'chattingWith': null});
        break;
      case AppLifecycleState.detached:
       // print("my:resumed");
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    chatTalkPage2 = true;
    WidgetsBinding.instance.addObserver(this);
    focusNode.addListener(onFocusChange);
    listScrollController.addListener(_scrollListener);

    groupChatId = '';

    isLoading = false;
    isShowSticker = false;
    imageUrl = '';

    readLocal();
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
        isShowSticker = false;
      });
    }
  }


  readLocal() async {
    if (id.hashCode <= peerId.hashCode) {
      groupChatId = '$id-$peerId';
    } else {
      groupChatId = '$peerId-$id';
    }

    FirebaseFirestore.instance
        .collection('Profiles')
        .doc(id)
        .update({'chattingWith': peerId});

    setState(() {});
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile pickedFile;

    pickedFile = await imagePicker.getImage(source: ImageSource.gallery);
    imageFile = File(pickedFile.path);

    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      uploadFile();
    }
  }

  void getSticker() {
    // Hide keyboard when sticker appear
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  Future uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
     await  FirebaseStorage.instance.ref('uploads').child(fileName).putFile(imageFile).then((snapshot) async {
       await snapshot.ref.getDownloadURL().then((value) {
      setState(() {
        isLoading = false;
        onSendMessage(value, 1);
      });
       });
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'This file is not an image');
    });
  }

  void onSendMessage(String content, int type) {
    // type: 0 = text, 1 = image, 2 = sticker
    if (content.trim() != '') {
      textEditingController.clear();

      var documentReference = FirebaseFirestore.instance
          .collection('messages')
          .doc(groupChatId)
          .collection(groupChatId)
          .doc(DateTime.now().millisecondsSinceEpoch.toString());

      String idFromData;
      FirebaseFirestore.instance.runTransaction((transaction) async {
        await transaction.get(FirebaseFirestore.instance.collection("Profiles")
            .doc(peerId)).then((value) => idFromData = value.data()["chattingWith"]);
        transaction.set(
          FirebaseFirestore.instance.collection("ChatFriends").doc(peerId)
              .collection("Network").doc(id),
          {
            'idFrom': id,
            'idTo': peerId,
            'timestamp': DateTime
                .now()
                .millisecondsSinceEpoch
                .toString(),
            'content': content,
            'type': type,
            'read': idFromData==id
          },
        );
        transaction.set(
          FirebaseFirestore.instance.collection("ChatFriends").doc(id)
              .collection("Network").doc(peerId),
          {
            'idFrom': id,
            'idTo': peerId,
            'timestamp': DateTime
                .now()
                .millisecondsSinceEpoch
                .toString(),
            'content': content,
            'type': type,
            'read': true
          },
        );
        if(idFromData!=id) {
       transaction.set(
            FirebaseFirestore.instance.collection("ChatFriends").doc(peerId)
                .collection("Network").doc(id).collection(id)
                .doc(),
            {
              'idFrom': id,
              'idTo': peerId,
              'timestamp': DateTime
                  .now()
                  .millisecondsSinceEpoch
                  .toString(),
              'content': content,
              'type': type
            },
          );
          transaction.set(
            FirebaseFirestore.instance.collection("ChatFriends").doc(peerId)
                .collection("UnRead")
                .doc(),
            {
              'idFrom':id,
              'timestamp': DateTime
                  .now()
                  .millisecondsSinceEpoch
                  .toString(),
            },
          );
        }
        transaction.set(
          documentReference,
          {
            'idFrom': id,
            'idTo': peerId,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'content': content,
            'type': type
          },
        );
      });
/*
     FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.get(FirebaseFirestore.instance.collection("Profiles")
            .doc(peerId))
            .then((value) async {
          if (value.data()["chattingWith"] != id) {
            transaction.set(
              FirebaseFirestore.instance.collection("ChatFriends").doc("gjjhg"),
              {
                'idFrom': id,
                'idTo': peerId,
                'timestamp': DateTime
                    .now()
                    .millisecondsSinceEpoch
                    .toString(),
                'content': content,
                'type': type
              },
            );
          }
        });
      });
*/
      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(
          msg: 'Nothing to send',
          backgroundColor: Colors.black,
          textColor: Colors.red);
    }
  }

  Widget buildItem(int index, DocumentSnapshot document) {
    if (document.data()['idFrom'] == id) {
      // Right (my message)
      return Container(
        child: Column(
            children: <Widget>[
        Row(
        children: <Widget>[
          document.data()['type'] == 0
          // Text
              ? Container(
            child: Text(
              document.data()['content'],
              style: TextStyle(color: primaryColor),
            ),
            padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
            width: 200.0,
            decoration: BoxDecoration(
                color: greyColor2,
                borderRadius: BorderRadius.circular(8.0)),
          //  margin: EdgeInsets.only(
             //   bottom: isLastMessageRight(index) ? 20.0 : 10.0,
             //   right: 10.0),
          )
              : document.data()['type'] == 1
          // Image
              ? Container(
            child: FlatButton(
              child: Material(
                child: CachedNetworkImage(
                  placeholder: (context, url) => Container(
                    child: CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(secondColor),
                    ),
                    width: 200.0,
                    height: 200.0,
                    padding: EdgeInsets.all(70.0),
                    decoration: BoxDecoration(
                      color: greyColor2,
                      borderRadius: BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Material(
                    child: Image.asset(
                      'assets/images/img_not_available.jpeg',
                      width: 200.0,
                      height: 200.0,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.0),
                    ),
                    clipBehavior: Clip.hardEdge,
                  ),
                  imageUrl: document.data()['content'],
                  width: 200.0,
                  height: 200.0,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                clipBehavior: Clip.hardEdge,
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FullPhoto(
                            url: document.data()['content'])));
              },
              padding: EdgeInsets.all(0),
            ),
           // margin: EdgeInsets.only(
             //   bottom: isLastMessageRight(index) ? 20.0 : 10.0,
              //  right: 10.0),
          )
          // Sticker
              : Container(
            child: Image.asset(
              'assets/images/${document.data()['content']}.gif',
              width: 100.0,
              height: 100.0,
              fit: BoxFit.cover,
            ),
            //margin: EdgeInsets.only(
             //   bottom: isLastMessageRight(index) ? 20.0 : 10.0,
              //  right: 10.0),
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.end,
      ),
              // Time
              isLastMessageRight(index)
                  ?
              Container(
                child: Text(
                  DateFormat('dd MMM kk:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(
                          int.parse(document.data()['timestamp']))),
                  style: TextStyle(
                      color: greyColor,
                      fontSize: 12.0,
                      fontStyle: FontStyle.italic),
                ),
                margin: EdgeInsets.only(left: 30.0, top: 5.0, bottom: 5.0),
              )
                  : Container()
            ],
          crossAxisAlignment: CrossAxisAlignment.end,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );

    } else {
      // Left (peer message)
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                isLastMessageLeftPhoto(index)
                    ? Material(
                  child: CachedNetworkImage(
                    placeholder: (context, url) => Container(
                      child: CircularProgressIndicator(
                        strokeWidth: 1.0,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(secondColor),
                      ),
                      width: 35.0,
                      height: 35.0,
                      padding: EdgeInsets.all(10.0),
                    ),
                    color: secondColor,
                    colorBlendMode: BlendMode.dstOver ,
                    imageUrl: peerAvatar,
                    width: 35.0,
                    height: 35.0,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(18.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                )
                    : Container(width: 35.0),
                document.data()['type'] == 0
                    ? Container(
                  child: Text(
                    document.data()['content'],
                    style: TextStyle(color: Colors.white),
                  ),
                  padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                  width: 200.0,
                  decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8.0)),
                  margin: EdgeInsets.only(left: 10.0),
                )
                    : document.data()['type'] == 1
                    ? Container(
                  child: FlatButton(
                    child: Material(
                      child: CachedNetworkImage(
                        placeholder: (context, url) => Container(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                secondColor),
                          ),
                          width: 200.0,
                          height: 200.0,
                          padding: EdgeInsets.all(70.0),
                          decoration: BoxDecoration(
                            color: greyColor2,
                            borderRadius: BorderRadius.all(
                              Radius.circular(8.0),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            Material(
                              child: Image.asset(
                                'assets/images/img_not_available.jpeg',
                                width: 200.0,
                                height: 200.0,
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(8.0),
                              ),
                              clipBehavior: Clip.hardEdge,
                            ),
                        imageUrl: document.data()['content'],
                        width: 200.0,
                        height: 200.0,
                        fit: BoxFit.cover,
                      ),
                      borderRadius:
                      BorderRadius.all(Radius.circular(8.0)),
                      clipBehavior: Clip.hardEdge,
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => FullPhoto(
                                  url: document.data()['content'])));
                    },
                    padding: EdgeInsets.all(0),
                  ),
                  margin: EdgeInsets.only(left: 10.0),
                )
                    : Container(
                  child: Image.asset(
                    'assets/images/${document.data()['content']}.gif',
                    width: 100.0,
                    height: 100.0,
                    fit: BoxFit.cover,
                  ),
                 // margin: EdgeInsets.only(
                  //    bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                  //    right: 10.0),
                ),
              ],
            ),

            // Time
            isLastMessageLeft(index)
                ?
            Container(
              child: Text(
                DateFormat('dd MMM kk:mm').format(
                    DateTime.fromMillisecondsSinceEpoch(
                        int.parse(document.data()['timestamp']))),
                style: TextStyle(
                    color: greyColor,
                    fontSize: 12.0,
                    fontStyle: FontStyle.italic),
              ),
              margin: EdgeInsets.only(left: 50.0, top: 5.0, bottom: 5.0),
            )
                : Container()
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
  }

  bool isLastMessageLeftPhoto(int index) {
    return index==_lastIndexPhoto;
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 &&
        listMessage != null &&
        listMessage[index - 1].data()['idFrom'] == id
    ) ||
      (index > 0 &&(  DateTime.fromMillisecondsSinceEpoch(int.parse(listMessage[index].data()['timestamp'])).add(Duration(minutes: 5))
          .compareTo
        (DateTime.fromMillisecondsSinceEpoch(int.parse(listMessage[index-1].data()['timestamp'])))<=0))
        ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
        listMessage != null &&
        listMessage[index - 1].data()['idFrom'] != id)
        ||
        (index > 0 &&(  DateTime.fromMillisecondsSinceEpoch(int.parse(listMessage[index].data()['timestamp'])).add(Duration(minutes: 5))
            .compareTo
          (DateTime.fromMillisecondsSinceEpoch(int.parse(listMessage[index-1].data()['timestamp'])))<=0))
        ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() async {
    chatTalkPage2 = false;
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      FirebaseFirestore.instance
          .collection('Profiles')
          .doc(id)
          .update({'chattingWith': null});

      QuerySnapshot q2 = await FirebaseFirestore.instance
          .collection("ChatFriends").doc(id).collection("Network").doc(peerId).collection(peerId)
          .get();

      FirebaseFirestore.instance.runTransaction((transaction) async {
        q2.docs.forEach((element) {
          transaction.delete(element.reference);
        });
        try {
          transaction.update(
            FirebaseFirestore.instance.collection("ChatFriends")
                .doc(id)
                .collection("Network")
                .doc(peerId),
            {
              'read': true
            },
          );
        }catch(e){}

      });
      Navigator.pop(context);
    }

    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              // List of messages
              buildListMessage(),

              // Sticker
              (isShowSticker ? buildSticker() : Container()),

              // Input content
              buildInput(),
            ],
          ),

          // Loading
          buildLoading()
        ],
      ),
      onWillPop: onBackPress,
    );
  }

  Widget buildSticker() {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi1', 2),
                child: Image.asset(
                  'assets/images/mimi1.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi2', 2),
                child: Image.asset(
                  'assets/images/mimi2.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi3', 2),
                child: Image.asset(
                  'assets/images/mimi3.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi4', 2),
                child: Image.asset(
                  'assets/images/mimi4.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi5', 2),
                child: Image.asset(
                  'assets/images/mimi5.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi6', 2),
                child: Image.asset(
                  'assets/images/mimi6.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi7', 2),
                child: Image.asset(
                  'assets/images/mimi7.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi8', 2),
                child: Image.asset(
                  'assets/images/mimi8.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi9', 2),
                child: Image.asset(
                  'assets/images/mimi9.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: greyColor2, width: 0.5)),
          color: Colors.white),
      padding: EdgeInsets.all(5.0),
      height: 180.0,
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading ? const Loading() : Container(),
    );
  }

  Widget buildInput() {
    return Container(
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: greyColor2, width: 0.5)),),
      child: Container(
        child: Row(
          children: <Widget>[
            // Button send image
            Material(
              borderRadius:  BorderRadius.all(Radius.circular(20.0)),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 1.0),
                child: IconButton(
                  icon: Icon(Icons.image),
                  onPressed: getImage,
                  color: primaryColor,
                ),
              ),
              color: Colors.white,
            ),
            Material(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 1.0),
                child: IconButton(
                  icon: Icon(Icons.face),
                  onPressed: getSticker,
                  color: primaryColor,
                ),
              ),
              color: Colors.white,
            ),

            // Edit text
            Flexible(
              child: Container(
                child: TextField(
                  onSubmitted: (value) {
                    onSendMessage(textEditingController.text, 0);
                  },
                  style: TextStyle(color: primaryColor, fontSize: 15.0),
                  controller: textEditingController,
                  decoration: InputDecoration.collapsed(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: greyColor),
                  ),
                  focusNode: focusNode,
                ),
              ),
            ),

            // Button send message
            Material(
              borderRadius: BorderRadius.all(Radius.circular(20.0)),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 8.0),
                child: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => onSendMessage(textEditingController.text, 0),
                  color: primaryColor,
                ),
              ),
              color: Colors.white,
            ),
          ],
        ),
       // width: double.infinity,
        height: 50.0,
      decoration:  BoxDecoration(color: Colors.white,borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20.0),bottomRight:Radius.circular(20.0))),
      /*  decoration: BoxDecoration(
            border: Border(top: BorderSide(color: greyColor2, width: 0.5)),
            color: Colors.white),*/
      ),
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId == ''
          ? Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(secondColor)))
          : StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .doc(groupChatId)
            .collection(groupChatId)
            .orderBy('timestamp', descending: true)
            .limit(_limit)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
                child: CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(secondColor)));
          } else {
            listMessage =[];
            listMessage.addAll(snapshot.data.documents);
            Comparator<DocumentSnapshot> timeComparator = (a, b) {
              return (int.parse(b.data()['timestamp']).compareTo(int.parse(a.data()['timestamp'])));
            };
            listMessage.sort(timeComparator);
            for(int i=0;i<listMessage.length;i++){
              if(listMessage[i].data()['idFrom']!=id){
                _lastIndexPhoto = i;
                break;
              }
            }
            return ListView.builder(
              padding: EdgeInsets.all(10.0),
              itemBuilder: (context, index) =>
                  buildItem(index, listMessage[index]),
              itemCount: snapshot.data.documents.length,
              reverse: true,
              controller: listScrollController,
            );
          }
        },
      ),
    );
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
