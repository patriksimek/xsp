module.exports = ->
	class @AppController extends @Controller
		@index: (req, res) ->
			res.render
				title: "xsp sample application"