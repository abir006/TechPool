import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:tech_pool/pages/FavoritesPage.dart';
import 'package:tech_pool/pages/NotificationsPage.dart';
import 'package:tech_pool/pages/ProfilePage.dart';
import 'package:tech_pool/pages/ChatPage.dart';
import 'package:tech_pool/widgets/WelcomeSignInButton.dart';
import 'package:tech_pool/widgets/WelcomeSignUpButton.dart';
import 'Utils.dart';

/// enum to specify from which page the drawer is called
enum DrawerSections { home, profile, notifications, favorites, chats, settings }

/// returns a Drawer suited for the app, with the user information from userRep, and highlighting the current page being used.
SafeArea techDrawer(UserRepository userRep, BuildContext context,
    DrawerSections currentSection) {
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  return SafeArea(child: ClipRRect(
      borderRadius: BorderRadius.only(topRight: Radius.circular(20.0),bottomRight:Radius.circular(20.0)),child: Container(width: MediaQuery.of(context).size.width*0.7,
        child: Drawer(
              child: Column(children: [
                /*  UserAccountsDrawerHeader(
                  accountName: Text("Hello, ${userRep.user.displayName}.",style: TextStyle(color: Colors.white,fontSize: 18),),
                  accountEmail: Container(height: 20,child: Row(crossAxisAlignment: CrossAxisAlignment.end,mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
                Text(userRep.user.email,style: TextStyle(color: Colors.white,fontSize: 14)),
               IconButton(icon: Icon(Icons.logout,color: Colors.white,size: 25,),onPressed: () => {},)]))
     ,currentAccountPicture: CircleAvatar(backgroundColor: secondColor,))*/
                Container(
                  color: mainColor,
                  height: 180,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40, left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CircleAvatar(
                            backgroundColor: secondColor,
                            radius: 40,
                            backgroundImage: userRep.profilePicture.image,
                          ),
                        ),
                        //Spacer(),
                        Expanded(
                          child: Row(mainAxisSize: MainAxisSize.max,mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Flexible(flex: 5,child: Text("Hello, ${userRep.user?.displayName}.",
                                style: TextStyle(color: Colors.white, fontSize: 20))),
                            Flexible(flex: 1,child: IconButton(
                              icon: Icon(
                                Icons.logout,
                                color: Colors.white,
                                size: 25,
                              ),
                              onPressed: () async => await (userRep.auth
                                  .signOut()
                                  .then((_) async {
                                final EncryptedSharedPreferences encryptedSharedPreferences = EncryptedSharedPreferences();
                                encryptedSharedPreferences.clear();
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) {
                                          var size = MediaQuery.of(context).size;
                                          return Scaffold(body: Container(height: size.height, width: size.width,color: mainColor,
                                              child: Stack(alignment: Alignment.center,children: [Image.asset("assets/images/TechPoolWelcomeBackground.png"), TransparentSignInButton(), TransparentSignUnButton()],)));}));
                              })),
                            ))
                          ]),
                        )
                      ],
                    ),
                  ),
                ),
                drawerListTile("Home",Icons.home_rounded,DrawerSections.home,currentSection, context, userRep,_key),
                drawerListTile("Profile",Icons.person,DrawerSections.profile,currentSection, context, userRep,_key),
                drawerListTile("Notifications",Icons.notifications,DrawerSections.notifications,currentSection, context, userRep,_key),
                drawerListTile("Favorites",Icons.favorite,DrawerSections.favorites,currentSection, context, userRep,_key),
                drawerListTile("Chats",Icons.chat,DrawerSections.chats,currentSection, context, userRep,_key),
                Spacer(),
                AboutListTile(
                  icon: Icon(
                    Icons.info,
                    //color: mainColor,
                    size: 30,
                  ),
                  applicationIcon: Image.asset("assets/images/TechPoolCar.png",width: 40,height: 40),
                  applicationName: 'TechPool',
                  applicationVersion: 'December 2020',
                  applicationLegalese: '\u{a9} 2020 Abir Shaked,Ori Mazor and Ofir Asulin',
                ),
            /*drawerListTile("Chats",Icons.chat,DrawerSections.chats,currentSection, context, userRep,_key),
            drawerListTile("Settings",Icons.settings,DrawerSections.settings,currentSection, context, userRep,_key)*/
              ])),
      ),
      ));
}

/// creates a listTile for the drawer, with the relevant pageName,icon,tileSection for the tile.
/// and the currentSection of the drawer.
ListTile drawerListTile(String pageName,IconData icon,DrawerSections tileSection,DrawerSections currentSection, BuildContext context, UserRepository userRep,GlobalKey<ScaffoldState> key) {
  return ListTile(
    selected: currentSection == tileSection,
    leading: Icon(
      icon,
      color: mainColor,
      size: 30,
    ),
    title: Text(
      pageName,
      style: TextStyle(fontSize: 12),
    ),
    onTap: () async {
      if (currentSection == tileSection) {
        Navigator.of(context).pop();
      } else {
        if(currentSection == DrawerSections.chats){
          QuerySnapshot q2 = await  FirebaseFirestore.instance.collection("ChatFriends").doc(userRep.user.email)
              .collection("UnRead").get();
          FirebaseFirestore.instance.runTransaction((transaction) async {
            q2.docs.forEach((element) {
              transaction.delete(element.reference);
            });
          });
        }
        switch(tileSection) {
          case DrawerSections.home:
            {
              Navigator.pop(context);
              Navigator.pop(context);
              break;
            }
          case DrawerSections.profile: {
            Navigator.pop(context);
            if(currentSection == DrawerSections.home){
  Navigator.push(
  context,
  MaterialPageRoute(
  builder: (context) => ProfilePage(email: userRep.user?.email, fromProfile: true)));
  }else {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ProfilePage(
                              email: userRep.user?.email, fromProfile: true)));
            }
            break;
          }
          case DrawerSections.notifications: {
            Navigator.pop(context);
            if(currentSection == DrawerSections.home){
  Navigator.push(
  context,
  MaterialPageRoute(
  builder: (context) => NotificationsPage()));
  }else {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NotificationsPage()));
            }
            break;
          }
          case DrawerSections.favorites:{
            Navigator.pop(context);
            if(currentSection == DrawerSections.home){
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => FavoritesPage()));
            }else {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => FavoritesPage()));
            }
            break;
          }
          case DrawerSections.chats: {
  Navigator.pop(context);
  if(currentSection == DrawerSections.home){
  Navigator.push(
  context,
  MaterialPageRoute(
  builder: (context) => ChatPage(currentUserId: userRep.user.email,fromNotification: false,)));
  }else {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => ChatPage(currentUserId: userRep.user.email,fromNotification: false)));
  }
            break;
          }
          case DrawerSections.settings: {
            //Navigator.of(context).pop();
            key.currentState.showSnackBar(SnackBar(content: Text("This feature is not yet implemented", style: TextStyle(fontSize: 20,),)));
            break;
          }
        }
      }
    },
  );
}






















