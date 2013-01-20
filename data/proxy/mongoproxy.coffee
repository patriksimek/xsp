Db = require('mongodb').Db
Server = require('mongodb').Server
ObjectID = require('mongodb').ObjectID
EventEmitter = require('events').EventEmitter

global.MongoConnection = class MongoConnection extends EventEmitter
	connection: null
	connected: false
	reconnect: true
	
	constructor: () ->
		if arguments.length then @open.apply this, arguments

	open: (ip, port, database) ->
		if @connection then @close()

		@connection = new Db database, new Server(ip, port, {auto_reconnect: true}, {}), 
			w: 0
			native_parser: true

		fce = () =>
			@connection.open (err) =>
				if err
					@emit 'error', err
					if @reconnect
						setTimeout () ->
							trace "reconnecting"
							fce()
						, 1000
				
				else
					@connected = true
					@emit 'connected', err
				
		@connection.on 'close', () =>
			@connected = false
			@emit 'disconnected'
			if @reconnect
				setTimeout () ->
					trace "reconnecting"
					fce()
				, 1000
				
		fce()
	
	close: ->
		unless @connection then return
		
		@reconnect = false
		@connection.close()
		@connection = null
		@connected = false

global.MongoProxy = class MongoProxy extends Proxy
	model: Record
	store: null
	connection: null
	parameters: null
	model: null
	report: true
	
	constructor: ->
		super

		@parameters = []
	
	append: (value) ->
		if value instanceof Model
			document = MongoProxy.serialize value
			@parameters.push document
		
		else
			@parameters.push value
	
	###@serialize: (model) ->
		doc = {}
		for name, item of model.constructor.fields
			if item.save
				if item.save.as
					doc[item.save.as] = model[name]
				
				else
					doc[name] = model[name]
				
		doc###
	
	execute: (callback) ->
		unless @connection
			return process.nextTick () ->
				trace.red "[mdb] Connection is not set!"
				callback? 'Connection is not set!'
				
		unless @connection instanceof MongoConnection
			return process.nextTick () ->
				trace.red "[mdb] Invalid connection!"
				callback? 'Invalid connection!'
				
		unless @connection.connected
			return process.nextTick () ->
				trace.red "[mdb] Connection is not connected!"
				callback? 'Connection is not connected!'
				
		unless MongoProcedures[@procedure]
			return process.nextTick () ->
				trace.red "[mdb] Procedure #{@procedure} doesn\'t exist!"
				callback? 'Procedure #{@procedure} doesn\'t exist!'
				
		if @report 
			trace.yellow "[mdb] execute: #{@procedure}"
			trace.yellow "[mdb] input #{i}: #{if typeof p is 'string' then p.crop(50, ' ...') else p}" for p, i in @parameters
			
		context =
			db: @connection.connection
			status: 0
			next: (err, result) ->
				if err
					trace.red "[mdb] #{err}"

				callback? err, context.status, result
		
		MongoProcedures[@procedure].apply context, @parameters
	
	update: (callback) ->
		@execute (err, status, result) =>
			if err
				callback? err, status
				
			else
				if @report 
					trace.yellow "[mdb] recordset ----------------"
					inspect.yellow result
					trace.yellow "[mdb] --------------------------"
					trace.yellow "[mdb] status: #{status}"

				if result
					unless result instanceof Array
						result = [result]
						
					for record in result
						if @model instanceof Model
							item = @model
							model = @model.constructor
						else
							item = new @model
							model = @model
							
						for col, value of record
							if item instanceof Record
								item[col] = value
							else
								@fetch model, item, col, value
						
						if item and @store
							@store.add item

				callback? err, status, result

		true
	
	fetch: (model, item, name, value) ->
		if value instanceof ObjectID then value = value.toHexString()
		super model, item, name, value