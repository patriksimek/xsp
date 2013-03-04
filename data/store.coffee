global.Store = class Store
	@from: ->
		new Store

	first: null
	last: null
	data: null
	position: 0
	proxy: null
	reader: null
	model: null
	eof: true
	count: 0
	
	constructor: ->
		@data = new Array
		
	add: (item) ->
		if @data.length is 0
			@first = item
			
		@last = item
		@eof = false
		@data.push item
		@count++
		
		@
		
	remove: (item) ->
		index = @data.indexOf item
		
		if index isnt -1
			@data.splice index, 1
	
	load: (callback) ->
		if !@proxy
			return callback 'No proxy defined.'

		@proxy.model = @model
		@proxy.store = @
		
		@proxy.update callback
	
	move: (index) ->
		@position = index ? 0
		@eof = @position >= @data.length
		
	next: ->
		@data[++@position]
		@eof = @position >= @data.length
	
	raw: ->
		out = []
		for item in @data
			if item instanceof Model
				out.push item.raw arguments...
			else
				out.push item
		
		out
	
	search: (value, prop) ->
		for item, i in @data
			if item[prop] is value
				return item
