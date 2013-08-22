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
          #source https://developers.facebook.com/docs/reference/api/realtime/
          request_signature = request.header('HTTP_X_HUB_SIGNATURE') || request.header('X-Hub-Signature')

          body = JSON.stringify(request.body)
          util.log body
          response.writeHead 200,
            "Content-Type": "text/plain"
          if request.body["object"] == "page" && facebook_util.validateReferal(body, facebook_app["secret_key"], request_signature)
            # if environment is "development"
            if(request.body["entry"] instanceof Array)
              sqs_queue.sendMessage sqs, queue_url, '{"entry":'+JSON.stringify(body)+"}" for body, i in request.body["entry"]
              response.end("This is subscription page put request")
            else
              response.end "This request is dropped"
          else
            response.end "This request is comming from invalid source or this request is not met to be handled"

       catch error
          util.log "Error while handing POST request from facebook - " + error

  self
