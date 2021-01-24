# Database

## Overview:
The database is designed in a convenient way for easy handling lifts\drives and easily extracting data about them by maintaining one collection that stores them all.
To identify users we used their email and for identifying different docs we used random unique id that is generated when creating them.
We also used Firebase storage to store the user's selected profile picture indexed by his id.

### Drives:
The Collections stores all information about a drive\lift(timestamp,destination address,start address, driverId...) with an unique random id. The collection is indexed by driverId(its email) and timestamp to receive information faster when querying it.
Passenger-array of passengers' email.
PassengersInfo-map from the Passengers email to their information.
Stops-array of map from the stop position\number to its information.

### Profiles:
The collection store all the personal information of the user (name,allowed payments,hobbies...) with the user's email as id.

### Notifications:
The collection stores to each user two collections Pending and UserNotifications with the user's email as id.
Pending- Stores all the information (timestamp,driver id,distance...) about user's requests for a lift which the driver of the lift didn't respond to yet with an unique random id.
UserNotifications-Stores all the information (destination city,drive id,type...) about user's notifications(accepted,rejected,canceled,requested) an unique random id.
Type-accepted,rejected,canceled,requested.

### Version:
Stores the app version.

### Favorites:
This collection store all the favorite locations of the user with the user's email as id.

### Desired:
This collection stores information about desired lifts (timestamp,destination address,start address, passengerid...) with an unique random id.
The collection is indexed by PassengerId(its email) to receive information faster when querying it.

### ChatFriends:
This collection stores all information about the chat management in the app. Each user has two collections: Unread and Network.
Network contains all the users that the user talked with and didn’t delete from the network. Each user contains all the messages that the user didn’t read.
Unread: contains all the messages the user didn’t read.

### Messages:
Contains all the conversation between users in the app, each conversation gets an id that is combined from the two users ids that are part of the conversation.

### Visual Representation:
![TechPool_DataBase](https://user-images.githubusercontent.com/39681215/105644244-5393be80-5e9d-11eb-8d4c-ace9587e0e19.png)
