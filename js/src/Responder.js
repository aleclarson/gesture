var Event, Factory, PAN_METHODS, PanResponder, emptyFunction, sync;

sync = require("io").sync;

emptyFunction = require("emptyFunction");

PanResponder = require("PanResponder");

Factory = require("factory");

Event = require("event");

PAN_METHODS = {
  "onStartShouldSetPanResponder": "onStartShouldSetPanResponder",
  "onMoveShouldSetPanResponder": "onMoveShouldSetPanResponder",
  "onStartShouldSetPanResponderCapture": "onStartShouldSetPanResponderCapture",
  "onMoveShouldSetPanResponderCapture": "onMoveShouldSetPanResponderCapture",
  "onPanResponderReject": "onPanResponderReject",
  "onPanResponderGrant": "onPanResponderGrant",
  "onPanResponderMove": "onPanResponderMove",
  "onPanResponderRelease": "onPanResponderRelease",
  "onPanResponderTerminate": "onPanResponderTerminate",
  "onPanResponderTerminationRequest": "onPanResponderTerminationRequest"
};

module.exports = Factory("Gesture_Responder", {
  optionTypes: {
    shouldRespondOnStart: Function,
    shouldRespondOnMove: Function,
    shouldCaptureOnStart: Function,
    shouldCaptureOnMove: Function,
    shouldTerminate: Function
  },
  optionDefaults: {
    shouldRespondOnStart: emptyFunction.thatReturnsTrue,
    shouldRespondOnMove: emptyFunction.thatReturnsFalse,
    shouldCaptureOnStart: emptyFunction.thatReturnsFalse,
    shouldCaptureOnMove: emptyFunction.thatReturnsFalse,
    shouldTerminate: emptyFunction.thatReturnsTrue
  },
  customValues: {
    isEnabled: {
      get: function() {
        return this._enabled;
      },
      set: function(isEnabled) {
        this._enabled = isEnabled;
        return this._onPanResponderTerminate();
      }
    },
    isTouching: {
      get: function() {
        var ref;
        return ((ref = this._gesture) != null ? ref.isTouching : void 0) === true;
      }
    },
    touchHandlers: {
      lazy: function() {
        var panMethods;
        panMethods = sync.map(PAN_METHODS, (function(_this) {
          return function(key) {
            return _this["_" + key].bind(_this);
          };
        })(this));
        return (PanResponder.create(panMethods)).panHandlers;
      }
    }
  },
  initFrozenValues: function() {
    return {
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
      _enabled: true,
      _gesture: null
    };
  },
  _onStartShouldSetPanResponder: function() {
    if (!this._enabled) {
      return false;
    }
    return this._shouldRespondOnStart(this._gesture);
  },
  _onMoveShouldSetPanResponder: function() {
    if (!this._enabled) {
      return false;
    }
    return this._shouldRespondOnMove(this._gesture);
  },
  _onStartShouldSetPanResponderCapture: function(gesture) {
    if (!this._enabled) {
      return false;
    }
    this._gesture = Gesture({
      gesture: gesture,
      axis: this.axis
    });
    return this._shouldCaptureOnStart(this._gesture);
  },
  _onMoveShouldSetPanResponderCapture: function() {
    if (!this._enabled) {
      return false;
    }
    return this._shouldCaptureOnMove(this._gesture);
  },
  _onPanResponderReject: emptyFunction,
  _onPanResponderGrant: function() {
    this._gesture._onTouchStart();
    return this.didTouchStart.emit(this._gesture);
  },
  _onPanResponderMove: function() {
    if (!this._gesture) {
      return;
    }
    this._gesture._onTouchMove();
    return this.didTouchMove.emit(this._gesture);
  },
  _onPanResponderEnd: function() {
    this.didTouchEnd.emit(this._gesture);
    return this._gesture = null;
  },
  _onPanResponderRelease: function() {
    if (!this._gesture) {
      return;
    }
    this._gesture._onTouchEnd(true);
    return this._onPanResponderEnd();
  },
  _onPanResponderTerminate: function() {
    if (!this._gesture) {
      return;
    }
    this._gesture._onTouchEnd(false);
    return this._onPanResponderEnd();
  },
  _onPanResponderTerminationRequest: function() {
    if (!this._gesture) {
      return true;
    }
    return this._shouldTerminate(this._gesture);
  }
});

//# sourceMappingURL=../../map/src/Responder.map
