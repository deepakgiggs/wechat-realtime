util = require "util"
crypto = require('crypto')

module.exports =
	validateReferal: (body,key,request_signature) ->
        shasum = "sha1="+crypto.createHmac("sha1",key).update(body).digest('hex')
        util.log shasum
        if shasum == request_signature
        	return true
        else
        	return false

