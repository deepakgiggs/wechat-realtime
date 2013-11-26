util = require("util")
sns = new aws.SNS()
sns_conf = require("./../config/sns.json")[environment]

RECIPIENTS = sns_conf["recipients"]

module.exports = 
  create_notification: (sqs, callback) ->
    topic_name = sns_conf["social_notification_topic"]
    topic_arn = ""
    sns.createTopic({'Name': topic_name}, (create_topic_err, result) ->
      if create_topic_err
        util.log "Error in creating topic name" + create_topic_err
        callback(create_topic_err, null)
      else
        topic_arn = result['TopicArn']
        sns.listSubscriptionsByTopic({'TopicArn' : topic_arn}, (list_subscription_err, result) ->
          if list_subscription_err
            util.log "Error in listing subscription" + list_subscription_err
            callback(list_subscription_err, null)
          else
            subscriptions = result["Subscriptions"]
            if subscriptions.length > 0
              util.log "Subscriptions already present"
              callback(null, topic_arn)
            else
              util.log "Gonnna subscribe"
              module.exports.sqs_subscribe(sqs, topic_name, topic_arn, (sqs_subscribe_err, email_sub_response) ->
                if sqs_subscribe_err
                  util.log "Error in subscribing to SQS" + sqs_subscribe_err
                else
                  module.exports.email_subscribe(topic_arn, (email_subscribe_err, email_sub_response) ->
                    if email_subscribe_err
                      util.log "Error in subscribing for email" + email_subscribe_err
                  )
                  callback(null, topic_arn)
              )
        )
    )
    
  publish_notification: (topic_arn, message, subject) ->
    publish_params =
      'TopicArn' : topic_arn
      'Subject' : subject
      'Message' : message
    sns.publish(publish_params, (publish_err, publish_result) ->
      if publish_err
        util.log "Error in publishing the topic" + publish_err
      else
        util.log "Published successfullly!!!"
    )
  
  email_subscribe: (topic_arn, callback) ->
    for email in RECIPIENTS
      subcription_params = 
        'TopicArn' : topic_arn
        'Protocol' : "email"
        'Endpoint' : email
      sns.subscribe(subcription_params, (err, sub_result)->
        if err
          util.log "Error in creating email subcription"
          callback(err, null)
        else
          util.log "successfullly created email subcription"
          callback(null, topic_arn)
      )
      
  sqs_subscribe: (sqs, topic_name, topic_arn, callback) ->
    sqs_prefix = "sns_subscriber"
    queue_name = sqs_prefix+"_"+topic_name
    queue_attributes =
      'MessageRetentionPeriod' : "1209600"
    sqs.createQueue(QueueName: queue_name, Attributes: queue_attributes, (sqs_create_q_err, response) ->
      if sqs_create_q_err
        util.log "Error in creating sns subscriber queue" + sqs_create_q_err
      else
        sqs.getQueueUrl(QueueName: queue_name, (sqs_list_q_err, queueList) ->
          if sqs_list_q_err
            util.log "Error in getting queue url" + sqs_list_q_err
            callback(sqs_list_q_err, topic_arn)
          else
            global.sqs_queue = queueList["QueueUrl"]
            sqs.getQueueAttributes(QueueUrl: sqs_queue, AttributeNames:['QueueArn'], (get_queue_attr_err, get_queue_attr_response)->
              if get_queue_attr_err
                util.log "Error in queue Attributes" + get_queue_attr_err
                callback(get_queue_attr_err, topic_arn)
              else
                queue_arn = get_queue_attr_response["Attributes"]["QueueArn"]
                policy = module.exports.create_policy(queue_name, topic_arn, queue_arn)
                module.exports.set_policy(sqs, policy, (set_policy_err, set_policy_response)-> 
                  if set_policy_err
                    util.log set_policy_err
                    callback(set_policy_err, topic_arn)
                  else
                    subcription_params = 
                      'TopicArn' : topic_arn
                      'Protocol' : "sqs"
                      'Endpoint' : queue_arn.toString()
                    sns.subscribe(subcription_params, (subscribe_err, sub_result)->
                      if subscribe_err
                        util.log ("Error in sqs subscription"+ subscribe_err)
                        callback(subscribe_err, topic_arn)
                      else
                        util.log "successfullly created  sqs subcription" 
                        callback(null,topic_arn)
                    )
                )  
            )  
        )
    )
  
  
  create_policy: (queue_name, topic_arn, queue_arn) ->
    time = new Date().toISOString()
    policy = 
      "Id" : "Policy_"+queue_name+"_"+time,
      "Statement" : [
        {
          "Sid" : "Stmt_"+queue_name+"_"+time,
          "Action" : ["sqs:SendMessage"],
          "Effect" : "Allow",
          "Resource" : queue_arn,
          "Condition" : {
            "ArnEquals" : {
              "aws:SourceArn" : topic_arn
            }
          },
          "Principal" : {
            "AWS" : ["*"]
          }
        }
      ]
      
  set_policy: (sqs, policy_attr, callback) ->
    policy_attributes = 
      "Policy" : JSON.stringify(policy_attr)
    sqs.setQueueAttributes(QueueUrl: sqs_queue, Attributes: policy_attributes, (set_queue_attr_err,response)->
      if set_queue_attr_err
        util.log "Error in setting policyyy" + set_queue_attr_err
        callback(set_queue_attr_err, response)
      else
        util.log "Policy created successfullly" 
        callback(null,response)
    )  
  