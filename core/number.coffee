global.Number::digits = (len) ->
	out = this.toString()
	while out.length < len
		out = '0'+ out

	out