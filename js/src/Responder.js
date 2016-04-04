var Event, Factory, Gesture, Immutable, Responder, ResponderEventPlugin, ResponderMixin, activeResponder, assertType, didSetActiveResponder, eligibleResponders, emptyFunction, hook, sync, touchHistory;

touchHistory = require("ResponderTouchHistoryStore").touchHistory;

assertType = require("type-utils").assertType;

ResponderEventPlugin = require("ResponderEventPlugin");

emptyFunction = require("emptyFunction");

Immutable = require("immutable");

Factory = require("factory");

Event = require("event");

hook = require("hook");

sync = require("sync");

ResponderMixin = require("./ResponderMixin");

Gesture = require("./Gesture");

activeResponder = null;

didSetActiveResponder = Event();

eligibleResponders = Immutable.OrderedSet();

hook.before(ResponderEventPlugin, "onFinalTouch", function(event) {
  if (eligibleResponders.size === 0) {
    return;
  }
  eligibleResponders.forEach(function(responder) {
    if (!responder._gesture) {
      return true;
    }
    responder._onTouchEnd(event);
    responder._deinitGesture();
    return true;
  });
  return eligibleResponders = Immutable.OrderedSet();
});

module.exports = Responder = Factory("Gesture_Responder", {
  statics: {
    activeResponder: {
      get: function() {
        return activeResponder;
      }
    },
    didSetActiveResponder: {
      get: function() {
        return didSetActiveResponder.listenable;
      }
    }
  },
  optionTypes: {
    minTouchCount: Number,
    maxTouchCount: Number,
    shouldRespondOnStart: Function,
    shouldRespondOnMove: Function,
    shouldRespondOnEnd: Function,
    shouldCaptureOnStart: Function,
    shouldCaptureOnMove: Function,
    shouldCaptureOnEnd: Function,
    shouldTerminate: Function
  },
  optionDefaults: {
    minTouchCount: 1,
    maxTouchCount: Infinity,
    shouldRespondOnStart: emptyFunction.thatReturnsTrue,
    shouldRespondOnMove: emptyFunction.thatReturnsFalse,
    shouldRespondOnEnd: emptyFunction.thatReturnsFalse,
    shouldCaptureOnStart: emptyFunction.thatReturnsFalse,
    shouldCaptureOnMove: emptyFunction.thatReturnsFalse,
    shouldCaptureOnEnd: emptyFunction.thatReturnsFalse,
    shouldTerminate: emptyFunction.thatReturnsTrue
  },
  customValues: {
    isEnabled: {
      get: function() {
        return this._enabled;
      },
      set: function(isEnabled) {
        this._enabled = isEnabled;
        return this._onTerminate();
      }
    },
    isTouching: {
      get: function() {
        return this._active;
      }
    },
    isCaptured: {
      get: function() {
        return this._captured;
      }
    },
    touchHandlers: {
      lazy: function() {
        var self;
        self = this;
        return sync.map(ResponderMixin, function(handler) {
          return function() {
            return handler.apply(self, arguments);
          };
        });
      }
    },
    _gestureType: {
      lazy: function() {
        return this._getGestureType();
      }
    }
  },
  initFrozenValues: function(options) {
    return {
      _options: options,
      didReject: Event(),
      didGrant: Event(),
      didEnd: Event(),
      didTouchStart: Event(),
      didTouchMove: Event(),
      didTouchEnd: Event()
    };
  },
  initReactiveValues: function() {
    return {
      _enabled: true,
      _active: false,
      _captured: false,
      _ended: false,
      _gesture: null,
      _lastGesture: null
    };
  },
  _needsUpdate: function() {
    if (!this._enabled) {
      return false;
    }
    if (this._ended) {
      return false;
    }
    if (this._gesture) {
      return this._gesture.needsUpdate;
    }
    return true;
  },
  _setActiveResponder: function() {
    if (activeResponder) {
      return;
    }
    didSetActiveResponder.emit(activeResponder = this);
  },
  _clearActiveResponder: function() {
    if (activeResponder !== this) {
      return;
    }
    didSetActiveResponder.emit(activeResponder = null);
  },
  _setEligibleResponder: function() {
    eligibleResponders = eligibleResponders.add(this);
    this._ended = false;
  },
  _clearEligibleResponder: function() {
    eligibleResponders = eligibleResponders.remove(this);
  },
  _getGestureType: function() {
    return Gesture;
  },
  _initGesture: function(event) {
    assert(!this._active);
    this._active = true;
    this._gesture = this._gestureType({
      event: event
    });
  },
  _deinitGesture: function() {
    assertType(this._gesture, Gesture.Kind);
    this._clearEligibleResponder();
    this._active = false;
    this._ended = true;
    if (this._captured) {
      this.didEnd.emit(this._gesture);
      this._captured = false;
    }
    this._lastGesture = this._gesture;
    this._gesture = null;
    this._clearActiveResponder();
  },
  _shouldRespondOnStart: function() {
    return this._options.shouldRespondOnStart(this._gesture);
  },
  _shouldRespondOnMove: function() {
    return this._options.shouldRespondOnMove(this._gesture);
  },
  _shouldRespondOnEnd: function() {
    return this._options.shouldRespondOnEnd(this._gesture);
  },
  _shouldCaptureOnStart: function() {
    return this._options.shouldCaptureOnStart(this._gesture);
  },
  _shouldCaptureOnMove: function() {
    return this._options.shouldCaptureOnMove(this._gesture);
  },
  _shouldCaptureOnEnd: function() {
    return this._options.shouldCaptureOnEnd(this._gesture);
  },
  _onTouchStart: function(event) {
    if (this._active && this._gesture.touchCount === touchHistory.numberActiveTouches) {
      return false;
    }
    if (!this._active) {
      this._initGesture(event);
    }
    this._gesture._onTouchStart(event);
    this.didTouchStart.emit(this._gesture, event);
    return true;
  },
  _onTouchMove: function(event) {
    this._gesture._onTouchMove(event);
    this.didTouchMove.emit(this._gesture, event);
  },
  _onTouchEnd: function(event) {
    if (this._gesture.touchCount === touchHistory.numberActiveTouches) {
      return false;
    }
    this._gesture._onTouchEnd(event);
    this.didTouchEnd.emit(this._gesture, event);
    return true;
  },
  _onReject: function(event) {
    this._gesture._onReject(event);
    this.didReject.emit(this._gesture, event);
  },
  _onGrant: function(event) {
    assert(!this._captured);
    this._captured = true;
    this._gesture._onGrant(event);
    this.didGrant.emit(this._gesture, event);
  },
  _onEnd: function(event) {
    this._gesture._onEnd(true, event);
    this._deinitGesture();
  },
  _onTerminate: function(event) {
    this._gesture._onEnd(false, event);
    this._deinitGesture();
  },
  _onTerminationRequest: function(event) {
    return this._options.shouldTerminate(this._gesture, event);
  }
});

//# sourceMappingURL=../../map/src/Responder.map
