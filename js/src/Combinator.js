var ArrayOf, Combinator, Factory, RESPONDER_METHODS, Responder, assertType, isType, ref, sync;

ref = require("type-utils"), isType = ref.isType, assertType = ref.assertType, ArrayOf = ref.ArrayOf;

sync = require("io").sync;

Factory = require("factory");

Responder = require("./Responder");

RESPONDER_METHODS = {
  "onStartShouldSetResponder": "onStartShouldSetResponder",
  "onMoveShouldSetResponder": "onMoveShouldSetResponder",
  "onStartShouldSetResponderCapture": "onStartShouldSetResponderCapture",
  "onMoveShouldSetResponderCapture": "onMoveShouldSetResponderCapture",
  "onResponderReject": "onResponderReject",
  "onResponderGrant": "onResponderGrant",
  "onResponderMove": "onResponderMove",
  "onResponderRelease": "onResponderRelease",
  "onResponderTerminate": "onResponderTerminate",
  "onResponderTerminationRequest": "onResponderTerminationRequest"
};

module.exports = Combinator = Factory("Gesture_Combinator", {
  initArguments: function(responders) {
    assertType(responders, ArrayOf([Responder.Kind, Object]));
    return arguments;
  },
  customValues: {
    touchHandlers: {
      lazy: function() {
        return sync.map(RESPONDER_METHODS, (function(_this) {
          return function(key) {
            return _this["_" + key].bind(_this);
          };
        })(this));
      }
    }
  },
  initFrozenValues: function(responders) {
    return {
      _responders: sync.map(responders, function(responder) {
        if (isType(responder, Object)) {
          return responder;
        }
        return responder.touchHandlers;
      })
    };
  },
  initValues: function() {
    return {
      _activeResponder: null
    };
  },
  _onStartShouldSetResponder: function(e) {
    var i, len, ref1, responder;
    ref1 = this._responders;
    for (i = 0, len = ref1.length; i < len; i++) {
      responder = ref1[i];
      if ((typeof responder.onStartShouldSetResponder === "function" ? responder.onStartShouldSetResponder(e) : void 0) !== true) {
        continue;
      }
      this._activeResponder = responder;
      break;
    }
    return this._activeResponder != null;
  },
  _onMoveShouldSetResponder: function(e) {
    var i, len, ref1, responder;
    ref1 = this._responders;
    for (i = 0, len = ref1.length; i < len; i++) {
      responder = ref1[i];
      if ((typeof responder.onMoveShouldSetResponder === "function" ? responder.onMoveShouldSetResponder(e) : void 0) !== true) {
        continue;
      }
      this._activeResponder = responder;
      break;
    }
    return this._activeResponder != null;
  },
  _onStartShouldSetResponderCapture: function(e) {
    var index, responder;
    index = this._responders.length;
    while (--index >= 0) {
      responder = this._responders[index];
      if ((typeof responder.onStartShouldSetResponderCapture === "function" ? responder.onStartShouldSetResponderCapture(e) : void 0) !== true) {
        continue;
      }
      this._activeResponder = responder;
      break;
    }
    return this._activeResponder != null;
  },
  _onMoveShouldSetResponderCapture: function(e) {
    var index, responder, shouldCapture;
    shouldCapture = false;
    index = this._responders.length;
    while (--index >= 0) {
      responder = this._responders[index];
      if (responder === this._activeResponder) {
        break;
      }
      if ((typeof responder.onMoveShouldSetResponderCapture === "function" ? responder.onMoveShouldSetResponderCapture(e) : void 0) !== true) {
        continue;
      }
      if (this._activeResponder != null) {
        if (!this._onResponderTerminationRequest(e)) {
          if (typeof responder.onResponderReject === "function") {
            responder.onResponderReject(e);
          }
          break;
        }
        this._onResponderTerminate(e);
        this._activeResponder = responder;
        this._onResponderGrant(e);
      } else {
        this._activeResponder = responder;
      }
      shouldCapture = true;
      break;
    }
    return shouldCapture;
  },
  _onResponderReject: function(e) {
    var base;
    return typeof (base = this._activeResponder).onResponderReject === "function" ? base.onResponderReject(e) : void 0;
  },
  _onResponderGrant: function(e) {
    var base;
    return typeof (base = this._activeResponder).onResponderGrant === "function" ? base.onResponderGrant(e) : void 0;
  },
  _onResponderMove: function(e) {
    var base;
    this._onMoveShouldSetResponderCapture(e);
    return typeof (base = this._activeResponder).onResponderMove === "function" ? base.onResponderMove(e) : void 0;
  },
  _onResponderRelease: function(e) {
    var base;
    if (typeof (base = this._activeResponder).onResponderRelease === "function") {
      base.onResponderRelease(e);
    }
    return this._activeResponder = null;
  },
  _onResponderTerminate: function(e) {
    var base;
    if (typeof (base = this._activeResponder).onResponderTerminate === "function") {
      base.onResponderTerminate(e);
    }
    return this._activeResponder = null;
  },
  _onResponderTerminationRequest: function(e) {
    var base;
    return (typeof (base = this._activeResponder).onResponderTerminationRequest === "function" ? base.onResponderTerminationRequest(e) : void 0) !== false;
  }
});

//# sourceMappingURL=../../map/src/Combinator.map
