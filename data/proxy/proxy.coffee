global.Proxy = class Proxy
	fetch: (model, item, name, value) ->
		if model.aliases and model.aliases[name]
			name = model.aliases[name]

		desc = model.fields[name]
		if desc
			switch desc.type
				when 'date'
					switch desc.format
						when 'unix'
							item[name] = new Date(value * 1000)
						
						else
							item[name] = new Date(value)
					
				when 'number'
					item[name] = Number(value)
					
				when 'boolean'
					item[name] = Boolean(value)
					
				when 'bounds'
					item[name] = new Bounds(new Coordinate(value[0]), new Coordinate(value[1]))
				
				when 'coordinate'
					item[name] = new Coordinate value
					
				when 'json'
					try
						item[name] = JSON.parse value
					catch ex
						item[name] = value
				
				else
					item[name] = value
					
	serialize: (value) ->
		if value instanceof Model
			document = MongoProxy.serialize value
			@parameters.push document
		
		else if value instanceof Coordinate
			return [value.longitude, value.latitude]
			
		else if value instanceof Point
			return [value.x, value.y]
			
		else if value instanceof Bounds
			return [@serialize(value.sw()), @serialize(value.ne())]
			
		else
			return value