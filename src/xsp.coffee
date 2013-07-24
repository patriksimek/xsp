express = require 'express'
fs = require 'fs'
async = require 'async'
yaml = require 'js-yaml'
report = require './report'
tasks = require './tasks'
http = require 'http'
https = require 'https'

xsp = module.exports
xsp.tasks = tasks
	
# -----------------------------------

global.trace = (msg) ->
	console.log Array.prototype.join.call arguments, ', '
	
global.inspect = (obj) ->
	console.dir obj

require('./colors.js').call xsp

# -----------------------------------

xsp.env = process.env.NODE_ENV or 'development'
xsp.cfg = require("#{__dirname}/../../../app/config/server.yml").server
xsp.db = null # placeholder for database connection

if xsp.env is 'test'
	global.xsp = xsp

if fs.existsSync "#{__dirname}/../../../app/config/server.#{xsp.env}.yml"
	cfgmore = require("#{__dirname}/../../../app/config/server.#{xsp.env}.yml").server
	cfgupdate = (tar, src) ->
		for name, value of src
			if tar[name]
				if typeof tar[name] is 'object' and typeof src[name] is 'object'
					unless tar[name] instanceof Array
						cfgupdate tar[name], src[name]
					
					else
						tar[name] = src[name]
					
				else
					tar[name] = src[name]
				
			else
				tar[name] = src[name]
	
	cfgupdate xsp.cfg, cfgmore

xsp.languageDefaults = (req) ->
	unless xsp.cfg.defaults then return null
		
	for lang in req.acceptedLanguages
		lang = lang.toLowerCase()
		if xsp.cfg.defaults[lang]
			return xsp.cfg.defaults[lang]
	
	xsp.cfg.defaults['*']

# -----------------------------------

loaded = {}
loadedQueue = {}
loadModule = (module, loadedpath) ->
	module?.call xsp
	loaded[loadedpath] = true
									
	for path, module of loadedQueue
		deps = module.DEPENDENCIES
		index = deps.indexOf loadedpath

		if index isnt -1
			deps.splice index, 1
			
			if deps.length is 0
				delete loadedQueue[path]
				
				#trace "loading queued", path
				loadModule module, path

xsp.autoload = (dir, scope) ->
	if fs.existsSync "#{dir}"
		if fs.lstatSync(dir).isDirectory()
			later = []
			
			fs.readdirSync(dir).forEach (file) ->
				path = require('path').normalize("#{dir}/#{file}")
				stats = fs.lstatSync path
				
				unless file.substr(0, 1) is '.'
					if stats.isDirectory()
						later.push path
					else
						try
							if scope
								module = require(path)
								
								module.DEPENDENCIES ?= []
								if typeof module.DEPENDENCIES is 'string' 
									module.DEPENDENCIES = [module.DEPENDENCIES]
									
								deps = module.DEPENDENCIES
								
								for dep, index in deps
									deps[index] = require('path').normalize(dep)
								
								if deps.length > 0
									for dep, index in deps by -1
										if loaded[dep] then deps.splice index, 1
								
								if deps.length is 0
									loadModule module, path
								
								else
									loadedQueue[path] = module
									#trace "queued: #{path}"
									
							else
								require path
								
						catch ex
							trace.red "[xsp] autoload failed on: #{path}"
							inspect.red ex
							
			for l in later
				xsp.autoload l, scope
							
		else
			try
				if scope
					require(dir)?.call xsp
				else
					require dir
					
			catch ex
				trace.red "[xsp] autoload failed on: #{dir}"
				inspect.red ex
				
	else
		if fs.existsSync "#{dir}.js" or fs.existsSync "#{dir}.coffee"
			try
				if scope
					require(dir)?.call xsp
				else
					require dir
					
			catch ex
				trace.red "[xsp] autoload failed on: #{dir}"
				inspect.red ex
				
		else
			trace.red "[xsp] autoload path not found: #{dir}"

xsp.autoload "#{__dirname}/prototype"

# -----------------------------------

app = xsp.app = express()
locals = xsp.locals = {}
inits = []
dictionaries = {}
controllers = {}
pathsTo = {}
socketController = null
socketClient = null

xsp.configure = (env, fce) ->
	if typeof env is 'string'
		if env is app.settings.env
			app.configure env, () ->
				fce app
		
	else
		app.configure () ->
			env app
			
xsp.init = (env, fce) ->
	if typeof env is 'string'
		if env is app.settings.env
			inits.push fce.bind(xsp)
		
	else
		inits.push env.bind(xsp)
			
xsp.get = ->
	path = arguments[0]

	for arg, index in arguments when index > 0
		if typeof arg is 'string'
			arguments[index] = controllers[arg] ? arg
	
	controller = arguments[arguments.length - 1]
	
	for arg, index in arguments when index > 0
		if arg instanceof Function
			arguments[index] = arg.bind(xsp)
			
		else
			throw new Error 'Undefined controller found in xsp.get(): '+ arg
		
	pathsTo[controller.__shortcut] = path

	Array.prototype.splice.call arguments, 1, 0, routed
	re = app.get.apply app, arguments
	
	for route in app.routes.get
		if route.path is path
			route.controller = controller.__shortcut
			
			# secial filter for supported languages
			if path is '/:lang'
				route.regexp = new RegExp("^\\/(?:(#{xsp.cfg.locales.join('|')}))\\/?$", "i")
			
	re

xsp.post = ->
	path = arguments[0]
	
	for arg, index in arguments when index > 0
		if typeof arg is 'string'
			arguments[index] = controllers[arg]
	
	controller = arguments[arguments.length - 1]
	
	for arg, index in arguments when index > 0
		if arg instanceof Function
			arguments[index] = arg.bind(xsp)
			
		else
			throw new Error 'Undefined controller found in xsp.post()'
	
	pathsTo[controller.__shortcut] = path
	
	Array.prototype.splice.call arguments, 1, 0, routed
	re = app.post.apply app, arguments
	
	for route in app.routes.post
		if route.path is path
			route.controller = controller.__shortcut
			
	re

xsp.all = ->
	path = arguments[0]
	
	for arg, index in arguments when index > 0
		if typeof arg is 'string'
			arguments[index] = controllers[arg]
	
	controller = arguments[arguments.length - 1]
	
	for arg, index in arguments when index > 0
		if arg instanceof Function
			arguments[index] = arg.bind(xsp)
			
		else
			throw new Error 'Undefined controller found in xsp.all()'
		
	pathsTo[controller.__shortcut] = path
	
	Array.prototype.splice.call arguments, 1, 0, routed
	re = app.all.apply app, arguments
	
	for route in app.routes.get
		if route.path is path
			route.controller = controller.__shortcut
			
	for route in app.routes.post
		if route.path is path
			route.controller = controller.__shortcut
			
	re
			
xsp.listen = ->
	xsp.autoload "#{__dirname}/../../../app/config/routes", true

	for locale in xsp.cfg.locales
		try
			dict = require "#{__dirname}/../../../app/locales/#{locale}.yml"
			dictionaries[locale] = dict[locale]
			
		catch ex
			trace.red "[xsp] failed to load localization #{locale}.yml"
			inspect.red ex
	
	#report app

	for init in inits
		init.bind xsp
	
	async.series inits, (err) ->
		app.set 'hostname', xsp.cfg.hostname
		
		bapp = express()
		bapp.use express.vhost(xsp.cfg.host, app)
		bapp.use (req, res, next) ->
			res.redirect "http://#{xsp.cfg.hostname}"
		
		server = http.createServer(bapp)
		server.listen xsp.cfg.port, =>
			unless xsp.env is 'test'
				trace.grey "[xsp] http server listening on #{xsp.cfg.hostname} in #{app.settings.env} mode"

		if socketController
			socketController = new socketController require('socket.io').listen(server)
		
		if xsp.cfg.ssl
			app.set 'sslhostname', xsp.cfg.ssl.hostname
			
			async.parallel [
				(callback) => fs.readFile("#{__dirname}/../../../ssl/#{xsp.cfg.ssl.privatekey}", callback)
				(callback) => fs.readFile("#{__dirname}/../../../ssl/#{xsp.cfg.ssl.certificate}", callback)
			], (err, results) =>
				unless err
					bapp = express()
					bapp.use express.vhost(xsp.cfg.ssl.hostname, app)
					bapp.use (req, res, next) ->
						res.redirect "https://#{xsp.cfg.host}"
						
					https.createServer({key: results[0].toString(), cert: results[1].toString()}, bapp).listen xsp.cfg.ssl.port, =>
						unless xsp.env is 'test'
							trace.grey "[xsp] https server listening on #{xsp.cfg.ssl.hostname} in #{app.settings.env} mode"
				
				else
					inspect.red err

xsp.translate = (dictionary, path, variables) ->
	if typeof dictionary is 'string'
		dictionary = dictionaries[dictionary]
		
	unless dictionary
		return "## #{path}"
		
	try
		eval("var verb = dictionary.#{path}")
		if verb is undefined or verb is null then return "## #{path}"
		
		if variables
			return verb.format variables
			
		else
			return verb
		
	catch ex
		return "## #{path}"

xsp.dictionary = (dictionary) ->
	if typeof dictionary is 'string'
		dictionary = dictionaries[dictionary]
		
	return dictionary

xsp.saveDictionary = (dictionary, callback) ->
	if typeof dictionary is 'string'
		dictionary = dictionaries[dictionary]
	
	yml = {}
	yml[dictionary._code] = dictionary

	fs.writeFile "#{__dirname}/../../../app/locales/#{dictionary._code}.yml", yaml.dump(yml), callback
	
# path 'model#detail', 'id'					=> /model/detail/:id
# path 'model#detail', 'id', '#anchor'		=> /model/detail/:id#anchor (anchor must be last argument)

xsp.path = (controller, lang) ->
	args = arguments
	last = arguments[arguments.length - 1]
	anchor = ''
	
	if typeof last is 'string' and last.substr(0, 1) is '#'
		Array.prototype.pop.call arguments
		anchor = last
	
	if typeof controller is 'function'
		controller = controller.__shortcut
	
	path = pathsTo[controller]
	
	unless path
		return '/'
		
	unless path.substr(0, 6) is '/:lang'
		Array.prototype.splice.call arguments, 1, 1
	
	index = 1
	if arguments.length > 1
 		path = path.replace /:[^\/]*/g, (f) ->
 			return args[index++] ? f

	path + anchor

# -----------------------------------

app.use (req, res, next) ->
	startTime = new Date
	
	# trace.grey "[xsp] #{xsp.colors.grey}#{req.method} #{req.originalUrl}#{xsp.colors.def}"

	end = res.end
	res.end = (chunk, encoding) ->
		res.end = end
		res.end chunk, encoding
		
		color = xsp.colors.green
		if res.statusCode >= 500 then color = xsp.colors.red
		else if res.statusCode >= 400 then color = xsp.colors.yellow
		else if res.statusCode >= 300 then color = xsp.colors.cyan
		
		if xsp.env is 'development'
			trace.grey "[xsp] #{xsp.colors.grey}#{req.method} #{req.originalUrl} #{color}#{res.statusCode}#{xsp.colors.grey} #{new Date - startTime}ms#{xsp.colors.def}"
		
	next()
	
routed = (req, res, next) ->
	req.defaults = xsp.languageDefaults(req)
	req.language = req.params?.lang ? req.cookies?.language ? req.defaults?.locale ? xsp.cfg.default_locale

	if req.route.path.substr(0, 6) is '/:lang'
		if xsp.cfg.locales.indexOf(req.language) is -1
			res.redirect xsp.path('app#index', req.defaults?.locale ? xsp.cfg.default_locale)
			return

	req.t = (path, variables) ->
		xsp.translate req.language, path, variables
		
	res.p = (controller) ->
		Array.prototype.splice.call arguments, 1, 0, req.language
		xsp.path arguments...

	res.locals.xsp = xsp
	res.locals.req = req
	res.locals.res = res
	res.locals.t = res.locals.translate = req.t
	res.locals.p = res.locals.path = res.p
	res.locals.title = xsp.translate req.language, 'app.name'
	res.locals.languages = xsp.cfg.locales
	res.locals.menu = req.route.controller
	
	for n, l of locals
		res.locals[n] = l
	
	render = res.render
	res.render = (view, variables, callback) ->
		res.render = render

		if typeof view is 'function'
			view = undefined
			variables = undefined
			callback = view
			
		if typeof view is 'object'
			callback = variables
			variables = view
			view = undefined

		unless view
			view = req.route.controller.replace(/#/g, '/')

		res.locals.view = view
		
		title = req.t "#{view.replace(/\//g, '.')}.title"
		if title.substr(0, 2) isnt '##'
			res.locals.title = title

		res.render view, variables, callback

	next()
		
# -----------------------------------

class xsp.Controller

class xsp.Model

class xsp.ProtocolController extends xsp.Controller
	@https: (req, res, next) ->
		if req.protocol is 'https'
			next()
		
		else
			res.send 403.4, "Forbidden"
	
	@http: (req, res, next) ->
		if req.protocol is 'http'
			next()
		
		else
			res.send 403, "Forbidden"

class xsp.SocketsClient
	socket: null
	controller: null
	ip: null

	constructor: (@socket) ->
		@ip = socket.handshake.headers['x-forwarded-for'] ? socket.handshake.address.address
		
		@socket.on 'disconnect', =>
			socketController.clients.splice socketController.clients.indexOf(@), 1
			socketController.disconnected @

class xsp.SocketsController
	io: null
	clients: null
	
	constructor: (@io) ->
		@clients = []
		@io.sockets.on 'connection', (socket) =>
			client = new socketClient socket
			@clients.push client
			@connected client
	
	connected: (client) ->
		
	
	disconnected: (client) ->

# -----------------------------------

xsp.basicAuth = require './middleware/basicAuth'

xsp.autoload "#{__dirname}/../../../app/helpers", true
xsp.autoload "#{__dirname}/../../../app/models", true
xsp.autoload "#{__dirname}/../../../app/controllers", true

for name, controller of xsp when controller?.prototype instanceof xsp.Controller
	name = name.toLowerCase()
	if name.substr(name.length - 10) is 'controller' then name = name.substr(0, name.length - 10)
	
	for route, fce of controller when route.substr(0, 2) isnt '__'
		controllers["#{name}##{route}"] = fce
		fce.__shortcut = "#{name}##{route}"

for name, controller of xsp when controller?.prototype instanceof xsp.SocketsController
	socketController = controller

for name, client of xsp when client?.prototype instanceof xsp.SocketsClient
	socketClient = client