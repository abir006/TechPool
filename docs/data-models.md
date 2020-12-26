# Data models

### 1.UserRepository
Manages the current user that uses the app, contains the user's information(email,displayname and auth state) and his profile picture.

### 2.Drive\Lift\PendingLift
Holds raw information about the event(drive\lift\pending) retrieved from the the firebase, contains the details and type of event.
Used to create a calendar tile that suits the event type and the calendar event info pages.

### 3.LiftNotification
Contains the information about a notification, the notification type(request,accepted,rejected,canceled).
Used to create the notifications page and the notification info pages.

### 4.MyLift
Contains the information about a lift and the driver, as stored in the database.
Used to create the lift-search tiles, lift info page,notification info pages and calendar event info pages.

### 5.LocationsResult
Contains the addresses as searched from the Location Search page.
Used as a return value from the Location search page, to be used by set drive page and lift search page.

### 6.liftRes
Contains all the parameters that users selected to the lift search.
Used to filter the search lift results.

### 7.UserInfo
Contains all the personal information about the user.
Used to create\update the user profile page.

### 8.appValidator
Manages the app version\internet connection.
Used to stop the user from using the app when there is no internet connection, or the version is out-dated.










