util = require "util"
crypto = require('crypto')

module.exports =
  validateReferal: (body,key,request_signature) ->
   hmacsha1 = "sha1="+crypto.createHmac("sha1",key).update(body).digest('hex')
   if hmacsha1 == request_signature
     return true
   else
     util.log body
     util.log "different"
     return false

