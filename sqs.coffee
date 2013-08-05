util = require "util"

module.exports =
  checkQueue: (sqs, sqs_queue_name, callback) ->
    util.log "Inside checkQueue"
    sqs.getQueueUrl
      QueueName: sqs_queue_name
      , (sqs_list_q_err, queueList) ->
        if sqs_list_q_err
          util.debug "Error while fetching queues from AWS - " + sqs_list_q_err
          callback(sqs_list_q_err, null, null)
        else
          if queueList["QueueUrl"]
            util.log "Queue Exists"
            sqs_queue_url = queueList["QueueUrl"]
            callback(null, sqs, sqs_queue_url)
          else
            #Create a new SQS queue
            # XXX Read queue config params from sqs.conf and create the queue
              # Attributes:
              #   VisibilityTimeout:
              #   Policy:
              #   MaximumMessageSize:
              #   MessageRetentionPeriod:
              #   ReceiveMessageWaitTimeSeconds

            sqs.createQueue
              QueueName: sqs_queue_name
              , (sqs_create_q_err, response) ->
                util.log "Creating Queue"
                if sqs_create_q_err
                  util.debug "Error while creating a queue in AWS SQS - " + sqs_create_q_err
                  callback(sqs_create_q_err, null, null)
                else
                  util.log "Queue creation successful"
                  #util.log response

                  sqs_queue_url = response["QueueUrl"]
                  callback(null, sqs, sqs_queue_url)
  sendMessage: (sqs, sqs_queue_url,body) ->
    util.log "**************************************"
    util.log body
    util.log sqs_queue_url
    sqs.sendMessage {QueueUrl : sqs_queue_url, MessageBody : body},(sqs_send_msg_err, msg_data) ->
        if sqs_send_msg_err
          util.debug "Error during message queueing - " + sqs_send_msg_err
        else
          util.debug "Pushed to sqs!!!!"