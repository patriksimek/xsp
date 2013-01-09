global.EventDispatcher = class EventDispatcher
	eventHandler: null

	constructor: ->
		@eventHandler = new Object

	addListener: (type, handler, scope) ->
		if @eventHandler[type]
			@eventHandler[type].push({type: type, handler: handler, scope: scope})
		else
			@eventHandler[type] = [{type: type, handler: handler, scope: scope}]
	
	clearListeners: () ->
		@eventHandler = new Object
	
	removeListener: (type, handler) ->
		if @eventHandler[type]
			for e, i in @eventHandler[type]
				if (e.handler == handler)
					@eventHandler[type].splice i--, 1
	
	fireEvent: (type, data...) ->
		event = target: @

		if @eventHandler[type]
			for e, i in @eventHandler[type]
				e.handler.apply e.scope ? @, data
				if event._stopPropagation or event._preventDefault
					break

	on: (event, handler, scope) ->
		@addListener(event, handler, scope)