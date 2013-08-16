util = require "util"
crypto = require('crypto')

module.exports =
	validateReferal: (body,key,request_signature) ->
        shasum = "sha1="+crypto.createHmac("sha1",key).update(body).digest('hex')
        util.log "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
        util.log shasum
        util.log request_signature
        util.log "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
        if shasum == request_signature
        	util.log "same"
        	return true
        else
        	util.log "different"
        	return false

