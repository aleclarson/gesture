var LazyVar, _computeFinalVelocity, _resetLazyValues, _updateEvent, _updateValues, combine, createFrozenValues, createValues, currentCentroidX, currentCentroidY, customValues, hook, init, lazyValues, publicValues, ref, sync, touchHistory;

ref = require("TouchHistoryMath"), currentCentroidX = ref.currentCentroidX, currentCentroidY = ref.currentCentroidY;

touchHistory = require("ResponderTouchHistoryStore").touchHistory;

LazyVar = require("lazy-var");

combine = require("combine");

hook = require("hook");

sync = require("sync");

module.exports = function(config) {
  combine(config.customValues != null ? config.customValues : config.customValues = {}, customValues);
  hook.after(config, "initValues", function(result) {
    return combine(result != null ? result : result = {}, createValues.call(this));
  });
  hook.after(config, "initFrozenValues", function(result) {
    return combine(result != null ? result : result = {}, createFrozenValues.call(this));
  });
  hook.after(config, "init", init);
  return combine(config, {
    _updateEvent: _updateEvent,
    _updateValues: _updateValues,
    _computeFinalVelocity: _computeFinalVelocity,
    _resetLazyValues: _resetLazyValues.get()
  });
};

customValues = {
  needsUpdate: {
    get: function() {
      return this._currentEvent < touchHistory.mostRecentTimeStamp;
    }
  }
};

publicValues = ["x0", "y0", "x", "y"];

sync.each(publicValues, function(key) {
  var backingKey;
  backingKey = "_" + key;
  return customValues[key] = {
    get: function() {
      return this[backingKey];
    }
  };
});

lazyValues = ["dx", "dy", "dt", "vx", "vy"];

sync.each(lazyValues, function(key) {
  var backingKey;
  backingKey = "_" + key;
  return customValues[key] = {
    get: function() {
      return this[backingKey].get();
    }
  };
});

createValues = function() {
  return {
    _currentEvent: 0,
    _prevEvent: null,
    _x0: null,
    _y0: null,
    _x: null,
    _y: null,
    _prevX: null,
    _prevY: null,
    _lastMoveTime: null
  };
};

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

init = function() {
  this._dx.set(0);
  this._dy.set(0);
  this._dt.set(0);
  this._vx.set(0);
  return this._vy.set(0);
};

_resetLazyValues = LazyVar(function() {
  var backingKeys;
  backingKeys = sync.map(lazyValues, function(key) {
    return "_" + key;
  });
  return function() {
    var i, key, len, results;
    results = [];
    for (i = 0, len = backingKeys.length; i < len; i++) {
      key = backingKeys[i];
      results.push(this[key].reset());
    }
    return results;
  };
});

_updateEvent = function() {
  assert(this.needsUpdate);
  this._prevEvent = this._currentEvent;
  return this._currentEvent = touchHistory.mostRecentTimeStamp;
};

_updateValues = function(phase) {
  return _updateValues[phase].call(this);
};

_updateValues.touchMove = function() {
  this._lastMoveTime = Date.now();
  this._prevX = this._x;
  this._prevY = this._y;
  this._x = currentCentroidX(touchHistory);
  this._y = currentCentroidY(touchHistory);
  this._resetLazyValues();
  return this._updateEvent();
};

_updateValues.touchStart = _updateValues.touchEnd = function() {
  var dx, dy, x, y;
  x = currentCentroidX(touchHistory);
  y = currentCentroidY(touchHistory);
  dx = x - this._x;
  dy = y - this._y;
  this._x = x;
  this._y = y;
  this._x0 += dx;
  this._y0 += dy;
  this._prevX += dx;
  this._prevY += dy;
  this._dt.reset();
  this._vx.set(0);
  return this._vy.set(0);
};

_computeFinalVelocity = function() {
  if (!this._lastMoveTime) {
    return;
  }
  if (Date.now() - this._lastMoveTime < 150) {
    return;
  }
  log.it("Gesture detected no movement!");
  this._vx.set(0);
  return this._vy.set(0);
};

//# sourceMappingURL=../../map/src/GestureMath.map
