global.Geography =
	distance: (p1, p2) ->
		r = 6371 ## km
		dLat = (p2[1]-p1[1]).toRad()
		dLon = (p2[0]-p1[0]).toRad()
		a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.cos(p1[1].toRad()) * Math.cos(p2[1].toRad()) * Math.sin(dLon/2) * Math.sin(dLon/2)
		c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
		return r * c