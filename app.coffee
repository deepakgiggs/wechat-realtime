#including the cluster module for forking child process
cluster = require "cluster"

#framework for node
express = require "express"
app = express()
app.use(express.bodyParser());

#logging to a file
app.use(express.logger());

#Setting the Enviroment Variables
nconf = require "nconf"
nconf.argv().env().file({ file: './config.json' })
environment = nconf.get("NODE_ENV")

#Utility for logging
util = require "util"

#Number of Cpus available to fork that many process
cCPUs   = require('os').cpus().length;


#Setting up AWS SDK for finding the sqs queue
aws = require "aws-sdk"
aws.config.loadFromPath './config/aws.json'
sqs_conf = require("./config/sqs.json")[environment]
sqs = new aws.SQS()
sqs_queue = require "./sqs"

#facebook signature
signature = require("./config/facebook.json")[environment]["signature"]

sqs_queue_url = sqs_queue.checkQueue(sqs, sqs_conf, (error, sqs, queue_url) ->
  if error
    util.log "Error while checking queue. Exiting gracefully " + error
  else
    if cluster.isMaster
      i = 0

      #Forking child process
      while i < cCPUs
        cluster.fork()
        i += 1

      cluster.on "online", (worker) ->
        util.log "Worker " + worker.process.pid + " is online."

      #Re-initalizing child process if Dead
      cluster.on "exit", (worker, code, signal) ->
        util.log "Worker " + worker.process.pid + " died."
        cluster.fork()
    else
      #For Setting up the subscription url in facebook
      app.get "/subscription",(request,response) ->
        response.writeHead(200,{"Content-Type": "text/plain"});
        if request.query["hub.mode"] is "subscribe" and request.query['hub.verify_token'] is "tokenforfreshdesk"
          response.end request.query["hub.challenge"]
        else
          response.end "This is not valid request buddy!!!"

      #For pushing data to sqs
      app.post "/subscription",(request,response) ->
        # util.log "*******************"
        # request_signature = request.header('HTTP_X_HUB_SIGNATURE') || request.header('X-Hub-Signature')
        # util.log request.header('HTTP_X_HUB_SIGNATURE')
        #TO-DO validate the source https://developers.facebook.com/docs/reference/api/realtime/
        body = JSON.stringify(request.body)
        sqs_queue.sendMessage sqs, queue_url, body
        response.writeHead(200,{"Content-Type": "text/plain"});
        response.end("This is subscription page put request")

      app.all "*", (request,response) ->
        response.writeHead(404, {"Content-Type": "text/plain"});
        response.end("This request is not allowed")

      app
      .listen(nconf.get("PORT"))

      util.log("new application instance inside cluster!!!!!!! "+  environment))
