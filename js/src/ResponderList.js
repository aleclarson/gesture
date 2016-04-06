var ArrayOf, Factory, Responder, ResponderMixin, ResponderSyntheticEvent, assertType, isKind, isType, ref, sync;

ref = require("type-utils"), ArrayOf = ref.ArrayOf, isType = ref.isType, isKind = ref.isKind, assertType = ref.assertType;

ResponderSyntheticEvent = require("ResponderSyntheticEvent");

Factory = require("factory");

sync = require("sync");

ResponderMixin = require("./ResponderMixin");

Responder = require("./Responder");

module.exports = Factory("Gesture_ResponderList", {
  initArguments: function(responders) {
    assertType(responders, ArrayOf([Responder.Kind, Void]));
    return arguments;
  },
  customValues: {
    touchHandlers: {
      lazy: function() {
        var self;
        self = this;
        return sync.map(ResponderMixin, function(_, key) {
          var handler;
          handler = self["_" + key];
          return function() {
            return handler.apply(self, arguments);
          };
        });
      }
    }
  },
  initFrozenValues: function(responders) {
    return {
      _responders: sync.filter(responders, function(responder) {
        return isKind(responder, Responder);
      })
    };
  },
  initValues: function() {
    return {
      _activeResponder: null
    };
  },
  _setActiveResponder: function(responder, event) {
    var base;
    assertType(responder, Responder.Kind);
    if (!this._activeResponder) {
      this._activeResponder = responder;
      return true;
    }
    if (!this._onResponderTerminationRequest(event)) {
      if (typeof (base = responder.touchHandlers).onResponderReject === "function") {
        base.onResponderReject(event);
      }
      return false;
    }
    this._onResponderTerminate(event);
    this._activeResponder = responder;
    this._onResponderGrant(event);
    return true;
  },
  _shouldRespond: function(phase, event) {
    var shouldRespond;
    assert(this._activeResponder === null);
    shouldRespond = false;
    sync.search(this._responders, function(responder) {
      if (!responder.touchHandlers.onStartShouldSetResponder(event)) {
        return true;
      }
      shouldRespond = this._setActiveResponder(responder, event);
      return false;
    });
    return shouldRespond;
  },
  _shouldCapture: function(phase, event) {
    var shouldCapture;
    shouldCapture = false;
    sync.searchFromEnd(this._responders, function(responder) {
      if (responder === this._activeResponder) {
        return false;
      }
      if (!responder.touchHandlers.onEndShouldSetResponderCapture(event)) {
        return true;
      }
      shouldCapture = this._setActiveResponder(responder, event);
      return false;
    });
    return shouldCapture;
  },
  _onStartShouldSetResponder: function(event) {
    return this._shouldRespond("onStartShouldSetResponder", event);
  },
  _onMoveShouldSetResponder: function(event) {
    return this._shouldRespond("onMoveShouldSetResponder", event);
  },
  _onEndShouldSetResponder: function(event) {
    return this._shouldRespond("onEndShouldSetResponder", event);
  },
  _onStartShouldSetResponderCapture: function(event) {
    return this._shouldCapture("onStartShouldSetResponderCapture", event);
  },
  _onMoveShouldSetResponderCapture: function(event) {
    return this._shouldCapture("onMoveShouldSetResponderCapture", event);
  },
  _onEndShouldSetResponderCapture: function(event) {
    return this._shouldCapture("onEndShouldSetResponderCapture", event);
  },
  _onResponderReject: function(event) {
    return this._activeResponder.touchHandlers.onResponderReject(event);
  },
  _onResponderGrant: function(event) {
    return this._activeResponder.touchHandlers.onResponderGrant(event);
  },
  _onResponderStart: function(event) {
    return this._activeResponder.touchHandlers.onResponderStart(event);
  },
  _onResponderMove: function(event) {
    this._onMoveShouldSetResponderCapture(event);
    return this._activeResponder.touchHandlers.onResponderMove(event);
  },
  _onResponderEnd: function(event) {
    return this._activeResponder.touchHandlers.onResponderEnd(event);
  },
  _onResponderRelease: function(event) {
    this._activeResponder.touchHandlers.onResponderRelease(event);
    return this._activeResponder = null;
  },
  _onResponderTerminate: function(event) {
    this._activeResponder.touchHandlers.onResponderTerminate(event);
    return this._activeResponder = null;
  },
  _onResponderTerminationRequest: function(event) {
    return this._activeResponder.touchHandlers.onResponderTerminationRequest(event);
  }
});

//# sourceMappingURL=../../map/src/ResponderList.map
