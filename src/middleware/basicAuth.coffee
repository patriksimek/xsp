module.exports = (username, password) ->
	(req, res, next) ->
		header = req.headers.authorization or ''
		token = header.split(/\s+/).pop() or ''
		auth = new Buffer(token, 'base64').toString()
		parts = auth.split /:/

		if username is parts[0] and password is parts[1]
			next()
		
		else
			res.statusCode = 401
			res.setHeader 'WWW-Authenticate', 'Basic realm="Authorization Required"'
			res.end 'Unauthorized'