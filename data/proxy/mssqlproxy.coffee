http = require 'http'

global.MSSQLConnection = class MSSQLConnection
	constructor: (@ip, @port, @path) ->

	open: ->

	query: (sql, callback) ->
		data = 'request='+ encodeURIComponent(JSON.stringify(sql))
	
		options =
			host: @ip
			port: @port
			path: @path
			method: 'POST'
			headers:
				'Content-Type': 'application/x-www-form-urlencoded'
				'Content-Length': data.length
	
		request = http.request options, (res) ->
			res.setEncoding 'utf8'
			
			buffer = ''
			res.on 'data', (chunk) ->
				buffer += chunk
				
			res.on 'end', () ->
				try
					response = JSON.parse buffer
				catch ex
					trace 'Response ----'
					trace buffer
					response = 
						error: 'Response parsing failed.'

				callback? response

		request.on 'error', (err) ->
			console.log "ERROR"
			response = 
				error: 'Transport failed.'
				
			callback? response
	
		request.write data
		request.end()
	
	close: ->

global.MSSQLProxy = class MSSQLProxy extends Proxy
	model: Record
	store: null
	connection: null
	parameters: null
	model: null
	report: true
	
	constructor: ->
		super

		@parameters = []
	
	append: (name, type, io, bit, value) ->
		if type == MSSQLProxy.DATETIME and value
			value = value.getTime()
	
		@parameters.push
			name: name
			type: type
			io: io
			bit: bit
			value: value
		
	execute: (callback) ->
		unless @connection then return false
		unless @connection instanceof MSSQLConnection then return false
		
		if @report 
			trace "MSSQL Execute: #{@procedure}"
			trace "MSSQL Input #{p.name}: #{p.value}" for p in @parameters

		status = 0
		error = null
		
		@connection.query {
			procedure: @procedure
			input: @parameters
		}, (res) =>
			if res.error
				if @report then trace "MSSQL Error: #{res.error}"
				callback? -9999, res.error
				
			else
				status = res['return'];
				
				if @report 
					trace "MSSQL Status: #{status}"
				
				callback? status

		true

	update: (callback) ->
		unless @connection then return false
		unless @connection instanceof MSSQLConnection then return false
		
		if @report 
			trace "MSSQL Update: #{@procedure}"
			trace "MSSQL Input #{p.name}: #{p.value}" for p in @parameters
			
		status = 0
		error = null
		
		@connection.query {
			procedure: @procedure
			input: @parameters
		}, (res) =>
			if res.error
				if @report then trace "MSSQL Error: #{res.error}"
				callback? -9999, res.error
				
			else
				status = res['return'];
				
				if @report 
					##trace "MSSQL Recordset ----------------"
					##trace res.recordsets[0]
					##trace "--------------------------------"
					trace "MSSQL Status: #{status}"
					trace "MSSQL Recordsets: #{res.recordsets.length}"

				if res.recordsets.length
					if @report
						trace "MSSQL Recordset 1: #{res.recordsets[0].length} rows"
						
					for result in res.recordsets[0]
						if @model instanceof Model
							item = @model
							model = @model.constructor
						else
							item = new @model
							model = @model
							
						for col, value of result
							if item instanceof Record
								item[col] = value
							else
								@fetch model, item, col, value
						
						if item and @store
							@store.add item

				callback? status

		true
		
	@INPUT = 1
	@OUTPUT = 2
	
	@INTEGER = 3
	@VARCHAR = 200
	@DATETIME = 135
	@DECIMAL = 5