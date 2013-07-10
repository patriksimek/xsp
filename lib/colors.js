module.exports = function() {
	var util = require('util');
	var cluster = require('cluster');
	
	this.colors = {
		white: '\033[37m',
		grey: '\033[90m',
		black: '\033[30m',
		blue: '\033[34m',
		cyan: '\033[36m',
		green: '\033[32m',
		magenta: '\033[35m',
		red: '\033[31m',
		yellow: '\033[33m',
		def: '\033[39m'
	};
	
	colors = {
		white: function() {trace('\033[37m'+ Array.prototype.join.call(arguments, ', ') +'\033[39m')},
		grey: function() {trace('\033[90m'+ Array.prototype.join.call(arguments, ', ') +'\033[39m')},
		black: function() {trace('\033[30m'+ Array.prototype.join.call(arguments, ', ') +'\033[39m')},
		blue: function() {trace('\033[34m'+ Array.prototype.join.call(arguments, ', ') +'\033[39m')},
		cyan: function() {trace('\033[36m'+ Array.prototype.join.call(arguments, ', ') +'\033[39m')},
		green: function() {trace('\033[32m'+ Array.prototype.join.call(arguments, ', ') +'\033[39m')},
		magenta: function() {trace('\033[35m'+ Array.prototype.join.call(arguments, ', ') +'\033[39m')},
		red: function() {trace('\033[31m'+ Array.prototype.join.call(arguments, ', ') +'\033[39m')},
		yellow: function() {trace('\033[33m'+ Array.prototype.join.call(arguments, ', ') +'\033[39m')},
		bold: function() {trace('\033[1m'+ Array.prototype.join.call(arguments, ', ') +'\033[22m')},
		italic: function() {trace('\033[3m'+ Array.prototype.join.call(arguments, ', ') +'\033[23m')},
		underline: function() {trace('\033[4m'+ Array.prototype.join.call(arguments, ', ') +'\033[24m')},
		inverse: function() {trace('\033[7m'+ Array.prototype.join.call(arguments, ', ') +'\033[27m')}
	};
	
	colors2 = {
		white: function(msg) {trace('\033[37m'+ util.inspect(msg) +'\033[39m')},
		grey: function(msg) {trace('\033[90m'+ util.inspect(msg) +'\033[39m')},
		black: function(msg) {trace('\033[30m'+ util.inspect(msg) +'\033[39m')},
		blue: function(msg) {trace('\033[34m'+ util.inspect(msg) +'\033[39m')},
		cyan: function(msg) {trace('\033[36m'+ util.inspect(msg) +'\033[39m')},
		green: function(msg) {trace('\033[32m'+ util.inspect(msg) +'\033[39m')},
		magenta: function(msg) {trace('\033[35m'+ util.inspect(msg) +'\033[39m')},
		red: function(msg) {trace('\033[31m'+ util.inspect(msg) +'\033[39m'); if (msg instanceof Error) trace.red(msg.stack)},
		yellow: function(msg) {trace('\033[33m'+ util.inspect(msg) +'\033[39m')},
		bold: function(msg) {trace('\033[1m'+ util.inspect(msg) +'\033[22m')},
		italic: function(msg) {trace('\033[3m'+ util.inspect(msg) +'\033[23m')},
		underline: function(msg) {trace('\033[4m'+ util.inspect(msg) +'\033[24m')},
		inverse: function(msg) {trace('\033[7m'+ util.inspect(msg) +'\033[27m')}
	};
	
	for (var i in colors) trace[i] = colors[i]
	for (var i in colors2) inspect[i] = colors2[i]
};