var LAZY_KEYS, LazyVar, combine, createFrozenValues, customValues, hook;

LazyVar = require("lazy-var");

combine = require("combine");

hook = require("hook");

LAZY_KEYS = ["_dx", "_dy", "_dt", "_vx", "_vy"];

module.exports = function(config) {
  combine(config.customValues != null ? config.customValues : config.customValues = {}, customValues);
  hook.after(config, "initFrozenValues", function(result) {
    return combine(result != null ? result : result = {}, createFrozenValues.call(this));
  });
  return config._resetLazyValues = function() {
    return LAZY_KEYS.forEach((function(_this) {
      return function(LAZY_KEY) {
        return _this[LAZY_KEY].reset();
      };
    })(this));
  };
};

customValues = {};

["dx", "dy", "dt", "vx", "vy"].forEach(function(key) {
  var LAZY_KEY;
  LAZY_KEY = "_" + key;
  return customValues[key] = {
    get: function() {
      return this[LAZY_KEY].get();
    }
  };
});

createFrozenValues = function() {
  return {
    _dx: LazyVar((function(_this) {
      return function() {
        return _this._x - _this._x0;
      };
    })(this)),
    _dy: LazyVar((function(_this) {
      return function() {
        return _this._y - _this._y0;
      };
    })(this)),
    _dt: LazyVar((function(_this) {
      return function() {
        return _this._currentEvent - _this._prevEvent;
      };
    })(this)),
    _vx: LazyVar((function(_this) {
      return function() {
        return (_this._x - _this._prevX) / _this._dt.get();
      };
    })(this)),
    _vy: LazyVar((function(_this) {
      return function() {
        return (_this._y - _this._prevY) / _this._dt.get();
      };
    })(this))
  };
};

//# sourceMappingURL=../../map/src/GestureMath.map
