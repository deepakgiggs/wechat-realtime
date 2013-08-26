Node.js server for processing facebook realtime data

How to run the app:
------------------
1. Install node.js - http://nodejs.org/download/
2. Install coffeescript - http://coffeescript.org/
3. Run "npm install" from the root directory of the project to install all the dependencies
4. To start the app run "coffee app.coffee or node server.js"


How to use this app
-------------------

1. Deploy this app
2. Register the public Url inside realtime update section of Facebook app
3. When the url is Registered with facebook for the first time facebook would be sending a get request with hub.mode and hub.challenge we need to respond back with hub.challenge
4. After the handshake between facebook and node app is done we can start registering the existing accounts for receiving the subscription this can be using the following rake task in helpkit "rake facebook:subscribe"
5. Once the subscription is done node will be receiving the subscriptions from facebook
6. we store the subscription in sqs
7. We can process the subscriptions from helpkit using the following rake task "rake facebook_realtime:fetch"