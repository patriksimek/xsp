// Generated by CoffeeScript 1.6.2
(function() {
  Object.defineProperty(Number.prototype, 'digits', {
    value: function(len) {
      var out;

      out = this.toString();
      while (out.length < len) {
        out = '0' + out;
      }
      return out;
    },
    enumerable: false
  });

  Object.defineProperty(Number.prototype, 'toRad', {
    value: function() {
      return this * Math.PI / 180;
    },
    enumerable: false
  });

}).call(this);