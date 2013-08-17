# Function.property 'test', {get: ..., set: ...} - set property
# Function.property 'test', -> {get: ..., set: ...} - set property
# Function.property 'test' - return get property descriptor
Object.defineProperty Function::, 'property',
	value: (prop, desc) ->
		if desc
			if desc instanceof Function then desc = desc()
			if @__super__
				c = @__super__
				while c
					sup = Object.getOwnPropertyDescriptor(c, prop)
					if sup then break
					c = c.constructor.__super__
	
				if sup
					# we are overriding property
					desc.configurable ?= sup.configurable
					desc.enumerable ?= sup.enumerable
					desc.get ?= sup.get
					desc.set ?= sup.set
		
			Object.defineProperty @prototype, prop, desc
		
		else
			Object.getOwnPropertyDescriptor(@, prop)
		
	enumerable: false

Object.defineProperty Function::, 'noop',
	value: ->