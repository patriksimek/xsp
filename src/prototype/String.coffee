global.String::multiply = (count, separator) ->
	out = ''
	while i < count
		if out.length > 0 and separator
			out += separator
			
		out += @
		
	out

global.String::format = (data) ->
	@replace new RegExp('{([^}]*)}', 'g'), (p) ->
		r = p.substr 1, p.length - 2
		data[r] ? ''

global.String::crop = (length, add) ->
	if @length > length
		@substr(0, length) + (add ? '')
		
	else
		@
		
global.String::inject = (index, text) ->
	@substr(0, index) + text + @substr(index)
	
global.String::escape = ->
	@.replace(/&(?!\w+;)/g, '&amp;')
	.replace(/</g, '&lt;')
	.replace(/>/g, '&gt;')
	.replace(/"/g, '&quot;')