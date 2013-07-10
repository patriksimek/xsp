class Task
	###*
	 * Handle to interval uid set by setInterval.
	 * @type {number}
	 * @private
	###
	_handle: null
	
	###*
	 * Internal function.
	 * @type {function}
	 * @private
	###
	_action: null
	
	###*
	 * Indicates if the task is running.
	 * @type {boolean}
	###
	running: false
	
	###*
	 * Task
	 * @constructor
	###
	constructor: (@name, @interval, @action) ->
		@_action = =>
			if @running
				@_report 'warning', 'Task execution skipped because the previous task is already running.'
				return
			
			started = +Date.now()
			@running = true
			@_report 'info', 'Executing task.'
			
			@action (err) =>
				if err
					@_report 'error', err
				
				else
					@_report 'info', "Task completed in #{+Date.now() - started}ms."
					
				@running = false

	###*
	 * Start task.
	 * @param {boolean=} runImmediately Task start immediately if true. False by default.
	###
	start: (runImmediately) ->
		if @_handle then return
		@_handle = setInterval @_action, @interval
		
		if runImmediately
			process.nextTick =>
				@_action()
		
	###*
	 * Stop task.
	###
	stop: ->
		clearInterval @_handle
		@_handle = null
	
	###*
	 * Restart task.
	###
	restart: ->
		@stop()
		@start()
	
	###*
	 * Restart task.
	 * @param {function(err)} callback A function to be called after the execution is done.
	###
	execute: (callback) ->
		@action callback
	
	###*
	 * Report task activity.
	 * @param {string} level Level of message (info, warning, error).
	 * @param {(string|object)} msg String message or Error object.
	 * @private
	###
	_report: (level, msg) ->
		if module.exports.silent
			return
			
		if typeof msg is 'string'
			if level is 'error'
				trace.red "[xsp:task] #{@name}: #{msg}"
			else if level is 'warning'
				trace.yellow "[xsp:task] #{@name}: #{msg}"
			else
				trace.grey "[xsp:task] #{@name}: #{msg}"
			
		else
			if level is 'error'
				trace.red "[xsp:task] #{@name}: #{msg.message}"
			else if level is 'warning'
				trace.yellow "[xsp:task] #{@name}: #{msg.message}"
			else
				trace.grey "[xsp:task] #{@name}: #{msg.message}"
			
###*
 * Array of tasks.
 * @type {Array.<Task>}
###
module.exports.tasks = []

###*
 * No log output if true.
 * @type {boolean}
###
module.exports.silent = true

###*
 * Register a new task.
 * @param {number} interval Repeat interval in milliseconds.
 * @param {function(callback)} action A function to be called in specified interval.
 * @return {Task}
###
module.exports.add = (name, interval, action) ->
	t = new Task name, interval, action
	@tasks.push t
	t

###*
 * Start all registered tasks.
 * @param {boolean=} runImmediately Task start immediately if true. False by default.
###
module.exports.start = (runImmediately) ->
	for task in @tasks
		task.start runImmediately

###*
 * Stop all registered tasks.
###
module.exports.stop = ->
	for task in @tasks
		task.stop()

###*
 * Restart all registered tasks.
###
module.exports.restart = ->
	for task in @tasks
		task.restart()

###*
 * Return task by specified name or null.
 * @param {string} name Name of the task.
###
module.exports.task = (name) ->
	for task in @tasks
		if task.name is name
			return task
			
	null