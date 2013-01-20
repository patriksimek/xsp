cluster = require 'cluster'

global.Scheduler = class Scheduler
	@jobs: {}
	@workers: []
	@employed: {}
	@timers: {}
	@locked = false
		
	@attach: (job, reattach) ->
		if @jobs[job.name]
			trace.red "[job] job already exist!"
			return job

		@jobs[job.name] = job

		if job.shared
			if cluster.isMaster
				unless @workers.length
					trace.yellow "[job] no workers for shared jobs, making job \"#{job.name}\" non-shared"
					job.shared = false
					job.makeSharedWhenPossible = true
					
				job._interval = setInterval () =>
					if job.running and not job.multi then return
					if @locked or job.locked or not job.enabled then return
					
					if @workers.length
						worker = @workers.shift()
						@employed[worker.id] = worker
						@timers[worker.id] = new Date().getTime()
						
						if job.report
							trace.cyan "[job] starting \"#{job.name}\" by worker #{worker.id}"

						job.running = true
						if job.locking then job.locked = true

						worker.send
							_node_scheduler:
								action: 'trigger'
								job: job.name
					
				, job.interval
			
		else
			if not cluster.isWorker
				job._interval = setInterval () =>
					if job.running and not job.multi then return
					if @locked or job.locked or not job.enabled then return
					
					if job.report
						trace.cyan "[job] starting \"#{job.name}\""
						
					job.running = true
					if job.locking then job.locked = true
					
					start = new Date().getTime()
					job.action?.call job.context ? @, job, (err) =>
						if job.report
							trace.cyan "[job] \"#{job.name}\" completed in #{new Date().getTime() - start}ms"
							
						@_complete err, job
					
				, job.interval
		
		if job.report and not reattach
			trace.cyan "[job] \"#{job.name}\" attached"
		
		job
	
	@detach: (job) ->
		unless @jobs[job.name]
			return false
	
		if job.running
			trace.yellow "[job] \"#{job.name}\" is running, detaching delayed"
			job.detachWhenPossible = true
			return true
	
		delete @jobs[job.name]
			
		clearInterval job._interval
		job._interval = null
		
		if job.makeShared
			if job.report
				trace.cyan "[job] setting \"#{job.name}\" shared"
				
			process.nextTick () =>
				job.shared = true
				delete job.makeShared
				@attach job, true
		
		else if job.makeNonShared
			if job.report
				trace.cyan "[job] setting \"#{job.name}\" non-shared"
				
			process.nextTick () =>
				job.shared = false
				delete job.makeNonShared
				@attach job, true
		
		else
			if job.report
				trace.cyan "[job] \"#{job.name}\" detached"
			
		## for sure
		delete job.makeSharedWhenPossible
		
		job
		
	@_complete: (err, job) ->
		job.running = false
		job.locked = false
		
		if err
			trace.red "[job] \"#{job.name}\" finshed with error: #{err}"
		
		if job.detachWhenPossible
			delete job.detachWhenPossible
			@detach job

	@_init: () ->
		handler = (msg, worker) =>
			if msg?._node_scheduler
				job = @jobs[msg._node_scheduler.job]
				
				switch msg._node_scheduler.action
					when 'complete'
						if job.report
							trace.cyan "[job] \"#{job.name}\" completed by worker #{worker.id} in #{new Date().getTime() - @timers[worker.id]}ms"

						delete @timers[worker.id]
						delete @employed[worker.id]
						@workers.push worker
						
						@_complete msg._node_scheduler.error, job
						
					when 'unlock'
						if job.report
							trace.cyan "[job] \"#{job.name}\" unlocked by worker #{worker.id}"
							
						job.locked = false
			
		if cluster.isMaster
			for id, worker of cluster.workers
				do (worker) =>
					@workers.push worker
					worker.on 'message', (msg) =>
						handler.call @, msg, worker

			cluster.on 'fork', (worker) =>
				@workers.push worker
				
				for name, job of @jobs when job.makeSharedWhenPossible
					delete job.makeSharedWhenPossible
					job.makeShared = true
					@detach job
				
				worker.on 'message', (msg) =>
					handler.call @, msg, worker
					
			cluster.on 'exit', (worker) =>
				@workers.splice @workers.indexOf(worker), 1
				
				## TODO: Logic about disconnecting a worker that has running task
				
				unless @workers.length
					for name, job of @jobs when job.shared
						job.makeSharedWhenPossible = true
						job.makeNonShared = true
						@detach job
				
		if cluster.isWorker
			process.on 'message', (msg) =>
				if msg?._node_scheduler
					switch msg._node_scheduler.action
						when 'trigger'
							@_trigger msg._node_scheduler.job
	
	@_trigger: (jobname) ->
		job = @jobs[jobname]
		
		unless job
			process.send
				_node_scheduler:
					action: 'complete'
					job: jobname
					error: "Job not found on worker #{cluster.worker.id}"
		
		else
			job.action?.call job.context ? @, job, (err) =>
				process.send
					_node_scheduler:
						action: 'complete'
						job: job.name
						error: err
		
Scheduler._init()
	
global.Job = class Job
	shared: false
	report: false
	multi: false
	action: null
	locking: false
	enabled: true
	
	constructor: (cfg) ->
		for i of cfg
			@[i] = cfg[i]
		
	start: () ->
		Scheduler.attach @
	
	stop: () ->
		Scheduler.detach @
		
	lock: () ->
		if @shared and cluster.isWorker
			process.send
				_node_scheduler:
					action: 'lock'
					job: @name
					
		else
			@locked = true
		
	unlock: () ->
		if @shared and cluster.isWorker
			process.send
				_node_scheduler:
					action: 'unlock'
					job: @name
					
		else
			@locked = false