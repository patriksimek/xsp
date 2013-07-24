module.exports = function() {
	this.get('/', 'app#index');
	
	this.get('/*', function(req, res) {
		res.send(404, 'Not found');
	});
};
