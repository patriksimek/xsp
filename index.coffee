require './core/array'
require './core/string'
require './core/math'
require './core/number'
require './core/date'
require './events/eventdispatcher'
require './data/model'
require './data/record'
require './data/store'
require './data/proxy/proxy'
require './data/proxy/mssqlproxy'
require './data/proxy/postgresproxy'
require './forms/formbuilder'
require './email/email'

initialized = false
tobeinitialized = []
dictionary = {menu: {}}
multilang = false

global.xsp = 
	database: {}

	localization: 
		LANGUAGES: []
		DEFAULT_LANGUAGE: 'en'
		INFLECTION_PATTERN: [0, 1, 2, 2, 2, 3]
		
		multiLang: (req, res, next) ->
			req.langs = dictionary.menu
			
			for lang in req.acceptedLanguages
				req.lang = dictionary[lang]
				if req.lang
					break
	
			if not req.lang
				req.lang = dictionary[xsp.localization.DEFAULT_LANGUAGE]
	
			next()

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
					trace.red "[xsp] dictionary \"#{lang}\" not found!"
				
			if xsp.localization.LANGUAGES.length is 0
				trace.red "[xsp] no languages imported!"
				
			unless xsp.localization.LANGUAGES.contains xsp.localization.DEFAULT_LANGUAGE
				trace.red "[xsp] default language \"#{xsp.localization.DEFAULT_LANGUAGE}\" is not imported!"

		for fce in tobeinitialized
			fce () ->
				if tobeinitialized.length is 0
					return
				
				tobeinitialized.splice tobeinitialized.indexOf(fce), 1
				
				if tobeinitialized.length is 0
					initialized = true
					trace.green "[xsp] initialized"
					
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
				when 'db'
					xsp.database.connection = value
		catch ex
			trace.red "[xsp] config: invalid value for parameter \"#{name}\"!"
			
	init: (fce) ->
		tobeinitialized.push fce

global.trace = (msg) ->
	console.log msg
	
require './core/colors'