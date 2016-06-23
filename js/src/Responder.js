var Event, Gesture, Responder, ResponderEventPlugin, ResponderSyntheticEvent, TouchEvent, Type, assert, assertType, emptyFunction, getArgProp, hook, touchHistory, type;

touchHistory = require("ResponderTouchHistoryStore").touchHistory;

ResponderSyntheticEvent = require("ResponderSyntheticEvent");

ResponderEventPlugin = require("ResponderEventPlugin");

emptyFunction = require("emptyFunction");

assertType = require("assertType");

getArgProp = require("getArgProp");

assert = require("assert");

Event = require("Event");

Type = require("Type");

hook = require("hook");

Gesture = require("./Gesture");

TouchEvent = {
  gesture: Gesture.Kind,
  event: [ResponderSyntheticEvent]
};

type = Type("Responder");

type.defineOptions({
  shouldRespondOnStart: {
    type: Function,
    "default": emptyFunction.thatReturnsTrue
  },
  shouldRespondOnMove: {
    type: Function,
    "default": emptyFunction.thatReturnsFalse
  },
  shouldRespondOnEnd: {
    type: Function,
    "default": emptyFunction.thatReturnsFalse
  },
  shouldCaptureOnStart: {
    type: Function,
    "default": emptyFunction.thatReturnsFalse
  },
  shouldCaptureOnMove: {
    type: Function,
    "default": emptyFunction.thatReturnsFalse
  },
  shouldCaptureOnEnd: {
    type: Function,
    "default": emptyFunction.thatReturnsFalse
  },
  shouldTerminate: {
    type: Function,
    "default": emptyFunction.thatReturnsTrue
  }
});

type.defineStatics({
  activeResponders: [],
  grantedResponder: null,
  didResponderGrant: Event()
});

type.defineProperties({
  touchHandlers: {
    get: function() {
      return this._createMixin();
    }
  },
  isEnabled: {
    value: true,
    reactive: true,
    didSet: function() {
      return this.terminate();
    }
  },
  isActive: {
    get: function() {
      return this._gesture !== null;
    }
  },
  isGranted: {
    get: function() {
      return this._isGranted;
    }
  },
  gesture: {
    get: function() {
      return this._gesture;
    }
  },
  _gesture: {
    value: null,
    reactive: true
  },
  _isGranted: {
    value: false,
    reactive: true,
    didSet: function(newValue, oldValue) {
      var responder;
      if (newValue === oldValue) {
        return;
      }
      responder = newValue ? this : null;
      Responder.grantedResponder = responder;
      return Responder.didResponderGrant.emit(responder);
    }
  }
});

type.defineValues({
  _shouldRespondOnStart: getArgProp("shouldRespondOnStart"),
  _shouldRespondOnMove: getArgProp("shouldRespondOnMove"),
  _shouldRespondOnEnd: getArgProp("shouldRespondOnEnd"),
  _shouldCaptureOnStart: getArgProp("shouldCaptureOnStart"),
  _shouldCaptureOnMove: getArgProp("shouldCaptureOnMove"),
  _shouldCaptureOnEnd: getArgProp("shouldCaptureOnEnd"),
  _shouldTerminate: getArgProp("shouldTerminate")
});

type.defineEvents({
  didReject: {
    types: TouchEvent
  },
  didGrant: {
    types: TouchEvent
  },
  didEnd: {
    types: TouchEvent
  },
  didTouchStart: {
    types: TouchEvent
  },
  didTouchMove: {
    types: TouchEvent
  },
  didTouchEnd: {
    types: TouchEvent
  }
});

type.defineMethods({
  terminate: function(event, finished) {
    if (!this.isActive) {
      return;
    }
    this.__onTouchEnd(event, 0);
    if (this.isGranted) {
      if (finished === true) {
        this.__onRelease(event);
      } else {
        this.__onTerminate(event);
      }
    }
    this._deleteGesture();
  },
  __canUpdate: function() {
    return this.isEnabled && this._gesture && this._gesture.isActive;
  },
  __createGesture: function(options) {
    return Gesture(options);
  },
  __shouldRespondOnStart: function(event) {
    return this._shouldRespondOnStart(this._gesture, event);
  },
  __shouldRespondOnMove: function(event) {
    return this._shouldRespondOnMove(this._gesture, event);
  },
  __shouldRespondOnEnd: function(event) {
    return this._shouldRespondOnEnd(this._gesture, event);
  },
  __shouldCaptureOnStart: function(event) {
    return this._shouldCaptureOnStart(this._gesture, event);
  },
  __shouldCaptureOnMove: function(event) {
    return this._shouldCaptureOnMove(this._gesture, event);
  },
  __shouldCaptureOnEnd: function(event) {
    return this._shouldCaptureOnEnd(this._gesture, event);
  },
  __onTouchStart: function(event, touchCount) {
    this._gesture.__onTouchStart(event, touchCount);
    return this._events.emit("didTouchStart", [this._gesture, event]);
  },
  __onTouchMove: function(event) {
    this._gesture.__onTouchMove(event);
    return this._events.emit("didTouchMove", [this._gesture, event]);
  },
  __onTouchEnd: function(event, touchCount) {
    this._gesture.__onTouchEnd(event, touchCount);
    return this._events.emit("didTouchEnd", [this._gesture, event]);
  },
  __onReject: function(event) {
    this._gesture.__onReject(event);
    return this._events.emit("didReject", [this._gesture, event]);
  },
  __onGrant: function(event) {
    this._gesture.__onGrant(event);
    return this._events.emit("didGrant", [this._gesture, event]);
  },
  __onRelease: function(event) {
    this._gesture.__onEnd(true, event);
    this._events.emit("didEnd", [this._gesture, event]);
  },
  __onTerminate: function(event) {
    this._gesture.__onEnd(false, event);
    return this._events.emit("didEnd", [this._gesture, event]);
  },
  __onTerminationRequest: function(event) {
    if (!this._gesture) {
      return true;
    }
    return this._shouldTerminate(this._gesture, event);
  },
  _setActive: function(isActive) {
    var responders;
    responders = Responder.activeResponders;
    if (isActive) {
      return responders.push(this);
    } else {
      return responders.splice(responders.indexOf(this), 1);
    }
  },
  _createGesture: function(event) {
    var pageX, pageY, ref;
    if (this._gesture) {
      return;
    }
    ref = event.nativeEvent, pageX = ref.pageX, pageY = ref.pageY;
    this._gesture = this.__createGesture({
      x: pageX,
      y: pageY
    });
    this._setActive(true);
    return assertType(this._gesture, Gesture.Kind);
  },
  _deleteGesture: function() {
    assert(this.isActive, "Gesture not yet created!");
    this._isGranted = false;
    return this._gesture = null;
  },
  _onTouchStart: function(event, touchCount) {
    if (this._gesture.touchCount === touchCount) {
      return;
    }
    return this.__onTouchStart(event, touchCount);
  },
  _onTouchMove: function(event, touchCount) {
    if (this._gesture.touchCount < touchCount) {
      this.__onTouchStart(event, touchCount);
      return;
    }
    assert(this._gesture.touchCount === touchCount, "Should call '_onTouchEnd' inside '_onTouchMove'!");
    return this.__onTouchMove(event);
  },
  _onTouchEnd: function(event, touchCount) {
    assert(this._gesture.touchCount !== touchCount);
    this.__onTouchEnd(event, touchCount);
    if (touchCount > 0) {
      return;
    }
    this._deleteGesture();
    return this._setActive(false);
  },
  _createMixin: function() {
    return {
      onStartShouldSetResponder: (function(_this) {
        return function(event) {
          _this._createGesture(event);
          if (!_this.__canUpdate()) {
            return false;
          }
          _this._onTouchStart(event, touchHistory.numberActiveTouches);
          return _this.__shouldRespondOnStart(event);
        };
      })(this),
      onMoveShouldSetResponder: (function(_this) {
        return function(event) {
          if (!_this.__canUpdate()) {
            return false;
          }
          _this._onTouchMove(event, touchHistory.numberActiveTouches);
          return _this.__shouldRespondOnMove(event);
        };
      })(this),
      onEndShouldSetResponder: (function(_this) {
        return function(event) {
          if (touchHistory.numberActiveTouches === 0) {
            return false;
          }
          if (!_this.__canUpdate()) {
            return false;
          }
          _this._onTouchEnd(event, touchHistory.numberActiveTouches);
          return _this.__shouldRespondOnEnd(event);
        };
      })(this),
      onStartShouldSetResponderCapture: (function(_this) {
        return function(event) {
          _this._createGesture(event);
          if (!_this.__canUpdate()) {
            return false;
          }
          _this._onTouchStart(event, touchHistory.numberActiveTouches);
          return _this.__shouldCaptureOnStart(event);
        };
      })(this),
      onMoveShouldSetResponderCapture: (function(_this) {
        return function(event) {
          if (!_this.__canUpdate()) {
            return false;
          }
          _this._onTouchMove(event, touchHistory.numberActiveTouches);
          return _this.__shouldCaptureOnMove(event);
        };
      })(this),
      onEndShouldSetResponderCapture: (function(_this) {
        return function(event) {
          if (touchHistory.numberActiveTouches === 0) {
            return false;
          }
          if (!_this.__canUpdate()) {
            return false;
          }
          _this._onTouchEnd(event, touchHistory.numberActiveTouches);
          return _this.__shouldCaptureOnEnd(event);
        };
      })(this),
      onResponderStart: (function(_this) {
        return function(event) {
          if (!_this.__canUpdate()) {
            return;
          }
          return _this._onTouchStart(event, touchHistory.numberActiveTouches);
        };
      })(this),
      onResponderMove: (function(_this) {
        return function(event) {
          if (!_this.__canUpdate()) {
            return;
          }
          return _this._onTouchMove(event, touchHistory.numberActiveTouches);
        };
      })(this),
      onResponderEnd: (function(_this) {
        return function(event) {
          if (!_this.__canUpdate()) {
            return;
          }
          return _this._onTouchEnd(event, touchHistory.numberActiveTouches);
        };
      })(this),
      onResponderReject: (function(_this) {
        return function(event) {
          if (!_this.__canUpdate()) {
            return;
          }
          return _this.__onReject(event);
        };
      })(this),
      onResponderGrant: (function(_this) {
        return function(event) {
          if (!_this.isGranted) {
            assert(Responder.grantedResponder === null, {
              reason: "The `grantedResponder` must be null before it can be set to a new Responder!",
              failedResponder: _this,
              grantedResponder: Responder.grantedResponder
            });
            _this._isGranted = true;
            _this.__onGrant(event);
          }
          return true;
        };
      })(this),
      onResponderRelease: emptyFunction,
      onResponderTerminate: (function(_this) {
        return function(event) {
          if (!_this.__canUpdate()) {
            return;
          }
          if (_this.gesture.touchCount === 0) {
            _this.__onTerminate(event);
            return;
          }
          _this.__onTouchEnd(event, 0);
          _this.__onTerminate(event);
          _this._deleteGesture();
          return _this._setActive(false);
        };
      })(this),
      onResponderTerminationRequest: (function(_this) {
        return function(event) {
          if (!_this._gesture) {
            return true;
          }
          return _this.__onTerminationRequest(event);
        };
      })(this)
    };
  }
});

module.exports = Responder = type.build();

hook.before(ResponderEventPlugin, "onFinalTouch", function(event) {
  var i, len, responder, responders;
  responders = Responder.activeResponders;
  if (responders.length === 0) {
    return;
  }
  for (i = 0, len = responders.length; i < len; i++) {
    responder = responders[i];
    responder.terminate(event, true);
  }
  return responders.length = 0;
});

//# sourceMappingURL=../../map/src/Responder.map
