cluster = require "cluster"
express = require "express"
nconf = require "nconf"
util = require "util"
aws = require "aws-sdk"
facebook_util = require "./lib/util"

# app configuration
app = express()
app.configure ->
  app.use express.errorHandler(
    dumpExceptions: true
    showStack: true
  )
  app.use(express.bodyParser());
  #logging to a file 
  app.use(express.logger('dev'));
  app.use(express.methodOverride());
  app.use(app.router);
 

#Setting the Enviroment Variables
nconf.argv().env().file({ file: './config/environment.json' })
environment = nconf.get("NODE_ENV")

#Number of Cpus available to fork that many process
cCPUs   = require('os').cpus().length;

#Setting up AWS SDK for finding the sqs queue
aws.config.loadFromPath './config/aws.json'
sqs_conf = require("./config/sqs.json")[environment]
sqs = new aws.SQS()
sqs_queue = require "./models/sqs"

facebook_app = require("./config/facebook.json")[environment]

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
       try
          request_signature = request.header('HTTP_X_HUB_SIGNATURE') || request.header('X-Hub-Signature')
          #source https://developers.facebook.com/docs/reference/api/realtime/
          body = JSON.stringify(request.body)
          util.log body
          response.writeHead(200,{"Content-Type": "text/plain"});
          if facebook_util.validateReferal(body,facebook_app["secret_key"],request_signature)
            sqs_queue.sendMessage sqs, queue_url, body
            response.end("This is subscription page put request")
          else
            response.end("This request is comming from invalid source!!") 
       catch error
          util.log error

      app.all "*", (request,response) ->
        response.writeHead(200, {"Content-Type": "text/plain"});
        response.end("This request is not allowed")

      app
      .listen(nconf.get("PORT"))

      util.log("in "+environment+" environemnt new application instance started :) :) "))
