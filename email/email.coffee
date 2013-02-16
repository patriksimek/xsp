global.Email = class Email
	proxy: null
	body: ''
	subject: ''
	from: ''
	recipients: null

	constructor: (@name) ->
		@recipients = []
		
	addRecipient: (email) ->
		@recipients.push email

	send: (callback) ->
		@proxy.send
			text: @body
			from: @from
			to: @recipients.join ', '
			subject: @subject
		, callback