global.Array::inflection = (count) ->
	index = xsp.localization.INFLECTION_PATTERN[Math.min(Math.abs(count), xsp.localization.INFLECTION_PATTERN.length - 1)]
	@[index].format({count: count});
	
global.Array::clear = () ->
	@.splice 0, @.length
	
global.Array::contains = (obj) ->
	@.indexOf obj isnt -1