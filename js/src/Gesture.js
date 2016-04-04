var Factory, Gesture, ResponderSyntheticEvent, assert, touchHistory;

touchHistory = require("ResponderTouchHistoryStore").touchHistory;

assert = require("type-utils").assert;

ResponderSyntheticEvent = require("ResponderSyntheticEvent");

Factory = require("factory");

module.exports = Gesture = Factory("Gesture", {
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
    }
  },
  initValues: function() {
    return {
      _grantDX: 0,
      _grantDY: 0
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
  },
  _onReject: function() {
    this.finished = false;
  },
  _onGrant: function() {
    this._grantDX = this.dx;
    this._grantDY = this.dy;
  },
  _onEnd: function(finished, event) {
    this._computeFinalVelocity();
    this.finished = finished;
  },
  _onTouchStart: function(event) {
    this.touchCount = touchHistory.numberActiveTouches;
    this._updateValues("touchStart");
    this._updateEvent();
  },
  _onTouchMove: function(event) {
    if (this.touchCount < touchHistory.numberActiveTouches) {
      this._onTouchStart(event);
      return false;
    } else if (this.touchCount > touchHistory.numberActiveTouches) {
      this._onTouchEnd(event);
      return false;
    }
    this._updateValues("touchMove");
    return true;
  },
  _onTouchEnd: function(event) {
    this.touchCount = touchHistory.numberActiveTouches;
    if (this.touchCount > 0) {
      this._updateValues("touchEnd");
    }
  }
});

//# sourceMappingURL=../../map/src/Gesture.map
