var Gesture, assertType, touchHistory;

touchHistory = require("ResponderTouchHistoryStore").touchHistory;

assertType = require("type-utils").assertType;

Gesture = require("./Gesture");

module.exports = {
  onStartShouldSetResponder: function(event) {
    if (!this._active) {
      this._setEligibleResponder();
    }
    if (!this._needsUpdate()) {
      return false;
    }
    this._onTouchStart(event);
    return this._shouldRespondOnStart(event);
  },
  onMoveShouldSetResponder: function(event) {
    if (!this._needsUpdate()) {
      return false;
    }
    this._onTouchMove(event);
    return this._shouldRespondOnMove(event);
  },
  onEndShouldSetResponder: function(event) {
    if (touchHistory.numberActiveTouches === 0) {
      return false;
    }
    if (!this._needsUpdate()) {
      return false;
    }
    this._onTouchEnd(event);
    return this._shouldRespondOnEnd(event);
  },
  onStartShouldSetResponderCapture: function(event) {
    if (!this._active) {
      this._setEligibleResponder();
    }
    if (!this._needsUpdate()) {
      return false;
    }
    this._onTouchStart(event);
    return this._shouldCaptureOnStart(event);
  },
  onMoveShouldSetResponderCapture: function(event) {
    if (!this._needsUpdate()) {
      return false;
    }
    this._onTouchMove(event);
    return this._shouldCaptureOnMove(event);
  },
  onEndShouldSetResponderCapture: function(event) {
    if (touchHistory.numberActiveTouches === 0) {
      return false;
    }
    if (!this._needsUpdate()) {
      return false;
    }
    this._onTouchEnd(event);
    return this._shouldCaptureOnEnd(event);
  },
  onResponderStart: function(event) {
    if (!this._needsUpdate()) {
      return;
    }
    this._onTouchStart(event);
  },
  onResponderMove: function(event) {
    if (!this._needsUpdate()) {
      return;
    }
    this._onTouchMove(event);
  },
  onResponderEnd: function(event) {
    if (!this._needsUpdate()) {
      return;
    }
    this._onTouchEnd(event);
  },
  onResponderReject: function(event) {
    if (!this._needsUpdate()) {
      return;
    }
    this._onReject(event);
  },
  onResponderGrant: function(event) {
    assertType(this._gesture, Gesture.Kind);
    this._setActiveResponder();
    if (!this._captured) {
      this._onGrant(event);
    }
    return true;
  },
  onResponderRelease: function(event) {
    if (!this._needsUpdate()) {
      return;
    }
    this._onRelease(event);
  },
  onResponderTerminate: function(event) {
    if (!this._needsUpdate()) {
      return;
    }
    this._onTerminate(event);
  },
  onResponderTerminationRequest: function(event) {
    if (!this._needsUpdate()) {
      return true;
    }
    return this._onTerminationRequest(event);
  }
};

//# sourceMappingURL=../../map/src/ResponderMixin.map
