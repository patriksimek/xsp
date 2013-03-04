Object.defineProperty Object.prototype, 'clone',
	value: () ->
		Object.clone @
		
	enumerable: false

Object.clone = (obj) ->
	if typeof obj is 'object'
		if obj instanceof Array
			a = []
			for item, i in obj
				a[i] = Object.clone item
				
			return a
			
		else if obj instanceof Buffer
			b = new Buffer obj.length
			obj.copy b
			b
		
		else
			o = {}
			for i, item of obj
				o[i] = Object.clone item
				
			return o
	
	else
		return obj