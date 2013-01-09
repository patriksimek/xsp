pg = require 'pg'

global.PostgresConnection = class PostgresConnection
	@connection: null
	
	constructor: (ip, port, user, password, database) ->
		if ip then @open.apply this, arguments
		
	open: (ip, port, user, password, database) ->
		if @connection then @close()
		
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
		unless @connection then return false
		unless @connection instanceof PostgresConnection then return false
		
		if @report 
			trace "PGP Execute: #{@procedure}", 'grey'
			trace "PGP Input #{i}: #{p}" for p, i in @parameters
			
		query = @connection.connection.query "select * from #{@procedure} (#{'$'+ (i + 1) for p, i in @parameters})", @parameters
		status = 0
		error = null
		
		query.on 'row', (result) =>
			if @report 
				trace "PGP Row ------------------------", 'grey'
				trace result
				trace "--------------------------------", 'grey'
				
			if result.xresult
				status = result.xresult

		query.on 'error', (err) =>
			if @report then trace "PGP Error: #{err}", 'red'
			error = err

		query.on 'end', () =>
			if @report then trace "PGP Status: #{status}", 'grey'
			@connection.close()
			
			if error
				callback? -9999, error
			else
				callback? status

		true

	update: (callback) ->
		unless @connection then return false
		unless @connection instanceof PostgresConnection then return false
		
		if @report 
			trace "PGP Update: #{@procedure}", 'grey'
			trace "PGP Input #{i}: #{p}" for p, i in @parameters
			
		query = @connection.connection.query "select * from #{@procedure} (#{'$'+ (i + 1) for p, i in @parameters})", @parameters
		output = 'load'
		status = 0
		error = null
		
		query.on 'row', (result) =>
			if @report 
				trace "PGP Row ------------------------", 'grey'
				trace result
				trace "--------------------------------", 'grey'
		
			if result.xresult
				status = result.xresult
			
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
			if @report then trace "PGP Error: #{error}", 'red'
			error = err

		query.on 'end', () =>
			if @report then trace "PGP Status: #{status}", 'grey'
			@connection.close()
			
			if error
				callback? -9999, error
			else
				callback? status

		true