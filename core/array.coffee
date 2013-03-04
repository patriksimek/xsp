Object.defineProperty Array.prototype, 'inflection',
	value: (count) ->
		index = xsp.localization.INFLECTION_PATTERN[Math.min(Math.abs(count), xsp.localization.INFLECTION_PATTERN.length - 1)]
		@[index].format({count: count});
		
	enumerable: false
	
Object.defineProperty Array.prototype, 'clear',
	value: () ->
		@.splice 0, @.length
		
	enumerable: false

Object.defineProperty Array.prototype, 'contains',
	value: (obj) ->
		@.indexOf obj isnt -1
		
	enumerable: false
	
Object.defineProperty Array.prototype, 'uniquify',
	value: () ->
		u = {}
		i = @.length
		while i > -1
			if u[@[i]]
				@.splice i, 1
			else
				u[@[i]] = true
			
			i--
			
		@
		
	enumerable: false