var Factory, Gesture, LazyVar, ResponderSyntheticEvent, assert, currentCentroidX, currentCentroidY, ref, touchHistory;

ref = require("TouchHistoryMath"), currentCentroidX = ref.currentCentroidX, currentCentroidY = ref.currentCentroidY;

touchHistory = require("ResponderTouchHistoryStore").touchHistory;

assert = require("type-utils").assert;

ResponderSyntheticEvent = require("ResponderSyntheticEvent");

LazyVar = require("lazy-var");

Factory = require("factory");

module.exports = Gesture = Factory("Gesture", {
  statics: {
    Responder: {
      lazy: function() {
        return require("./Responder");
      }
    },
    ResponderList: {
      lazy: function() {
        return require("./ResponderList");
      }
    }
  },
  optionTypes: {
    event: ResponderSyntheticEvent
  },
  customValues: {
    isActive: {
      get: function() {
        return this.finished === null;
      }
    },
    canUpdate: {
      get: function() {
        return this._currentTime < touchHistory.mostRecentTimeStamp;
      }
    },
    x0: {
      get: function() {
        return this._x0;
      }
    },
    y0: {
      get: function() {
        return this._y0;
      }
    },
    x: {
      get: function() {
        return this._x;
      }
    },
    y: {
      get: function() {
        return this._y;
      }
    },
    dx: {
      get: function() {
        return this._dx.get();
      }
    },
    dy: {
      get: function() {
        return this._dy.get();
      }
    },
    dt: {
      get: function() {
        return this._dt.get();
      }
    },
    vx: {
      get: function() {
        return this._vx.get();
      }
    },
    vy: {
      get: function() {
        return this._vy.get();
      }
    }
  },
  initFrozenValues: function() {
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
          return _this._currentTime - _this._prevTime;
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
  },
  initValues: function() {
    return {
      touchCount: touchHistory.numberActiveTouches,
      finished: null,
      _currentTime: 0,
      _prevTime: null,
      _x0: null,
      _y0: null,
      _x: null,
      _y: null,
      _prevX: null,
      _prevY: null,
      _grantDX: 0,
      _grantDY: 0,
      _lastMoveTime: null
    };
  },
  init: function(options) {
    var nativeEvent;
    nativeEvent = options.event.nativeEvent;
    this._x = this._prevX = this._x0 = nativeEvent.pageX;
    this._y = this._prevY = this._y0 = nativeEvent.pageY;
    this._dx.set(0);
    this._dy.set(0);
    this._dt.set(0);
    this._vx.set(0);
    return this._vy.set(0);
  },
  _updateTime: function() {
    this._prevTime = this._currentTime;
    return this._currentTime = touchHistory.mostRecentTimeStamp;
  },
  _updateCentroid: function() {
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
  },
  __onReject: function() {
    return this.finished = false;
  },
  __onGrant: function() {
    this._grantDX = this.dx;
    return this._grantDY = this.dy;
  },
  __onEnd: function(finished, event) {
    this.finished = finished;
    if (this._lastMoveTime && (Date.now() - this._lastMoveTime) >= 150) {
      this._vx.set(0);
      return this._vy.set(0);
    }
  },
  __onTouchStart: function(event, touchCount) {
    assert(touchCount > 0, "Invalid touch count!");
    this.touchCount = touchCount;
    if (!this.canUpdate) {
      return;
    }
    this._updateTime();
    return this._updateCentroid();
  },
  __onTouchMove: function(event) {
    if (!this.canUpdate) {
      return;
    }
    this._updateTime();
    this._lastMoveTime = Date.now();
    this._prevX = this._x;
    this._prevY = this._y;
    this._x = currentCentroidX(touchHistory);
    this._y = currentCentroidY(touchHistory);
    this._dx.reset();
    this._dy.reset();
    this._dt.reset();
    this._vx.reset();
    return this._vy.reset();
  },
  __onTouchEnd: function(event, touchCount) {
    assert(touchCount >= 0, "Invalid touch count!");
    this.touchCount = touchCount;
    if (touchCount === 0) {
      return;
    }
    if (!this.canUpdate) {
      return;
    }
    this._updateTime();
    return this._updateCentroid();
  }
});

//# sourceMappingURL=../../map/src/Gesture.map
