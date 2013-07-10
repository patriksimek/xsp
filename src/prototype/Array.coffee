Object.defineProperty Array.prototype, 'clone',
	value: (sort) ->
		@slice()
		
	enumerable: false

Object.defineProperty Array.prototype, 'first',
	value: ->
		@[0]
		
	enumerable: false

Object.defineProperty Array.prototype, 'last',
	value: ->
		@[@.length - 1]
		
	enumerable: false
	
Object.defineProperty Array.prototype, 'union',
	value: (sort) ->
		if @length < 2
			return @
		
		queries = @clone()
		first = queries.shift()
		out = first.concat.apply first, queries
		
		if sort
			asc = true
			
			if sort.substr(0, 1) is '-'
				asc = false
				sort = sort.substr(1)
				
			out.sort (a, b) ->
				if asc
					return a[sort] - b[sort]
				
				else
					return b[sort] - a[sort]
					
			return out
		
		else
			return out

	enumerable: false

Object.defineProperty Array.prototype, 'groupBy',
	value: (prop) ->
		groups = {}
		
		for item in @
			unless groups[item[prop]]
				groups[item[prop]] = []
				
			groups[item[prop]].push item
		
		groups

	enumerable: false

__filter = Array.prototype.filter
Object.defineProperty Array.prototype, 'filter',
	value: (callback, thisObject) ->
		if typeof callback is 'function'
			return __filter.call @, callback, thisObject
			
		else
			return __filter.call @, (element, index, array) ->
				for name, value of callback
					if element[name] isnt value
						return false
				
				true

	enumerable: false