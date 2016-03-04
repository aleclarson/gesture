var Factory, LazyVar;

LazyVar = require("lazy-var");

Factory = require("factory");

module.exports = Factory("Gesture", {
  statics: {
    Responder: LazyVar(function() {
      return require("./Responder");
    }),
    Combinator: LazyVar(function() {
      return require("./Combinator");
    })
  },
  optionTypes: {
    gesture: Object
  },
  customValues: {
    isTouching: {
      get: function() {
        return this._touching;
      }
    },
    finished: {
      get: function() {
        return this._finished;
      }
    },
    x0: {
      get: function() {
        return this._gesture.x0;
      }
    },
    y0: {
      get: function() {
        return this._gesture.y0;
      }
    },
    x: {
      get: function() {
        return this._gesture.moveX;
      }
    },
    y: {
      get: function() {
        return this._gesture.moveY;
      }
    },
    dx: {
      get: function() {
        return this._gesture.dx;
      }
    },
    dy: {
      get: function() {
        return this._gesture.dy;
      }
    },
    vx: {
      get: function() {
        return this._gesture.vx;
      }
    },
    vy: {
      get: function() {
        return this._gesture.vy;
      }
    }
  },
  initFrozenValues: function(options) {
    return {
      _gesture: options.gesture
    };
  },
  initValues: function() {
    return {
      _finished: null
    };
  },
  initReactiveValues: function() {
    return {
      _touching: false
    };
  },
  _onTouchStart: function() {
    this._touching = true;
  },
  _onTouchMove: function() {},
  _onTouchEnd: function(finished) {
    this._finished = finished;
    this._touching = false;
  }
});

//# sourceMappingURL=../../map/src/Gesture.map
