import * as functions from "firebase-functions";

import * as admin from "firebase-admin";
const serviceAccount = require("../service-account.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://techpool-f0406.firebaseio.com",
});

export const sendLiftNotification = functions.firestore
    .document("Notifications/{userID}/UserNotifications/{notification}")
    .onCreate(async (change, context) => {
      console.log("-$-$-$-$-$-Notifications start--------------");

      // if (!change.after.exists) {
      // // Ignore delete operations
      //  return;
      // }

      const doc = change.data();
      // console.log(doc);

      const typeStr = doc.type;
      const notificationID = doc.id;
      const driveID = doc.driveId;
      const liftTime = doc.liftTime.toDate().toLocaleString(
          "en-GB", {timeZone: "Israel", month: "2-digit", day: "2-digit",
            hour: "2-digit", minute: "2-digit"});
      // const liftTimeToShow = (liftTime.getDate() + "/" +
      // ((liftTime.getMonth() + 1)) + " " +
      // liftTime.getHours() + ":" + liftTime.getMinutes());

      let contentMessage = "";
      let titleMessage = "";
      let destinationUser = "";
      switch (typeStr) {
        case "RequestedLift": {
          console.log("-*-*-*-We are in RequestedLift-*-*-*-");
          destinationUser = doc.driverId;
          console.log("destinationUser is: " + destinationUser);
          const passengerId = doc.passengerId;
          // console.log("passengerId before query is: " + passengerId);
          // Get passenger full name
          try {
            await admin
                .firestore()
                .collection("Profiles")
                .doc(passengerId)
                .get()
                .then(async (passenger) => {
                  if (passenger && passenger.data()) {
                    const passengerName = passenger?.data()?.firstName + " " +
                    passenger?.data()?.lastName;
                    console.log("passengerName inside query: " + passengerName);
                    titleMessage = passengerName +
                    " requested a lift from you.";
                    console.log("titleMessage: " + titleMessage);
                    contentMessage = "For your drive at " + liftTime;
                    console.log("contentMessage: " + contentMessage);
                  }
                });
          } catch (error) {
            console.log("Error sending message:", error);
          }
          break;
        }
        case "RejectedLift": {
          console.log("-*-*-*-We are in RejectedLift-*-*-*-");
          const driverId = doc.driverId;
          destinationUser = context.params.userID;
          console.log("destinationUser is: " + destinationUser);
          // Get driver full name
          try {
            await admin
                .firestore()
                .collection("Profiles")
                .doc(driverId)
                .get()
                .then(async (driver) => {
                  if (driver && driver.data()) {
                    const driverName = driver?.data()?.firstName + " " +
                    driver?.data()?.lastName;
                    titleMessage = driverName +
                    " rejected your request";
                    console.log("titleMessage: " + titleMessage);
                    contentMessage = "For a lift at " + liftTime;
                    console.log("contentMessage: " + contentMessage);
                  }
                });
          } catch (error) {
            console.log("Error sending message:", error);
          }
          break;
        }
        case "AcceptedLift": {
          console.log("-*-*-*-We are in AcceptedLift-*-*-*-");
          const driverId = doc.driverId;
          destinationUser = context.params.userID;
          console.log("destinationUser is: " + destinationUser);
          try {
            await admin
                .firestore()
                .collection("Profiles")
                .doc(driverId)
                .get()
                .then(async (driver) => {
                  if (driver && driver.data()) {
                    const driverName = driver?.data()?.firstName + " " +
                    driver?.data()?.lastName;
                    titleMessage = driverName +
                    " accepted your request!";
                    console.log("titleMessage: " + titleMessage);
                    contentMessage = "For a lift at " + liftTime;
                    console.log("contentMessage: " + contentMessage);
                  }
                });
          } catch (error) {
            console.log("Error sending message:", error);
          }
          break;
        }
        case "CanceledLift": {
          console.log("-*-*-*-We are in CanceledLift-*-*-*-");
          const passengerId = doc.passengerId;
          // destinationUser = context.params.userID;
          destinationUser = doc.driverId;
          console.log("destinationUser is: " + destinationUser);
          // Get passenger full name
          try {
            await admin
                .firestore()
                .collection("Profiles")
                .doc(passengerId)
                .get()
                .then(async (passenger) => {
                  if (passenger && passenger.data()) {
                    const passengerName = passenger?.data()?.firstName + " " +
                    passenger?.data()?.lastName;
                    titleMessage = passengerName +
                    " canceled his lift with you!";
                    console.log("titleMessage: " + titleMessage);
                    contentMessage = "For the drive at " + liftTime;
                    console.log("contentMessage: " + contentMessage);
                  }
                });
          } catch (error) {
            console.log("Error sending message:", error);
          }
          break;
        }
        case "CanceledDrive": {
          console.log("-*-*-*-We are in CanceledDrive-*-*-*-");
          destinationUser = context.params.userID;
          console.log("destinationUser is: " + destinationUser);
          const driverId = doc.driverId;
          // Get driver full name
          try {
            await admin
                .firestore()
                .collection("Profiles")
                .doc(driverId)
                .get()
                .then(async (driver) => {
                  if (driver && driver.data()) {
                    const driverName = driver?.data()?.firstName + " " +
                    driver?.data()?.lastName;
                    titleMessage = driverName +
                    " canceled his drive!";
                    console.log("titleMessage: " + titleMessage);
                    contentMessage = "Your lift at " + liftTime +
                    " is canceled";
                    // contentMessage = "For the lift at " + liftTime;
                    console.log("contentMessage: " + contentMessage);
                  }
                });
          } catch (error) {
            console.log("Error sending message:", error);
          }
          break;
        }
        case "DesiredLift": {
          console.log("-*-*-*-We are in DesiredLift-*-*-*-");
          const driverId = doc.driverId;
          destinationUser = context.params.userID;
          console.log("destinationUser is: " + destinationUser);
          try {
            await admin
                .firestore()
                .collection("Profiles")
                .doc(driverId)
                .get()
                .then(async (driver) => {
                  if (driver && driver.data()) {
                    const driverName = driver?.data()?.firstName + " " +
                    driver?.data()?.lastName;
                    titleMessage =
                    "We found a lift for you!";
                    console.log("titleMessage: " + titleMessage);
                    contentMessage = "At " + liftTime + " with " + driverName;
                    console.log("contentMessage: " + contentMessage);
                  }
                });
          } catch (error) {
            console.log("Error sending message:", error);
          }
          break;
        }
        default: {
          console.log("-!!-!!-!!-We are in DefaultCase-!!-!!-!!-");
          return null;
          // break;
        }
      }


      // Get push token user to (receive)
      await admin
          .firestore()
          .collection("Profiles")
          .doc(destinationUser)
          .get()
          .then(async (destUser) => {
            console.log("&&&-Inside then of sending a notification-&&&");
            if (destUser && destUser?.data()) {
              if (destUser?.data() && destUser?.data()?.pushToken) {
                console.log("payload notificationId: " +
                notificationID);
                console.log("payload driveId: " +
                driveID);
                const payload = {
                  notification: {
                    title: titleMessage,
                    body: contentMessage,
                    badge: "1",
                    sound: "default",
                  },
                  data: {
                    type: typeStr,
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    notificationId: notificationID,
                    driveId: driveID,
                  },
                };
                // Push to the target device
                console.log("dest Token is: " + destUser?.data()?.pushToken);
                await admin
                    .messaging()
                    .sendToDevice(destUser?.data()?.pushToken, payload)
                    .then(async (response) => {
                      console.log("Successfully sent message:", response);
                    })
                    .catch((error) => {
                      console.log("Error sending message:", error);
                    });
              } else {
                console.log("Can not find pushToken target user");
              }
            } else {
              console.log("Can not find pushToken target user");
            }
          });
      console.log("-----------Notifications ended-$-$-$-$-$-");
      return null;
    });

