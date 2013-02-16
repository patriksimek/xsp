xsp.use 'data.proxy.proxy'

global.PostgresConnection = class PostgresConnection
	@connection: null
	
	constructor: () ->
		if arguments.length then @open.apply this, arguments
		
	open: (ip, port, user, password, database) ->
		if @connection then @close()
		
		pg = require 'pg'
		@connection = new pg.Client("tcp://#{user}:#{password}@#{ip}:#{port}/#{database}")
		@connection.connect()
	
	close: ->
		unless @connection then return
		
		@connection.end()
		@connection = null

global.PostgresProxy = class PostgresProxy extends Proxy
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
		@parameters.push value
		
	execute: (callback) ->
		unless @connection
			return process.nextTick () ->
				callback? 'Connection is not set!'
				
		unless @connection instanceof PostgresConnection
			return process.nextTick () ->
				callback? 'Invalid connection!'
		
		if @report 
			trace.yellow "[pgp] execute: #{@procedure}"
			trace.yellow "[pgp] input #{i}: #{p}" for p, i in @parameters
			
		query = @connection.connection.query "select * from #{@procedure} (#{'$'+ (i + 1) for p, i in @parameters})", @parameters
		recordset = []
		status = 0
		error = null
		
		query.on 'row', (result) =>
			recordset.push result
			
			if result.xresult
				status = result.xresult
			
			if @report 
				trace.yellow "[pgp] recordset ----------------"
				inspect.yellow result
				trace.yellow "[pgp] --------------------------"

		query.on 'error', (err) =>
			if @report then trace.red "[pgp] #{err}"
			error = err

		query.on 'end', () =>
			if @report then trace.yellow "[pgp] status: #{status}"
			@connection.close()
			
			if error
				callback? error
			else
				callback? null, status, recordset

		true

	update: (callback) ->
		unless @connection
			return process.nextTick () ->
				callback? 'Connection is not set!'
				
		unless @connection instanceof PostgresConnection
			return process.nextTick () ->
				callback? 'Invalid connection!'
		
		if @report 
			trace.yellow "[pgp] update: #{@procedure}"
			trace.yellow "[pgp] input #{i}: #{p}" for p, i in @parameters
			
		query = @connection.connection.query "select * from #{@procedure} (#{'$'+ (i + 1) for p, i in @parameters})", @parameters
		recordset = []
		status = 0
		error = null
		
		query.on 'row', (result) =>
			recordset.push result
			
			if result.xresult
				status = result.xresult
			
			if @report 
				trace.yellow "[pgp] recordset ----------------"
				inspect.yellow result
				trace.yellow "[pgp] --------------------------"

			if @model instanceof Model
				item = @model
				model = @model.constructor
			else
				item = new @model
				model = @model
			
			for col, value of result when col isnt 'xresult'
				if item instanceof Record
					item[col] = value
				else
					@fetch model, item, col, value
			
			if item and @store
				@store.add item

		query.on 'error', (err) =>
			if @report then trace.red "[pgp]  #{err}"
			error = err

		query.on 'end', () =>
			if @report then trace.yellow "[pgp] status: #{status}"
			@connection.close()
			
			if error
				callback? error
			else
				callback? null, status, recordset

		true