global.Model = class Model
	@fields: null
	
	load: (proxy, callback) ->
		if !proxy
			return callback(-9998)

		proxy.model = @
		
		proxy.update callback
		
	raw: ->
		out = {}
		
		if arguments.length
			for prop in arguments
				if @constructor.fields[prop]
					out[prop] = @[prop]
		else
			for prop of @constructor.fields
				out[prop] = @[prop]
			
		out