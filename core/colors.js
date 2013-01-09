colors = {
	white: function(msg) {trace('\033[37m'+ msg +'\033[39m')},
	grey: function(msg) {trace('\033[90m'+ msg +'\033[39m')},
	black: function(msg) {trace('\033[30m'+ msg +'\033[39m')},
	blue: function(msg) {trace('\033[34m'+ msg +'\033[39m')},
	cyan: function(msg) {trace('\033[36m'+ msg +'\033[39m')},
	green: function(msg) {trace('\033[32m'+ msg +'\033[39m')},
	magenta: function(msg) {trace('\033[35m'+ msg +'\033[39m')},
	red: function(msg) {trace('\033[31m'+ msg +'\033[39m')},
	yellow: function(msg) {trace('\033[33m'+ msg +'\033[39m')},
	bold: function(msg) {trace('\033[1m'+ msg +'\033[22m')},
	italic: function(msg) {trace('\033[3m'+ msg +'\033[23m')},
	underline: function(msg) {trace('\033[4m'+ msg +'\033[24m')},
	inverse: function(msg) {trace('\033[7m'+ msg +'\033[27m')}
};

for (var i in colors) trace[i] = colors[i]