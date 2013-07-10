__parse = Date.parse
Date.parse = (date, pattern) ->
	unless pattern
		return __parse(date)
	
	else
		re = ''
		f = pattern
		x = []
		
		while f
			i = 1
			c = f.substr 0, 1
			
			if c.charCodeAt(0) is 92
				out += f.substr 1, 1
				f = f.substr Math.min(f.length, 2)
			
			else
				cc = c
				while f.substr(i, 1) is c
					cc += f.substr i, 1
					i++
		
				f = f.substr i
				
				switch cc
					when 'yyyy' then re += '([0-9]{4})'; x.push 'year'
					when 'yyy' then re += '([0-9]{3})'; x.push 'year'
					when 'yy' then re += '([0-9]{2})'; x.push 'year'
					when 'y' then re += '([0-9]{2})'; x.push 'year'
					when 'y' then re += '([0-9]{2})'; x.push 'year'
					when 'mm' then re += '([1-9]|[0-1][0-2])'; x.push 'month'
					when 'm' then re += '([1-9]|[0-1][0-2])'; x.push 'month'
					when 'dd' then re += '([1-9]|[0-2][1-9]|3[0-1])'; x.push 'day'
					when 'd' then re += '([1-9]|[0-2][1-9]|3[0-1])'; x.push 'day'
					when 'hh' then re += '([1-9]|[0-1][0-9]|2[0-3])'; x.push 'hour'
					when 'h' then re += '([1-9]|[0-1][0-9]|2[0-3])'; x.push 'hour'
					when 'nn' then re += '([1-9]|[0-5][0-9])'; x.push 'minute'
					when 'n' then re += '([1-9]|[0-5][0-9])'; x.push 'minute'
					when 'ss' then re += '([1-9]|[0-5][0-9])'; x.push 'second'
					when 's' then re += '([1-9]|[0-5][0-9])'; x.push 'second'
					when 'iii' then re += '([0-9]{1,3})'; x.push 'millisecond'
					when 'ii' then re += '([0-9]{1,3})'; x.push 'millisecond'
					when 'i' then re += '([0-9]{1,3})'; x.push 'millisecond'
					else re += "\\#{cc}"
	
		re = new RegExp "^#{re}$", ''
		match = date.match re
		
		if match
			values = {}
			for value, index in match when index > 0
				values[x[index - 1]] = parseInt value

			return new Date(values.year, values.month - 1, values.day, values.hour ? 0, values.minute ? 0, values.second ? 0, values.millisecond ? 0)
		else
			return null

Object.defineProperty Date.prototype, 'format',
	value: (f) ->
		out = ''
		
		while f
			i = 1
			c = f.substr 0, 1
			
			if c.charCodeAt(0) is 92
				out += f.substr 1, 1
				f = f.substr Math.min(f.length, 2)
			
			else
				cc = c
				while f.substr(i, 1) is c
					cc += f.substr i, 1
					i++
		
				f = f.substr i
				
				switch cc
					when 'yyyy' then out += this.getFullYear()
					when 'yyy' then out += String(this.getFullYear()).substr(1)
					when 'yy' then out += String(this.getFullYear()).substr(2)
					when 'y' then out += Number(String(this.getFullYear()).substr(2))
					when 'y' then out += Number(String(this.getFullYear()).substr(2))
					when 'mm' then out += Number(this.getMonth() + 1).digits(2)
					when 'm' then out += this.getMonth() + 1
					when 'dd' then out += Number(this.getDate()).digits(2)
					when 'd' then out += this.getDate()
					when 'hh' then out += Number(this.getHours()).digits(2)
					when 'h' then out += this.getHours()
					when 'nn' then out += Number(this.getMinutes()).digits(2)
					when 'n' then out += this.getHours()
					when 'ss' then out += Number(this.getSeconds()).digits(2)
					when 's' then out += this.getHours()
					when 'iii' then out += Number(this.getMilliseconds()).digits(3)
					when 'ii' then out += Number(this.getMilliseconds()).digits(2)
					when 'i' then out += this.getMilliseconds()
					else out += cc
	
		out
		
	enumerable: false
	
Object.defineProperty Date.prototype, 'diff',
	value: (units, dt) ->
		d = 0
		
		switch units.toLowerCase()
			when 'y'
				d = Math.floor((dt - this) / (365*24*60*60*1000))
			when 'm'
				d = Math.floor((dt - this) / (30*24*60*60*1000))
			when 'd'
				d = Math.floor((dt - this) / (24*60*60*1000))
			when 'h'
				d = Math.floor((dt - this) / (60*60*1000))
			when 'n'
				d = Math.floor((dt - this) / (60*1000))
			when 's'
				d = Math.floor((dt - this) / (1000))
			when 'i'
				d = Math.floor(dt - this)
				
		d
		
	enumerable: false
	
Object.defineProperty Date.prototype, 'add',
	value: (units, value) ->
		switch units.toLowerCase()
			when 'y'
				@setFullYear @getFullYear() + value
			when 'm'
				@setMonth @getMonth() + value
			when 'd'
				@setDate @getDate() + value
			when 'h'
				@setHours @getHours() + value
			when 'n'
				@setMinutes @getMinutes() + value
			when 's'
				@setSeconds @getSeconds() + value
			when 'i'
				@setMilliseconds @getMilliseconds() + value
				
		@
		
	enumerable: false