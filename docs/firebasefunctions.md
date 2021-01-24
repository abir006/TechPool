# Firebase functions

### Drive\lift hour before notification cloud function:
The drive\lift reminder is triggered by a google scheduler(job) that is being called every 5 minutes.
the scheduler triggers an http function, which sends reminder to all of the users which have a
drive or a lift within an hour.

### Chat notification cloud function:
The chat function is triggered at every message document that is created on the message collection.
It sends notification with the message content to its destination, only if the destination user
is not currently with the application open or is currently talking to the sender.


### Lift notification cloud function:
The function checks for an “OnCreate” trigger on notifications documents in firebase.
If a notification document is created, a notification is sent to the relevant driver or hitchhiker.
The types of notifications are: Lift Accepted, Lift Rejected, Request for a Lift, Drive Canceled by a driver,
Lift Canceled by a hitchhiker and a new desired Lift is found.












