fixed = (str, len, app = ' ') ->
	str = String str
	
	while str.length < len
		str += app
		
	str

module.exports = (app) ->
	c1 = 'Path'.length
	c2 = 'Controller'.length
	
	routes = app.routes.get.concat(app.routes.post)
	
	for route in routes
		c1 = Math.max c1, route.path?.length ? 0
		c2 = Math.max c2, route.controller?.length ? 0
		
	cl = c1 + c2 + 3
		
	trace "[xsp] Routes #{fixed('', cl - 13, '-')}"
	trace.yellow "#{fixed('Path', c1)}   #{fixed('Controller', c1)}"
	trace.yellow "#{fixed('', cl, '-')}"
		
	for route in routes
		trace.yellow "#{fixed(route.path, c1)}   #{fixed(route.controller, 2)}"