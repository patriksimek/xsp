global.Coordinate = class Coordinate extends Point
	constructor: () ->
		@__defineGetter__ 'latitude', () ->
			@y
			
		@__defineGetter__ 'longitude', () ->
			@x
			
		if arguments[0] instanceof Array
			@x = arguments[0][0]
			@y = arguments[0][1]
		
		else if arguments.length is 2
			@y = arguments[0]
			@x = arguments[1]
		
	distance: (point) ->
		unless point instanceof Coordinate
			return 0
			
		r = 6371 ## km
		dLat = (point.x - @x).toRad()
		dLon = (point.y - @y).toRad()
		a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.cos(@x.toRad()) * Math.cos(point.x.toRad()) * Math.sin(dLon/2) * Math.sin(dLon/2)
		c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
		return r * c
		
	toString: () ->
		"#{@y},#{@x}"
	
	@fromExif: (lat, lon) ->
		parse = (value) ->
			try
				s = value.split ','
			
				for item, index in s
					c = item.split '/'
					s[index] = parseInt(c[0]) / parseInt(c[1])
					
				s[1] = s[1] / 60
				s[2] = s[2] / 60
				
				return s[0] + s[1] + s[2]
				
			catch ex
				return -1
		
		a = parse lat
		o = parse lon
		
		if a is -1 or o is -1
			return null
		
		else
			return new Coordinate a, o
		
global.Bounds = class Bounds extends Rectangle
	_inited: false
	
	constructor: (sw, ne) ->
		if sw instanceof Coordinate then @extend sw
		if ne instanceof Coordinate then @extend ne
		
	extend: (point) ->
		unless point instanceof Coordinate
			return 0
			
		unless @_inited
			@_inited = true
			@x = point.x
			@y = point.y
			return

		@x = Math.min @x, point.x
		@y = Math.min @y, point.y
		
		@width = Math.max(@x + @width, point.x) - @x
		@height = Math.max(@y + @height, point.y) - @y
		
	sw: () ->
		new Coordinate @y, @x
	
	ne: () ->
		new Coordinate @y + @height, @x + @width
		
	center: () ->
		new Coordinate @y + @height / 2, @x + @width / 2