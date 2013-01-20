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
				
				else
					item[name] = value