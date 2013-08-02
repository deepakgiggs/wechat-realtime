cluster = require "cluster"
express = require "express"
http = require "http"
nconf = require "nconf"
util = require "util"
app = express()
cCPUs   = require('os').cpus().length;
#Environment Variables	
nconf.argv().env().file({ file: './config.json' })
environment = nconf.get("NODE_ENV")
sqs_queue = require "./sqs"
util.log "Running in " + environment.toString() + " environment"

if cluster.isMaster
  i = 0

  while i < cCPUs
   cluster.fork()
   i += 1
  cluster.on "online", (worker) ->
    util.log "Worker " + worker.process.pid + " is online."

  cluster.on "exit", (worker, code, signal) ->
    util.log "worker " + worker.process.pid + " died."
    cluster.fork()
else
 #Configuration Variables
  app.get "/subscription",(request,response) ->
   response.writeHead(200,{"Content-Type": "text/plain"});
   if request.query["hub.mode"] is "subscribe" and request.query['hub.verify_token'] is "tokenforfreshdesk"
     response.end request.query["hub.challenge"]
   else
     response.end "This is not valid request buddy!!!"

  app.post "/subscription",(request,response) ->	
   post = request.body	
   response.writeHead(200,{"Content-Type": "text/plain"});
   response.end("This is subscription page put request")

  app.all "*", (request,response) ->
   response.writeHead(404, {"Content-Type": "text/plain"});
   response.end("This request is not allowed")

  app
  .listen(nconf.get("PORT"))

  util.log("new application instance inside cluster!!!!!!!")
