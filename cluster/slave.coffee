EventEmitter = require('events').EventEmitter

class Slave extends EventEmitter
	process: null
	client: null
	
	_calls: null
	_counter: 0
	_timeout: null

	constructor: (script, next) ->
		@_calls = {}
		@client = {}
		@_timeout = setTimeout () =>
			@process.removeAllListeners()
			@process.kill()
			@emit 'timeout', null
		, 10000
		
		@process = require('child_process').fork script
		@process.on 'message', (msg) =>
			switch msg.type
				when 'online'
					clearTimeout @_timeout
					@_timeout = null
					
					next?(null, @)
					@emit 'online', null
				
				when 'message'
					@emit 'message', msg.msg
				
				when 'rpc'
					if @client[msg.procedure]
						msg.args.push () =>
							@process.send
								id: msg.id
								type: 'rpcr'
								result: i for i in arguments
							
						@client[msg.procedure].apply @, msg.args
					
					else
						@process.send
							id: msg.id
							type: 'rpcr'
							error: 'Procedure not found.'
							
				when 'rpcr'
					rp = @_calls[msg.id]
					if rp
						delete @_calls[msg.id]
						rp.callback?.apply @, msg.result
	
	send: (msg) ->
		@process.send
			type: 'message'
			msg: msg
	
	call: (procedure, args, callback) ->
		id = @_counter++
		@_calls[id] =
			id: id
			procedure: procedure
			args: args
			callback: callback
			
		@process.send
			id: id
			type: 'rpc'
			procedure: procedure
			args: args
			
module.exports = Slave