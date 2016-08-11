var Event, Gesture, Responder, ResponderEventPlugin, ResponderSyntheticEvent, TouchEvent, Type, assert, assertType, emptyFunction, hook, touchHistory, type;

touchHistory = require("ResponderTouchHistoryStore").touchHistory;

ResponderSyntheticEvent = require("ResponderSyntheticEvent");

ResponderEventPlugin = require("ResponderEventPlugin");

emptyFunction = require("emptyFunction");

assertType = require("assertType");

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
  shouldRespondOnStart: Function.withDefault(emptyFunction.thatReturnsTrue),
  shouldRespondOnMove: Function.withDefault(emptyFunction.thatReturnsFalse),
  shouldRespondOnEnd: Function.withDefault(emptyFunction.thatReturnsFalse),
  shouldCaptureOnStart: Function.withDefault(emptyFunction.thatReturnsFalse),
  shouldCaptureOnMove: Function.withDefault(emptyFunction.thatReturnsFalse),
  shouldCaptureOnEnd: Function.withDefault(emptyFunction.thatReturnsFalse),
  shouldTerminate: Function.withDefault(emptyFunction.thatReturnsTrue)
});

type.defineValues(function(options) {
  return {
    _shouldRespondOnStart: options.shouldRespondOnStart,
    _shouldRespondOnMove: options.shouldRespondOnMove,
    _shouldRespondOnEnd: options.shouldRespondOnEnd,
    _shouldCaptureOnStart: options.shouldCaptureOnStart,
    _shouldCaptureOnMove: options.shouldCaptureOnMove,
    _shouldCaptureOnEnd: options.shouldCaptureOnEnd,
    _shouldTerminate: options.shouldTerminate
  };
});

type.defineProperties({
  isEnabled: {
    value: true,
    reactive: true,
    didSet: function() {
      return this.terminate();
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
      if (newValue === oldValue) {
        return;
      }
      if (newValue) {
        Responder.current = this;
        return Responder.didGrant.emit(this);
      } else {
        Responder.current = null;
        return Responder.didRelease.emit(this);
      }
    }
  }
});

type.defineEvents({
  didReject: TouchEvent,
  didGrant: TouchEvent,
  didEnd: TouchEvent,
  didTouchStart: TouchEvent,
  didTouchMove: TouchEvent,
  didTouchEnd: TouchEvent
});

type.defineGetters({
  touchHandlers: function() {
    return this._createMixin();
  },
  gesture: function() {
    return this._gesture;
  },
  isActive: function() {
    return this._gesture && this._gesture.isActive;
  },
  isGranted: function() {
    return this._isGranted;
  }
});

type.defineMethods({
  finish: function(nativeEvent) {
    var event;
    assertType(nativeEvent, Object.Maybe);
    if (this.isActive) {
      event = this._createEvent(nativeEvent);
      this._stopTracking();
      this._gestureEnded(event, true);
    }
  },
  terminate: function(nativeEvent) {
    var event;
    assertType(nativeEvent, Object.Maybe);
    if (this.isActive) {
      event = this._createEvent(nativeEvent);
      this._stopTracking();
      this._gestureEnded(event, false);
    }
  },
  _createEvent: function(nativeEvent) {
    var dispatchConfig, dispatchMarker;
    if (nativeEvent == null) {
      nativeEvent = {};
    }
    if (nativeEvent.touches == null) {
      nativeEvent.touches = [];
    }
    return new ResponderSyntheticEvent(dispatchConfig = {}, dispatchMarker = "", nativeEvent, nativeEvent.target);
  },
  _gestureBegan: function(event) {
    var pageX, pageY, ref;
    assert(!this._gesture, "Must reset '_gesture' before calling '_gestureBegan'!");
    ref = event.nativeEvent, pageX = ref.pageX, pageY = ref.pageY;
    this._gesture = this.__createGesture({
      x: pageX,
      y: pageY
    });
    assertType(this._gesture, Gesture.Kind);
    Responder.tracking.push(this);
  },
  _stopTracking: function() {
    var index, tracking;
    tracking = Responder.tracking;
    index = tracking.indexOf(this);
    tracking.splice(index, 1);
  },
  _gestureEnded: function(event, finished) {
    assert(this._gesture, "Must set '_gesture' before calling '_gestureEnded'!");
    this._touchEnded(event);
    if (this._isGranted) {
      if (finished) {
        this.__onRelease(event);
      } else {
        this.__onTerminate(event);
      }
    }
    this._gesture = null;
  },
  _touchesChanged: function(newTouches) {
    var index, oldTouches, touchCount;
    assert(this._gesture, "Must set '_gesture' before calling '_touchesChanged'!");
    oldTouches = this._gesture.touches;
    touchCount = oldTouches.length;
    if (touchCount !== newTouches.length) {
      return true;
    }
    index = -1;
    while (++index < touchCount) {
      if (oldTouches[index].identifier !== newTouches[index].identifier) {
        return true;
      }
    }
    return false;
  },
  _touchBegan: function(event) {
    var touches;
    assert(this.isActive, "Must be active when calling '_touchBegan'!");
    touches = event.nativeEvent.touches;
    if (this._touchesChanged(touches)) {
      this.__onTouchStart(event);
    }
  },
  _touchMoved: function(event) {
    var touches;
    assert(this.isActive, "Must be active when calling '_touchMoved'!");
    touches = event.nativeEvent.touches;
    assert(!this._touchesChanged(touches), "Must have same touches!");
    this.__onTouchMove(event);
  },
  _touchEnded: function(event) {
    var touches;
    assert(this.isActive, "Must be active when calling '_touchEnded'!");
    touches = event.nativeEvent.touches;
    if (this._touchesChanged(touches)) {
      this.__onTouchEnd(event);
    }
  },
  _createMixin: function() {
    return {
      onStartShouldSetResponder: (function(_this) {
        return function(event) {
          _this._gesture || _this._gestureBegan(event);
          if (_this.__canUpdate()) {
            _this._touchBegan(event);
            return _this.__shouldRespondOnStart(event);
          }
          return false;
        };
      })(this),
      onMoveShouldSetResponder: (function(_this) {
        return function(event) {
          if (_this.__canUpdate()) {
            _this._touchMoved(event);
            return _this.__shouldRespondOnMove(event);
          }
          return false;
        };
      })(this),
      onEndShouldSetResponder: (function(_this) {
        return function(event) {
          if (touchHistory.numberActiveTouches === 0) {
            return false;
          }
          if (_this.__canUpdate()) {
            _this._touchEnded(event);
            return _this.__shouldRespondOnEnd(event);
          }
          return false;
        };
      })(this),
      onStartShouldSetResponderCapture: (function(_this) {
        return function(event) {
          _this._gesture || _this._gestureBegan(event);
          if (_this.__canUpdate()) {
            _this._touchBegan(event);
            return _this.__shouldCaptureOnStart(event);
          }
          return false;
        };
      })(this),
      onMoveShouldSetResponderCapture: (function(_this) {
        return function(event) {
          if (_this.__canUpdate()) {
            _this._touchMoved(event);
            return _this.__shouldCaptureOnMove(event);
          }
          return false;
        };
      })(this),
      onEndShouldSetResponderCapture: (function(_this) {
        return function(event) {
          if (touchHistory.numberActiveTouches === 0) {
            return false;
          }
          if (_this.__canUpdate()) {
            _this._touchEnded(event);
            return _this.__shouldCaptureOnEnd(event);
          }
          return false;
        };
      })(this),
      onResponderStart: (function(_this) {
        return function(event) {
          return _this.__canUpdate() && _this._touchBegan(event);
        };
      })(this),
      onResponderMove: (function(_this) {
        return function(event) {
          return _this.__canUpdate() && _this._touchMoved(event);
        };
      })(this),
      onResponderEnd: (function(_this) {
        return function(event) {
          return _this.__canUpdate() && _this._touchEnded(event);
        };
      })(this),
      onResponderReject: (function(_this) {
        return function(event) {
          return _this.__canUpdate() && _this.__onReject(event);
        };
      })(this),
      onResponderGrant: (function(_this) {
        return function(event) {
          if (!_this._isGranted) {
            if (Responder.current !== null) {
              throw Error("`Responder.current` must be null before a new Responder can be set!");
            }
            _this._isGranted = true;
            _this.__onGrant(event);
          }
          return true;
        };
      })(this),
      onResponderRelease: emptyFunction,
      onResponderTerminate: (function(_this) {
        return function(event) {
          if (_this.__canUpdate()) {
            _this._stopTracking();
            _this._gestureEnded(event);
          }
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

type.defineHooks({
  __canUpdate: function() {
    return this.isEnabled && this.isActive;
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
  __onTouchStart: function(event) {
    this._gesture.__onTouchStart(event);
    return this._events.emit("didTouchStart", [this._gesture, event]);
  },
  __onTouchMove: function(event) {
    this._gesture.__onTouchMove(event);
    return this._events.emit("didTouchMove", [this._gesture, event]);
  },
  __onTouchEnd: function(event) {
    this._gesture.__onTouchEnd(event);
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
    this._isGranted = false;
    return this._events.emit("didEnd", [this._gesture, event]);
  },
  __onTerminate: function(event) {
    this._gesture.__onEnd(false, event);
    this._isGranted = false;
    return this._events.emit("didEnd", [this._gesture, event]);
  },
  __onTerminationRequest: function(event) {
    if (!this._gesture) {
      return true;
    }
    return this._shouldTerminate(this._gesture, event);
  }
});

type.defineStatics({
  tracking: [],
  current: null,
  didGrant: Event(),
  didRelease: Event()
});

module.exports = Responder = type.build();

hook.before(ResponderEventPlugin, "onFinalTouch", function(event) {
  var tracking;
  tracking = Responder.tracking;
  if (tracking.length === 0) {
    return;
  }
  tracking.forEach(function(responder) {
    responder.__canUpdate() && responder._gestureEnded(event, true);
  });
  return tracking.length = 0;
});

//# sourceMappingURL=map/Responder.map
