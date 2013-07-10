Object.defineProperty Number.prototype, 'digits',
	value: (len) ->
		out = this.toString()
		while out.length < len
			out = '0'+ out
	
		out
		
	enumerable: false
	
Object.defineProperty Number.prototype, 'toRad',
	value: () ->
		@ * Math.PI / 180
		
	enumerable: false