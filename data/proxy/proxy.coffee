global.Proxy = class Proxy extends EventDispatcher
	fetch: (model, item, name, value) ->
		if model.aliases and model.aliases[name]
			name = model.aliases[name]
		
		desc = model.fields[name]
		if desc
			switch desc.type
				when 'date'
					item[name] = new Date(value)
					
				when 'number'
					item[name] = Number(value)
					
				when 'boolean'
					item[name] = Boolean(value)
				
				else
					item[name] = value