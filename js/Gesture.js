var LazyVar, ResponderSyntheticEvent, Type, assert, currentCentroidX, currentCentroidY, fromArgs, ref, touchHistory, type;

ref = require("TouchHistoryMath"), currentCentroidX = ref.currentCentroidX, currentCentroidY = ref.currentCentroidY;

touchHistory = require("ResponderTouchHistoryStore").touchHistory;

ResponderSyntheticEvent = require("ResponderSyntheticEvent");

fromArgs = require("fromArgs");

LazyVar = require("LazyVar");

assert = require("assert");

Type = require("Type");

type = Type("Gesture");

type.defineOptions({
  x: Number.isRequired,
  y: Number.isRequired
});

type.defineGetters({
  isActive: function() {
    return this.finished === null;
  },
  canUpdate: function() {
    return this._currentTime < touchHistory.mostRecentTimeStamp;
  },
  x0: function() {
    return this._x0;
  },
  y0: function() {
    return this._y0;
  },
  x: function() {
    return this._x;
  },
  y: function() {
    return this._y;
  },
  dx: function() {
    return this._dx.get();
  },
  dy: function() {
    return this._dy.get();
  },
  dt: function() {
    return this._dt.get();
  },
  vx: function() {
    return this._vx.get();
  },
  vy: function() {
    return this._vy.get();
  }
});

type.defineFrozenValues({
  _dx: function() {
    return LazyVar((function(_this) {
      return function() {
        return _this._x - _this._x0;
      };
    })(this));
  },
  _dy: function() {
    return LazyVar((function(_this) {
      return function() {
        return _this._y - _this._y0;
      };
    })(this));
  },
  _dt: function() {
    return LazyVar((function(_this) {
      return function() {
        return _this._currentTime - _this._prevTime;
      };
    })(this));
  },
  _vx: function() {
    return LazyVar((function(_this) {
      return function() {
        return (_this._x - _this._prevX) / _this._dt.get();
      };
    })(this));
  },
  _vy: function() {
    return LazyVar((function(_this) {
      return function() {
        return (_this._y - _this._prevY) / _this._dt.get();
      };
    })(this));
  }
});

type.defineValues({
  touchCount: function() {
    return touchHistory.numberActiveTouches;
  },
  finished: null,
  _currentTime: 0,
  _prevTime: null,
  _x: fromArgs("x"),
  _y: fromArgs("y"),
  _x0: function() {
    return this._x;
  },
  _y0: function() {
    return this._y;
  },
  _prevX: function() {
    return this._x;
  },
  _prevY: function() {
    return this._y;
  },
  _grantDX: 0,
  _grantDY: 0,
  _lastMoveTime: null
});

type.initInstance(function() {
  this._dx.set(0);
  this._dy.set(0);
  this._dt.set(0);
  this._vx.set(0);
  return this._vy.set(0);
});

type.defineMethods({
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
  }
});

type.defineHooks({
  __onReject: function() {
    return this.finished = false;
  },
  __onGrant: function() {
    this._grantDX = this.dx;
    return this._grantDY = this.dy;
  },
  __onEnd: function(finished) {
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
  __onTouchMove: function() {
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

type.defineStatics({
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
});

module.exports = type.build();

//# sourceMappingURL=map/Gesture.map
