nconf = require "nconf"
AWS = require "aws-sdk"
AWS.config.loadFromPath './config/aws.json'
nconf.argv().env().file({ file: './config.json' })
environment = nconf.get("NODE_ENV")
sqs_conf = require("./config/sqs.json")[environment]
sqs = new AWS.SQS()
sqs_queue_name = sqs_conf["sqs_queue_name"]
