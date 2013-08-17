util = require "util"
crypto = require('crypto')

module.exports =
	validateReferal: (body,key,request_signature) ->
        shasum = "sha1="+crypto.createHmac("sha1",key).update(body).digest('hex')
        if shasum == request_signature
        	util.log "same"
        	return true
        else
                util.log "*************************"
                util.log body
                util.log "different"
        	return false

