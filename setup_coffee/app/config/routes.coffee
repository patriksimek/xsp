module.exports = ->
	@get '/', 'app#index'

	@get '/*', (req, res) ->
		res.send 404, 'Not found'