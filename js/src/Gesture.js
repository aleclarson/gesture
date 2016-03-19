var Factory, ResponderSyntheticEvent, assert, currentCentroidX, currentCentroidY, ref, touchHistory;

ref = require("TouchHistoryMath"), currentCentroidX = ref.currentCentroidX, currentCentroidY = ref.currentCentroidY;

touchHistory = require("ResponderTouchHistoryStore").touchHistory;

assert = require("type-utils").assert;

ResponderSyntheticEvent = require("ResponderSyntheticEvent");

Factory = require("factory");

module.exports = Factory("Gesture", {
  mixins: [require("./GestureMath")],
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
    event: [ResponderSyntheticEvent]
  },
  customValues: {
    isTouching: {
      get: function() {
        return this.finished === null;
      }
    },
    needsUpdate: {
      get: function() {
        return this._currentEvent < touchHistory.mostRecentTimeStamp;
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
    }
  },
  initValues: function() {
    return {
      _x0: null,
      _y0: null,
      _prevX: null,
      _prevY: null,
      _lastMoveTime: null,
      _currentEvent: 0,
      _prevEvent: null
    };
  },
  initReactiveValues: function() {
    return {
      touchCount: touchHistory.numberActiveTouches,
      finished: null
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
  _updateEvent: function() {
    assert(this.needsUpdate);
    this._prevEvent = this._currentEvent;
    return this._currentEvent = touchHistory.mostRecentTimeStamp;
  },
  _computeFinalVelocity: function() {
    if (!this._lastMoveTime) {
      return;
    }
    if (Date.now() - this._lastMoveTime < 150) {
      return;
    }
    this._vx.set(0);
    return this._vy.set(0);
  },
  _onReject: function() {
    return this.finished = false;
  },
  _onGrant: emptyFunction,
  _onEnd: function(finished, event) {
    this._computeFinalVelocity();
    return this.finished = finished;
  },
  _onTouchStart: function(event) {
    this.touchCount = touchHistory.numberActiveTouches;
    this._onTouchCountChanged();
    return this._updateEvent();
  },
  _onTouchMove: function(event) {
    if (this.touchCount < touchHistory.numberActiveTouches) {
      this._onTouchStart(event);
      return false;
    } else if (this.touchCount > touchHistory.numberActiveTouches) {
      this._onTouchEnd(event);
      return false;
    }
    this._lastMoveTime = Date.now();
    this._prevX = this._x;
    this._prevY = this._y;
    this._x = currentCentroidX(touchHistory);
    this._y = currentCentroidY(touchHistory);
    this._resetLazyValues();
    this._updateEvent();
    return true;
  },
  _onTouchEnd: function(event) {
    this.touchCount = touchHistory.numberActiveTouches;
    if (this.touchCount > 0) {
      return this._onTouchCountChanged();
    }
  },
  _onTouchCountChanged: function() {
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

//# sourceMappingURL=../../map/src/Gesture.map
