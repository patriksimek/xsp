cluster = require 'cluster'
os = require 'os'

require './core/object'
require './core/array'
require './core/string'
require './core/math'
require './core/number'
require './core/date'
require './core/geometry'
require './core/geography'
require './data/model'
require './data/record'
require './data/store'

global.Scheduler = require('ctask').Scheduler
global.Job = require('ctask').Job

Scheduler.locked = true

initialized = false
tobeinitialized = []
dictionary = {}
multilang = false
langcookie = 'language'
initializedfce = null
schedules = []

global.xsp = 
	database: {}
	email: {}
	workers: 0

	localization: 
		LANGUAGES: []
		DEFAULT_LANGUAGE: 'en'
		INFLECTION_PATTERN: [0, 1, 2, 2, 2, 3]
		JAVASCRIPT_PATTERN: null
		
		multiLang: (req, res, next) ->
			req.langs = dictionary
			
			if req.cookies?[langcookie]
				req.lang = dictionary[req.cookies[langcookie]]
			
			unless req.lang
				for lang in req.acceptedLanguages
					req.lang = dictionary[lang]
					if req.lang
						break
	
			unless req.lang
				req.lang = dictionary[xsp.localization.DEFAULT_LANGUAGE]
	
			next()
			
		toJSON: (dictionary, pattern, output) ->
			unless output then output = {}
			
			for name, value of pattern
				if value is true
					output[name] = dictionary[name]
					
				else
					if dictionary[name]
						output[name] = {}
						xsp.localization.toJSON dictionary[name], value, output[name]
						
			output

	main: (req, res, next) ->
		res.setHeader 'X-Powered-By', "xsp"

		unless initialized
			res.status = 503
			res.end "Web server is initializing, try again later..."
			
		else
			if multilang
				xsp.localization.multiLang req, res, next
				
			else
				next()
	
	configure: (config) ->
		config?()
		
		if multilang
			for lang in xsp.localization.LANGUAGES
				try
					require("../../langs/#{lang}")(dictionary)
				catch ex
					if ex?.code is 'MODULE_NOT_FOUND'
						trace.red "[xsp] dictionary \"#{lang}\" not found!"
						
					else
						trace.red "[xsp] can\'t load dictionary \"#{lang}\"!"
						trace.red ex
				
			if xsp.localization.LANGUAGES.length is 0
				trace.red "[xsp] no languages imported!"
				
			unless xsp.localization.LANGUAGES.contains xsp.localization.DEFAULT_LANGUAGE
				trace.red "[xsp] default language \"#{xsp.localization.DEFAULT_LANGUAGE}\" is not imported!"

		if tobeinitialized.length
			for fce in tobeinitialized
				fce () ->
					if initialized then return
					
					if tobeinitialized.length is 0
						return
					
					tobeinitialized.splice tobeinitialized.indexOf(fce), 1
					
					if tobeinitialized.length is 0
						initialized = true
						trace.green "[xsp] initialized"
						
						Scheduler.locked = false
						
						if initializedfce then process.nextTick initializedfce
		else
			initialized = true
			trace.green "[xsp] initialized"
			
			Scheduler.locked = false
			
			if initializedfce then process.nextTick initializedfce
		
	set: (name, value) ->
		try
			switch name
				when 'app'
					xsp.app = value
				when 'langs'
					xsp.localization.LANGUAGES = value.split ','
				when 'lang'
					xsp.localization.DEFAULT_LANGUAGE = value
				when 'multilang'
					multilang = value
				when 'langcookie'
					langcookie = value
				when 'db'
					xsp.database.connection = value
				when 'email'
					xsp.email.connection = value
				when 'initialized'
					initializedfce = value
					
		catch ex
			trace.red "[xsp] config: invalid value for parameter \"#{name}\"!"
	
	init: (fce) ->
		tobeinitialized.push fce

	multicore: (cores, fce, fce2) ->
		supported = true
		
		if os.platform() is 'win32'
			supported = false
			
		if cores < 2
			supported = false
		
		if cluster.isMaster and supported
			trace.magenta "- [xsp] master (pid: #{process.pid})"
			cluster.on 'fork', (worker) ->
				trace.magenta "[xsp] worker #{worker.id} created (pid: #{worker.process.pid})"
		
			for i in new Array cores
				cluster.fork()
				xsp.workers++
				
			fce true, false
			
		else
			fce supported, cluster.isWorker
			
	logger: (req, res, next) ->
		startTime = new Date
		
		##trace.grey "[xsp] #{xsp.colors.grey}#{req.method} #{req.originalUrl}#{xsp.colors.def}"

		end = res.end
		res.end = (chunk, encoding) ->
			res.end = end
			res.end chunk, encoding
			
			color = xsp.colors.green
			if res.statusCode >= 500 then color = xsp.colors.red
			else if res.statusCode >= 400 then color = xsp.colors.yellow
			else if res.statusCode >= 300 then color = xsp.colors.cyan
			
			trace.grey "[xsp] #{xsp.colors.grey}#{req.method} #{req.originalUrl} #{color}#{res.statusCode}#{xsp.colors.grey} #{new Date - startTime}ms#{xsp.colors.def}"
			
		next()
		
	schedule: (opts) ->
		return new Job(opts).start()
	
	use: (module) ->
		try
			require __dirname + "/#{module.replace /\./g, '\/'}"
			
		catch ex
			if ex?.code is 'MODULE_NOT_FOUND'
				trace.red "[xsp] module \"#{module}\" not found!"
			
			else
				trace.red "[xsp] can\'t load module: #{module}"
				trace.red ex
	
global.trace = (msg) ->
	console.log trace.process() + msg
	
global.inspect = (obj) ->
	console.dir obj
	
require './core/colors'