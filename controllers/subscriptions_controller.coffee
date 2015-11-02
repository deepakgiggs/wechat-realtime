module.exports = ->
  self =
     postWeChatMsg: (request , response) ->
      try
        response.writeHead 200,
        body = JSON.stringify(request.body)
        "Content-Type": "text/plain"
        if(request.headers.authorization in [global.wechat_app["secret_key"]])
          sqs_queue.sendMessage sqs, queue_url, body
          response.end("This is subscription page put request")
        else
          response.end "This request is dropped"
      catch error
        util.log "Error while handling post request from Wechat" + error

  self
