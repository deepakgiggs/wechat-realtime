module.exports = ->
  self =
    getSubscription: (request, response) ->
      response.writeHead 200,
        "Content-Type": "text/plain"

      if request.query["hub.mode"] is "subscribe" and request.query["hub.verify_token"] is "tokenforfreshdesk"
        response.end request.query["hub.challenge"]
      else
        response.end "This is not valid request buddy!!!"

    postSubscription: (request, response) ->
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

  self