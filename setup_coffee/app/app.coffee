express = require 'express'
xsp = require 'xsp'

xsp.configure (app) ->
	app.set 'views', "#{__dirname}/views"
	app.set 'view engine', 'jade'
	app.use express.static("#{__dirname}/public")
	app.use express.favicon()
	app.use express.bodyParser {keepExtensions: true, uploadDir: "#{__dirname}/upload"}
	app.use express.methodOverride()
	app.use app.router

xsp.configure 'development', (app) ->
	app.use express.errorHandler()

xsp.listen()