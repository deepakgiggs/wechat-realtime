cluster = require "cluster"
express = require "express"
nconf = require "nconf"
global.aws = require "aws-sdk"
global.util = require "util"

#Setting the Enviroment Variables
nconf.argv().env().file({ file: './config/environment.json' })
global.environment = nconf.get("NODE_ENV")

#Setting up AWS SDK for finding the sqs queue
aws.config.loadFromPath './config/aws.json'
sqs_conf = require("./config/sqs.json")[environment]
sqs = new aws.SQS()
global.sqs_queue = require "./models/sqs"
sns_util = require("./lib/sns")

global.wechat_app = require("./config/wechat.json")[environment]
controllers = require("./controllers");

#Number of Cpus available to fork that many process
cCPUs = require('os').cpus().length;

# App/Express configuration
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

sns_util.create_notification(sqs, (create_notification_err, data) ->
  if create_notification_err
    util.log "Error in creating notification" + create_notification_err
  else 
    time = new Date().toISOString()
    subject = "Wechat Node reconnnected"
    message = "We chat Node has reconnected at " + time + " in '" + environment + "' environment"
    if cluster.isMaster
      sns_util.publish_notification(data, message, subject)
)

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
      global.queue_url = queue_url
      
      #For pushing data to sqs
      app.post "/postWeChatMsg", controllers.subscriptionsController().postWeChatMsg

      #Rest of the routes using wildcard
      app.all "*", (request, response) ->
        response.writeHead(200, {"Content-Type": "text/plain"});
        response.end("This request is not allowed")

      app.listen(nconf.get("PORT"))

      util.log("in " + environment + " environemnt new application instance started"))
