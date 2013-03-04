global.FormBuilder = class FormBuilder
	prefix: 'fb_'
	action: ''
	submited: false
	ajax: false
	multipart: false
	last: null

	constructor: (@name) ->
		@fields = new Store
		@buttons = new Store
		
	from: (model, fields...) ->
		unless model instanceof Model
			return @
		
		values = model
		model = model.constructor
		
		if fields.length
			for name in fields
				cfg = model.fields[name];
				if cfg && cfg.form
					f = new FormBuilderField().from(cfg.form)
					f.name = name
					if values then f.value = values[name]
					@add f

		else
			for name, cfg of model.fields when cfg.form
				f = new FormBuilderField().from(cfg.form)
				f.name = name
				if values then f.value = values[name]
				@add f
			
		@
		
	init: (req) ->
		@submited = Number(req.body.formbuilder) is 1
	
		if @submited
			for field in @fields.data
				switch field.type
					when FormBuilderField.CHECKBOX
						field.checked = if req.body[field.name] then true else false
						
					else
						field.value = req.body[field.name]
			
		@
		
	into: (instance) ->
		unless instance instanceof Model 
			return @
			
		model = instance.constructor
		
		for field in @fields.data when model.fields[field.name].form
			instance[field.name] = field.value
			
		@
		
	labels: (dict) ->
		for field in @fields.data
			unless field.label then field.label = "#{dict[field.name]}:"
			
		for button in @buttons.data
			unless button.label then button.label = dict[button.name]
			
		@

	add: (field) ->
		field.owner = @
		
		if field instanceof FormBuilderField
			@fields.add field
			if field.type is FormBuilderField.FILE
				@multipart = true
			
		else if field instanceof FormBuilderButton
			@buttons.add field
			
		@last = field
		
	remove: (field) ->
		if typeof field is 'string'
			field = @field field
			
			unless field
				field = @button field
			
		if field instanceof FormBuilderField
			@fields.remove field
			
		else if field instanceof FormBuilderButton
			@buttons.remove field
	
	generate: (fieldsonly) ->
		buffer = []
		enctype = if @multipart then " enctype=\"multipart/form-data\"" else ""
		
		groups = {}
		groupsc = 0
		for field in @fields.data
			if field.group 
				groupsc++
				if field.group.substr(0, 1) is '#'
					field.groupController = field.group.substr 1
					unless groups[undefined] then groups[undefined] = []
					groups[undefined].push field
				
				else
					unless groups[field.group] then groups[field.group] = []
					groups[field.group].push field
			
			else
				unless groups[undefined] then groups[undefined] = []
				groups[undefined].push field
		
		unless fieldsonly then buffer.push "<form id=\"#{@prefix}form\" method=\"post\" action=\"#{@action}\" class=\"formbuilder#{if @ajax then ' ajax' else ''}\" data-validate=\"#{if @ajax then 'formbuilder' else 'parsley'}\"#{enctype}><fieldset class=\"#{@name}#{if groupsc then ' groups' else ''}\"><input type=\"hidden\" name=\"formbuilder\" value=\"1\" />"

		if groupsc
			for name, group of groups
				if name is 'undefined'
					for field in group
						buffer.push field.generate()
						
				else
					buffer.push "<div class=\"group #{name}\">"
					for field in group
						buffer.push field.generate()
					buffer.push "</div>"
			
		else
			for field in @fields.data
				buffer.push field.generate()
			
		for button in @buttons.data
			buffer.push button.generate()

		unless fieldsonly then buffer.push "</fieldset></form>"
		
		buffer.join ''
		
	field: (name) ->
		for item in @fields.data when item.name is name
			return item
			
		null
	
	button: (name) ->
		for item in @buttons.data when item.name is name
			return item
			
		null

global.FormBuilderField = class FormBuilderField
	visible: true
	rows: 5
	
	constructor: (type) ->
		@type = type ? FormBuilderField.TEXTFIELD
		@on = {}
		@options = []
	
	from: (cfg) ->
		for name, item of cfg
			@[name] = item

		if @options instanceof Function
			@options = @options()
			
		@
		
	generate: ->
		buffer = ""
		
		unless @visible
			return buffer
		
		if @type != FormBuilderField.HIDDEN
			buffer += "<label for=\"#{@owner.prefix}#{@name}\">#{@label ? @name}#{if @required then ' <span class="required">*</span>' else ''}</label>"
		
		value = if @value then " value=\"#{String(@value)}\"" else ""
		readonly = if @readonly then " disabled=\"disabled\"" else ""
		
		switch @type
			when FormBuilderField.HIDDEN
				buffer += "<input type=\"hidden\" name=\"#{@name}\" id=\"#{@owner.prefix}#{@name}\"#{value}#{readonly}#{@events()}#{@validations()}>"
				
			when FormBuilderField.TEXTFIELD
				buffer += "<input type=\"text\" name=\"#{@name}\" id=\"#{@owner.prefix}#{@name}\"#{value}#{readonly}#{@events()}#{@validations()}>"
			
			when FormBuilderField.TEXTAREA
				buffer += "<textarea name=\"#{@name}\" rows=\"#{@rows}\" id=\"#{@owner.prefix}#{@name}\"#{readonly}#{@events()}#{@validations()}>#{if @value then String(@value) else ''}</textarea>"
			
			when FormBuilderField.FILE
				buffer += "<input type=\"file\" name=\"#{@name}\" id=\"#{@owner.prefix}#{@name}\"#{value}#{readonly}#{@events()}#{@validations()}>"
			
			when FormBuilderField.PASSWORD
				buffer += "<input type=\"password\" name=\"#{@name}\" id=\"#{@owner.prefix}#{@name}\"#{value}#{readonly}#{@events()}#{@validations()}>"
			
			when FormBuilderField.CHECKBOX
				buffer += "<input type=\"checkbox\" name=\"#{@name}\" id=\"#{@owner.prefix}#{@name}\" value=\"#{@value ? 'on'}\""
				if @checked then buffer += " checked=\"checked\""
				buffer += "#{readonly}#{@events()}#{@validations()}>"
				
			when FormBuilderField.SELECT
				if @groupController
					buffer += "<select name=\"#{@name}\" id=\"#{@owner.prefix}#{@name}\" class=\"groupctrl\" data-group=\"#{@groupController}\"#{readonly}#{@events()}#{@validations()}>"
				
				else
					buffer += "<select name=\"#{@name}\" id=\"#{@owner.prefix}#{@name}\"#{readonly}#{@events()}#{@validations()}>"
				
				groups = {}
				for option in @options
					unless groups[option.group] then groups[option.group] = []
					groups[option.group].push option
				
				for name, group of groups
					if name isnt 'undefined'
						buffer += "<optgroup label=\"#{name}\">"
					
					for option in group
						checked = if String(option.value) is String(@value) then " selected=\"selected\"" else ""
						buffer += "<option value=\"#{String(option.value)}\"#{checked}>#{option.label}</option>"
					
					if name isnt 'undefined'
						buffer += "</optgroup>"
				
				buffer += "</select>"
				
		buffer
	
	validations: ->
		out = []
		
		if @validate
			for name, value of @validate
				out.push "data-#{name}=\"#{value}\""
		
		if @required
			out.push "data-required=\"true\""
		
		" #{out.join(' ')}"
		
	events: ->
		unless @on
			return
			
		out = []
		for name, value of @on
			out.push "on#{name}=\"#{value}\""
			
		" #{out.join(' ')}"
		
	move: (index) ->
		@owner.fields.data.splice @owner.fields.data.indexOf(@), 1
		@owner.fields.data.splice index, 0, @
	
	@HIDDEN: 'hidden'
	@TEXTFIELD: 'text'
	@TEXTAREA: 'textarea'
	@CHECKBOX: 'checkbox'
	@SELECT: 'select'
	@PASSWORD: 'password'
	@FILE: 'file'
		
global.FormBuilderButton = class FormBuilderButton
	constructor: (type) ->
		@type = type ? FormBuilderField.BUTTON
		
	from: (cfg) ->
		if cfg.type then @type = cfg.type
		if cfg.name then @name = cfg.name
		if cfg.label then @label = cfg.label
		if cfg.on then @on = cfg.on
		@
	
	generate: ->
		buffer = ""
		
		switch @type
			when FormBuilderButton.BUTTON
				buffer += "<input type=\"button\" name=\"#{@name}\" value=\"#{@label}\"#{@events()}>"
				
			when FormBuilderButton.SUBMIT
				buffer += "<input type=\"submit\" name=\"#{@name}\" value=\"#{@label}\"#{@events()}>"
				
		buffer
	
	events: ->
		unless @on
			return ''
			
		out = []
		for name, value of @on
			out.push "on#{name}=\"#{value}\""
			
		" #{out.join(' ')}"
	
	@BUTTON = 'button'
	@SUBMIT = 'submit'