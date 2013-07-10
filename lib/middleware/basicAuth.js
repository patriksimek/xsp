// Generated by CoffeeScript 1.6.2
(function() {
  module.exports = function(username, password) {
    return function(req, res, next) {
      var auth, header, parts, token;

      header = req.headers.authorization || '';
      token = header.split(/\s+/).pop() || '';
      auth = new Buffer(token, 'base64').toString();
      parts = auth.split(/:/);
      if (username === parts[0] && password === parts[1]) {
        return next();
      } else {
        res.statusCode = 401;
        res.setHeader('WWW-Authenticate', 'Basic realm="Authorization Required"');
        return res.end('Unauthorized');
      }
    };
  };

}).call(this);