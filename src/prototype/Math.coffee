decimalAdjust = (type, value, exp) ->
	if exp is undefined or +exp is 0
		return Math[type] value
		
	value = +value
	exp = +exp
	
	if isNaN(value) or not (typeof exp is 'number' and exp % 1 is 0)
		return NaN
		
	value = value.toString().split 'e'
	value = Math[type](+(value[0] + 'e' + (if value[1] then (+value[1] - exp) else -exp)))
	
	value = value.toString().split 'e'
	return +(value[0] + 'e' + (if value[1] then (+value[1] + exp) else exp))
	
__round = Math.round
Math.round = (value, decimal) ->
	if decimal
		return decimalAdjust 'round', value, decimal * -1
		
	else
		return __round(value)

__floor = Math.floor
Math.floor = (value, decimal) ->
	if decimal
		return decimalAdjust 'floor', value, decimal * -1
		
	else
		return __floor(value)
		
__ceil = Math.ceil
Math.ceil = (value, decimal) ->
	if decimal
		return decimalAdjust 'ceil', value, decimal * -1
		
	else
		return __ceil(value)