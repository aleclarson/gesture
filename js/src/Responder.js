var Event, Factory, Gesture, Responder, ResponderEventPlugin, assertType, emptyFunction, hook, isTerminatingActiveResponders, touchHistory;

touchHistory = require("ResponderTouchHistoryStore").touchHistory;

assertType = require("type-utils").assertType;

ResponderEventPlugin = require("ResponderEventPlugin");

emptyFunction = require("emptyFunction");

Factory = require("factory");

Event = require("event");

hook = require("hook");

Gesture = require("./Gesture");

isTerminatingActiveResponders = false;

hook.before(ResponderEventPlugin, "onFinalTouch", function() {
  var i, len, responder, responders;
  responders = Responder.activeResponders;
  if (responders.length === 0) {
    return;
  }
  isTerminatingActiveResponders = true;
  for (i = 0, len = responders.length; i < len; i++) {
    responder = responders[i];
    responder.finish();
  }
  responders.length = 0;
  return isTerminatingActiveResponders = false;
});

module.exports = Responder = Factory("Gesture_Responder", {
  statics: {
    activeResponders: [],
    capturedResponder: null,
    didResponderCapture: Event()
  },
  optionTypes: {
    minTouchCount: Number,
    shouldRespondOnStart: Function,
    shouldRespondOnMove: Function,
    shouldCaptureOnStart: Function,
    shouldCaptureOnMove: Function,
    shouldTerminate: Function
  },
  optionDefaults: {
    minTouchCount: 1,
    shouldRespondOnStart: emptyFunction.thatReturnsTrue,
    shouldRespondOnMove: emptyFunction.thatReturnsFalse,
    shouldCaptureOnStart: emptyFunction.thatReturnsFalse,
    shouldCaptureOnMove: emptyFunction.thatReturnsFalse,
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
    }
  },
  initFrozenValues: function(options) {
    return {
      minTouchCount: options.minTouchCount,
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
      _shouldCaptureOnStart: options.shouldCaptureOnStart,
      _shouldCaptureOnMove: options.shouldCaptureOnMove,
      _shouldTerminate: options.shouldTerminate
    };
  },
  initReactiveValues: function() {
    return {
      _gesture: null,
      _isCaptured: false
    };
  },
  capture: function() {
    if (this.isCaptured) {
      return;
    }
    assert(Responder.capturedResponder === null, {
      reason: "The `capturedResponder` must be null before it can be set to a new Responder!",
      failedResponder: this,
      capturedResponder: Responder.capturedResponder
    });
    this._setCaptured(true);
    this.__onGrant();
  },
  finish: function() {
    this._interrupt(true);
  },
  terminate: function() {
    if (!this.__onTerminationRequest()) {
      return;
    }
    this._interrupt(false);
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
  __shouldCaptureOnStart: function() {
    return this._shouldCaptureOnStart(this._gesture);
  },
  __shouldCaptureOnMove: function() {
    return this._shouldCaptureOnMove(this._gesture);
  },
  __onTouchStart: function(touchCount) {
    this._gesture.__onTouchStart(touchCount);
    return this.didTouchStart.emit(this._gesture);
  },
  __onTouchMove: function() {
    this._gesture.__onTouchMove();
    return this.didTouchMove.emit(this._gesture);
  },
  __onTouchEnd: function(touchCount) {
    this._gesture.__onTouchEnd(touchCount);
    return this.didTouchEnd.emit(this._gesture);
  },
  __onReject: function() {
    this._gesture.__onReject();
    return this.didReject.emit(this._gesture);
  },
  __onGrant: function() {
    this._gesture.__onGrant();
    return this.didGrant.emit(this._gesture);
  },
  __onRelease: function() {
    this._gesture.__onEnd(true);
    return this.didEnd.emit(this._gesture);
  },
  __onTerminate: function() {
    this._gesture.__onEnd(false);
    return this.didEnd.emit(this._gesture);
  },
  __onTerminationRequest: function() {
    if (!this._gesture) {
      return true;
    }
    return this._shouldTerminate(this._gesture);
  },
  _interrupt: function(finished) {
    if (!this.isActive) {
      return;
    }
    this.__onTouchEnd(0);
    if (this._isCaptured) {
      if (finished === true) {
        this.__onRelease();
      } else {
        this.__onTerminate();
      }
    }
    this._deleteGesture();
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
    var wasCaptured;
    assert(this.isActive, "Gesture not yet created!");
    wasCaptured = this._isCaptured;
    this._setCaptured(false);
    this._setActive(false);
    return this._gesture = null;
  },
  _setActive: function(isActive) {
    var responders;
    if (isTerminatingActiveResponders && !isActive) {
      return;
    }
    responders = Responder.activeResponders;
    if (isActive) {
      return responders.push(this);
    } else {
      return responders.splice(responders.indexOf(this), 1);
    }
  },
  _setCaptured: function(isCaptured) {
    var responder;
    if (isCaptured === this._isCaptured) {
      return;
    }
    this._isCaptured = isCaptured;
    responder = isCaptured ? this : null;
    Responder.capturedResponder = responder;
    return Responder.didResponderCapture.emit(responder);
  },
  _onTouchStart: function(touchCount) {
    if (this._gesture.touchCount === touchCount) {
      return;
    }
    return this.__onTouchStart(touchCount);
  },
  _onTouchMove: function(touchCount) {
    if (this._gesture.touchCount < touchCount) {
      this.__onTouchStart(touchCount);
      return;
    } else if (this._gesture.touchCount > touchCount) {
      this._onTouchEnd(touchCount);
      return;
    }
    return this.__onTouchMove();
  },
  _onTouchEnd: function(touchCount) {
    assert(this._gesture.touchCount !== touchCount);
    this.__onTouchEnd(touchCount);
    if (touchCount > 0) {
      return;
    }
    return this._deleteGesture();
  },
  _createMixin: function() {
    return {
      onStartShouldSetResponder: (function(_this) {
        return function(event) {
          if (Responder.capturedResponder) {
            return false;
          }
          if (touchHistory.numberActiveTouches < _this.minTouchCount) {
            return false;
          }
          _this._createGesture(event);
          if (!_this.__canUpdate()) {
            return false;
          }
          _this._onTouchStart(touchHistory.numberActiveTouches);
          return _this.__shouldRespondOnStart();
        };
      })(this),
      onMoveShouldSetResponder: (function(_this) {
        return function() {
          if (touchHistory.numberActiveTouches < _this.minTouchCount) {
            return false;
          }
          if (!_this.__canUpdate()) {
            return false;
          }
          _this._onTouchMove(touchHistory.numberActiveTouches);
          return _this.__shouldRespondOnMove();
        };
      })(this),
      onStartShouldSetResponderCapture: (function(_this) {
        return function(event) {
          if (touchHistory.numberActiveTouches < _this.minTouchCount) {
            return false;
          }
          _this._createGesture(event);
          if (!_this.__canUpdate()) {
            return false;
          }
          _this._onTouchStart(touchHistory.numberActiveTouches);
          return _this.__shouldCaptureOnStart(event);
        };
      })(this),
      onMoveShouldSetResponderCapture: (function(_this) {
        return function(event) {
          if (touchHistory.numberActiveTouches < _this.minTouchCount) {
            return false;
          }
          if (!_this.__canUpdate()) {
            return false;
          }
          _this._onTouchMove(touchHistory.numberActiveTouches);
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
          _this._onTouchEnd(touchHistory.numberActiveTouches);
          return false;
        };
      })(this),
      onResponderStart: (function(_this) {
        return function() {
          if (!_this.__canUpdate()) {
            return;
          }
          return _this._onTouchStart(touchHistory.numberActiveTouches);
        };
      })(this),
      onResponderMove: (function(_this) {
        return function() {
          if (!_this.__canUpdate()) {
            return;
          }
          return _this._onTouchMove(touchHistory.numberActiveTouches);
        };
      })(this),
      onResponderEnd: (function(_this) {
        return function() {
          if (!_this.__canUpdate()) {
            return;
          }
          return _this._onTouchEnd(touchHistory.numberActiveTouches);
        };
      })(this),
      onResponderReject: (function(_this) {
        return function() {
          if (!_this.__canUpdate()) {
            return;
          }
          return _this.__onReject();
        };
      })(this),
      onResponderGrant: (function(_this) {
        return function() {
          assert(_this._gesture !== null, {
            reason: "A gesture must be created before 'onResponderGrant'!"
          });
          if (!_this._isCaptured) {
            _this.capture();
          }
          return true;
        };
      })(this),
      onResponderRelease: emptyFunction,
      onResponderTerminate: (function(_this) {
        return function() {
          if (!_this.__canUpdate()) {
            return;
          }
          if (_this.gesture.touchCount === 0) {
            _this.__onTerminate();
            return;
          }
          _this.__onTouchEnd(0);
          _this.__onTerminate();
          return _this._deleteGesture();
        };
      })(this),
      onResponderTerminationRequest: (function(_this) {
        return function() {
          if (!_this._gesture) {
            return true;
          }
          return _this.__onTerminationRequest();
        };
      })(this)
    };
  }
});

//# sourceMappingURL=../../map/src/Responder.map
