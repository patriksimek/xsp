global.FormBuilder = class FormBuilder
	prefix: 'fb_'
	action: ''
	submited: false
	ajax: false
	multipart: false

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
					
		for field in @fields.data
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
	
	generate: (fieldsonly) ->
		buffer = ""
		enctype = if @multipart then " enctype=\"multipart/form-data\"" else ""
		
		unless fieldsonly then buffer = "<form id=\"#{@prefix}form\" method=\"post\" action=\"#{@action}\"#{enctype}><fieldset class=\"#{@name}\"><input type=\"hidden\" name=\"formbuilder\" value=\"1\" />"

		for field in @fields.data
			buffer += field.generate()
			
		for button in @buttons.data
			buffer += button.generate()

		validations = []
		for field in @fields.data
			v = field.validations()
			if v then validations.push v
			
		unless fieldsonly then buffer += "</fieldset></form><script type=\"text/javascript\">$(function(){$(\"##{@prefix}form\").validate({rules:{#{validations.join(',')}}})});</script>"
		
		if @ajax and not fieldsonly
			buffer += "<script type=\"text/javascript\">$(function(){$(\"##{@prefix}form\").submit(formbuilder.submit)});</script>"
		
		buffer

global.FormBuilderField = class FormBuilderField
	constructor: (type) ->
		@type = type ? FormBuilderField.TEXTFIELD
		@on = {}
		@options = []
	
	from: (cfg) ->
		if cfg.type then @type = cfg.type
		if cfg.name then @name = cfg.name
		if cfg.label then @label = cfg.label
		if cfg.value then @value = cfg.value
		if cfg.checked then @checked = cfg.checked
		if cfg.validate then @validate = cfg.validate
		if cfg.on then @on = cfg.on

		if cfg.options instanceof Array 
			@options = cfg.options
			
		else if cfg.options instanceof Function
			@options = cfg.options()
			
		@
		
	generate: ->
		buffer = ""
		
		if @type != FormBuilderField.HIDDEN
			buffer += "<label for=\"#{@owner.prefix}#{@name}\">#{@label ? @name}</label>"
		
		value = if @value then " value=\"#{@value}\"" else ""
		
		switch @type
			when FormBuilderField.HIDDEN
				buffer += "<input type=\"hidden\" name=\"#{@name}\" id=\"#{@owner.prefix}#{@name}\"#{value}#{@events()}>"
				
			when FormBuilderField.TEXTFIELD
				buffer += "<input type=\"text\" name=\"#{@name}\" id=\"#{@owner.prefix}#{@name}\"#{value}#{@events()}>"
			
			when FormBuilderField.FILE
				buffer += "<input type=\"file\" name=\"#{@name}\" id=\"#{@owner.prefix}#{@name}\"#{value}#{@events()}>"
			
			when FormBuilderField.PASSWORD
				buffer += "<input type=\"password\" name=\"#{@name}\" id=\"#{@owner.prefix}#{@name}\"#{value}#{@events()}>"
			
			when FormBuilderField.CHECKBOX
				buffer += "<input type=\"checkbox\" name=\"#{@name}\" id=\"#{@owner.prefix}#{@name}\" value=\"on\""
				if @checked then buffer += " checked=\"checked\""
				buffer += "#{@events()}>"
				
			when FormBuilderField.SELECT
				buffer += "<select name=\"#{@name}\" id=\"#{@owner.prefix}#{@name}\"#{@events()}>"
				
				for option in @options
					checked = if option.value == @value then " selected=\"selected\"" else ""
					buffer += "<option value=\"#{option.value}\"#{checked}>#{option.label}</option>"
				
				buffer += "</select>"
				
		buffer
	
	validations: ->
		unless @validate
			return
			
		out = []
		for name, value of @validate
			out.push "#{name}:#{value}"
			
		"#{@name}:{#{out.join(',')}}"
		
	events: ->
		unless @on
			return
			
		out = []
		for name, value of @on
			out.push "on#{name}=\"#{value}\""
			
		" #{out.join(' ')}"
	
	@HIDDEN: 'hidden'
	@TEXTFIELD: 'text'
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