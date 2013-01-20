global.Date::format = (f) ->
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
				when 'mmm' then out += 'TODO'
				when 'mm' then out += Number(this.getMonth() + 1).digits(2)
				when 'm' then out += this.getMonth() + 1
				when 'ddd' then out += 'TODO'
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
	
global.Date::diff = (units, dt) ->
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
			
global.Date::interval = (f, dt) ->
	s = Math.floor((dt - this) / (1000))
	n = Math.floor((dt - this) / (60*1000))
	h = Math.floor((dt - this) / (60*60*1000))
	d = Math.floor((dt - this) / (24*60*60*1000))
	
	if s > 60 then s = s % 60
	if n > 60 then n = n % 60
	if h > 24 then h = h % 24
	
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
				when 'dd' then out += Number(d).digits(2)
				when 'd' then out += d
				when 'hh' then out += Number(h).digits(2)
				when 'h' then out += h
				when 'nn' then out += Number(n).digits(2)
				when 'n' then out += n
				when 'ss' then out += Number(s).digits(2)
				when 's' then out += s
				else out += cc

	out
	
global.Date::timestamp = () ->
	Math.round @.getTime() / 1000
	
global.Date.now = () ->
	new Date
	
global.Date.timestamp = () ->
	Date.now().timestamp()