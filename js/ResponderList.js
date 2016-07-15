var Responder, Type, sync, type;

sync = require("sync");

Type = require("Type");

Responder = require("./Responder");

type = Type("ResponderList");

type.argumentTypes = {
  responders: Array
};

type.initArguments(function(args) {
  args[0] = sync.filter(args[0], function(responder) {
    return responder instanceof Responder;
  });
  return args;
});

type.returnExisting(function(responders) {
  if (responders.length === 0) {
    return null;
  }
  if (responders.length === 1) {
    return responders[0];
  }
});

type.defineProperties({
  touchHandlers: {
    lazy: function() {
      return this._createMixin();
    }
  }
});

type.defineFrozenValues({
  _responders: function(responders) {
    return responders;
  }
});

type.defineValues({
  _activeResponder: null
});

type.defineMethods({
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
      if (!responder.touchHandlers[phase](event)) {
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
      if (!responder.touchHandlers[phase](event)) {
        return true;
      }
      shouldCapture = this._setActiveResponder(responder, event);
      return false;
    });
    return shouldCapture;
  },
  _createMixin: function() {
    return {
      onStartShouldSetResponder: (function(_this) {
        return function(event) {
          return _this._shouldRespond("onStartShouldSetResponder", event);
        };
      })(this),
      onMoveShouldSetResponder: (function(_this) {
        return function(event) {
          return _this._shouldRespond("onMoveShouldSetResponder", event);
        };
      })(this),
      onEndShouldSetResponder: (function(_this) {
        return function(event) {
          return _this._shouldRespond("onEndShouldSetResponder", event);
        };
      })(this),
      onStartShouldSetResponderCapture: (function(_this) {
        return function(event) {
          return _this._shouldCapture("onStartShouldSetResponderCapture", event);
        };
      })(this),
      onMoveShouldSetResponderCapture: (function(_this) {
        return function(event) {
          return _this._shouldCapture("onMoveShouldSetResponderCapture", event);
        };
      })(this),
      onEndShouldSetResponderCapture: (function(_this) {
        return function(event) {
          return _this._shouldCapture("onEndShouldSetResponderCapture", event);
        };
      })(this),
      onResponderReject: (function(_this) {
        return function(event) {
          return _this._activeResponder.touchHandlers.onResponderReject(event);
        };
      })(this),
      onResponderGrant: (function(_this) {
        return function(event) {
          return _this._activeResponder.touchHandlers.onResponderGrant(event);
        };
      })(this),
      onResponderStart: (function(_this) {
        return function(event) {
          return _this._activeResponder.touchHandlers.onResponderStart(event);
        };
      })(this),
      onResponderMove: (function(_this) {
        return function(event) {
          _this._onMoveShouldSetResponderCapture(event);
          return _this._activeResponder.touchHandlers.onResponderMove(event);
        };
      })(this),
      onResponderEnd: (function(_this) {
        return function(event) {
          return _this._activeResponder.touchHandlers.onResponderEnd(event);
        };
      })(this),
      onResponderRelease: (function(_this) {
        return function(event) {
          _this._activeResponder.touchHandlers.onResponderRelease(event);
          return _this._activeResponder = null;
        };
      })(this),
      onResponderTerminate: (function(_this) {
        return function(event) {
          _this._activeResponder.touchHandlers.onResponderTerminate(event);
          return _this._activeResponder = null;
        };
      })(this),
      onResponderTerminationRequest: (function(_this) {
        return function(event) {
          return _this._activeResponder.touchHandlers.onResponderTerminationRequest(event);
        };
      })(this)
    };
  }
});

module.exports = type.build();

//# sourceMappingURL=map/ResponderList.map
