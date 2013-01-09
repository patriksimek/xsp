global.Email = class Email
	body: ''
	subject: ''
	from: 'xsp <xsp@xsp.cz>'
	recipients: null

	constructor: (@name) ->
		@recipients = []
		
	addRecipient: (email) ->
		@recipients.push email

	send: (callback) ->
		emailjs = require "emailjs"
		
		server 	= emailjs.server.connect
			host: "172.30.183.111"
			
		server.send {
			text: @body
			from: @from
			to: @recipients.join ', '
			subject: @subject
		}, (err, message) ->
			console.log(err || message)