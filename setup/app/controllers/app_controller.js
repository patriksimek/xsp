module.exports = function() {
	xsp = this;
	
	AppController = function() {
		xsp.Controller.call(this);
	}
	
	AppController.prototype = new xsp.Controller()
	AppController.prototype.constructor = AppController
	
	AppController.index = function(req, res) {
		res.render({
			title: "xsp sample application"
		});
	};
	
	this.AppController = AppController;
};