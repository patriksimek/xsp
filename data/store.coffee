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
	
	load: (callback) ->
		if !@proxy
			return callback(-9998)

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
