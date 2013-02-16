global.Point = class Point
	x: 0
	y: 0

	constructor: () ->
		if arguments[0] instanceof Array
			@x = arguments[0][0]
			@y = arguments[0][1]
		
		else if arguments.length is 2
			@x = arguments[0]
			@y = arguments[1]
			
global.Rectangle = class Rectangle
	x: 0
	y: 0
	width: 0
	height: 0