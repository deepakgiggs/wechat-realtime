cluster = require "cluster"
express = require "express"
nconf = require "nconf"
aws = require "aws-sdk"
global.facebook_util = require "./lib/util"
global.util = require "util"

#Setting the Enviroment Variables
nconf.argv().env().file({ file: './config/environment.json' })
global.environment = nconf.get("NODE_ENV")

#Setting up AWS SDK for finding the sqs queue
aws.config.loadFromPath './config/aws.json'
sqs_conf = require("./config/sqs.json")[environment]
sqs = new aws.SQS()
global.sqs_queue = require "./models/sqs"
global.facebook_app = require("./config/facebook.json")[environment]
controllers = require("./controllers");

#Number of Cpus available to fork that many process
cCPUs   = require('os').cpus().length;

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
      global.sqs = sqs
      global.queue_url = sqs_queue_url
      #For Setting up the subscription url in facebook
      app.get "/subscription",controllers.subscriptionsController().getSubscription
      #For pushing data to sqs
      app.post "/subscription",controllers.subscriptionsController().postSubscription

      app.all "*", (request,response) ->
        response.writeHead(200, {"Content-Type": "text/plain"});
        response.end("This request is not allowed")

      app
      .listen(nconf.get("PORT"))

      util.log("in "+environment+" environemnt new application instance started :) :) "))
