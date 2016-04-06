var Event, Factory, Gesture, Responder, ResponderEventPlugin, assertType, emptyFunction, hook, touchHistory;

touchHistory = require("ResponderTouchHistoryStore").touchHistory;

assertType = require("type-utils").assertType;

ResponderEventPlugin = require("ResponderEventPlugin");

emptyFunction = require("emptyFunction");

Factory = require("factory");

Event = require("event");

hook = require("hook");

Gesture = require("./Gesture");

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

module.exports = Responder = Factory("Gesture_Responder", {
  statics: {
    activeResponders: [],
    capturedResponder: null,
    didResponderCapture: Event()
  },
  optionTypes: {
    shouldRespondOnStart: Function,
    shouldRespondOnMove: Function,
    shouldRespondOnEnd: Function,
    shouldCaptureOnStart: Function,
    shouldCaptureOnMove: Function,
    shouldCaptureOnEnd: Function,
    shouldTerminate: Function
  },
  optionDefaults: {
    shouldRespondOnStart: emptyFunction.thatReturnsTrue,
    shouldRespondOnMove: emptyFunction.thatReturnsFalse,
    shouldRespondOnEnd: emptyFunction.thatReturnsFalse,
    shouldCaptureOnStart: emptyFunction.thatReturnsFalse,
    shouldCaptureOnMove: emptyFunction.thatReturnsFalse,
    shouldCaptureOnEnd: emptyFunction.thatReturnsFalse,
    shouldTerminate: emptyFunction.thatReturnsTrue
  },
  customValues: {
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
    isCaptured: {
      get: function() {
        return this._isCaptured;
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
    _isCaptured: {
      value: false,
      reactive: true,
      didSet: function(newValue, oldValue) {
        var responder;
        if (newValue === oldValue) {
          return;
        }
        responder = newValue ? this : null;
        Responder.capturedResponder = responder;
        return Responder.didResponderCapture.emit(responder);
      }
    }
  },
  initFrozenValues: function() {
    return {
      didReject: Event(),
      didGrant: Event(),
      didEnd: Event(),
      didTouchStart: Event(),
      didTouchMove: Event(),
      didTouchEnd: Event()
    };
  },
  initValues: function(options) {
    return {
      _shouldRespondOnStart: options.shouldRespondOnStart,
      _shouldRespondOnMove: options.shouldRespondOnMove,
      _shouldRespondOnEnd: options.shouldRespondOnEnd,
      _shouldCaptureOnStart: options.shouldCaptureOnStart,
      _shouldCaptureOnMove: options.shouldCaptureOnMove,
      _shouldCaptureOnEnd: options.shouldCaptureOnEnd,
      _shouldTerminate: options.shouldTerminate
    };
  },
  terminate: function(event, finished) {
    if (!this.isActive) {
      return;
    }
    this.__onTouchEnd(event, 0);
    if (this.isCaptured) {
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
  __shouldRespondOnStart: function() {
    return this._shouldRespondOnStart(this._gesture);
  },
  __shouldRespondOnMove: function() {
    return this._shouldRespondOnMove(this._gesture);
  },
  __shouldRespondOnEnd: function() {
    return this._shouldRespondOnEnd(this._gesture);
  },
  __shouldCaptureOnStart: function() {
    return this._shouldCaptureOnStart(this._gesture);
  },
  __shouldCaptureOnMove: function() {
    return this._shouldCaptureOnMove(this._gesture);
  },
  __shouldCaptureOnEnd: function() {
    return this._shouldCaptureOnEnd(this._gesture);
  },
  __onTouchStart: function(event, touchCount) {
    log.it(this.__id + ".__onTouchStart()");
    this._gesture.__onTouchStart(event, touchCount);
    return this.didTouchStart.emit(this._gesture, event);
  },
  __onTouchMove: function(event) {
    this._gesture.__onTouchMove(event);
    return this.didTouchMove.emit(this._gesture, event);
  },
  __onTouchEnd: function(event, touchCount) {
    log.it(this.__id + ".__onTouchEnd()");
    this._gesture.__onTouchEnd(event, touchCount);
    return this.didTouchEnd.emit(this._gesture, event);
  },
  __onReject: function(event) {
    log.it(this.__id + ".__onReject()");
    this._gesture.__onReject(event);
    return this.didReject.emit(this._gesture, event);
  },
  __onGrant: function(event) {
    log.it(this.__id + ".__onGrant()");
    this._gesture.__onGrant(event);
    return this.didGrant.emit(this._gesture, event);
  },
  __onRelease: function(event) {
    log.it(this.__id + ".__onRelease()");
    this._gesture.__onEnd(true, event);
    return this.didEnd.emit(this._gesture, event);
  },
  __onTerminate: function(event) {
    log.it(this.__id + ".__onTerminate()");
    this._gesture.__onEnd(false, event);
    return this.didEnd.emit(this._gesture, event);
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
    if (this._gesture) {
      return;
    }
    this._gesture = this.__createGesture({
      event: event
    });
    this._setActive(true);
    return assertType(this._gesture, Gesture.Kind);
  },
  _deleteGesture: function() {
    assert(this.isActive, "Gesture not yet created!");
    this._isCaptured = false;
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
          if (!_this.isCaptured) {
            assert(Responder.capturedResponder === null, {
              reason: "The `capturedResponder` must be null before it can be set to a new Responder!",
              failedResponder: _this,
              capturedResponder: Responder.capturedResponder
            });
            _this._isCaptured = true;
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
            console.info("Detected the terminate method!");
            _this.__onTerminate(event);
            return;
          }
          console.info("Higher responder captured the active touch!");
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

//# sourceMappingURL=../../map/src/Responder.map
