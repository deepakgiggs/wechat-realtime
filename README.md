Node.js server for processing We chat realtime data

How to run the app:
------------------
1. Install node.js - http://nodejs.org/download/
2. Install coffeescript - http://coffeescript.org/
3. Run "npm install" from the root directory of the project to install all the dependencies
4. To start the app run "coffee app.coffee or node server.js"


How to use this app
-------------------

1. Deploy this app
2. Register the public Url inside realtime update section of We chat app
3. Once the subscription is done node will be receiving the subscriptions from We chat
4. we store the subscription in sqs
5. We can process the subscriptions from helpkit 