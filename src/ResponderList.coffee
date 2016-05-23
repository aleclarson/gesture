
{ Void, assertType } = require "type-utils"

sync = require "sync"
Type = require "Type"

Responder = require "./Responder"

type = Type "ResponderList"

type.createArguments (args) ->
  assertType args[0], Array
  args[0] = sync.filter args[0], (responder) -> responder instanceof Responder
  return args

type.returnExisting (responders) ->
  return null if responders.length is 0
  return responders[0] if responders.length is 1

type.defineProperties

  touchHandlers: lazy: ->
    @_createMixin()

type.defineFrozenValues

  _responders: (responders) -> responders

type.defineValues

  _activeResponder: null

type.defineMethods

  _setActiveResponder: (responder, event) ->
    assertType responder, Responder.Kind
    unless @_activeResponder
      @_activeResponder = responder
      return yes
    unless @_onResponderTerminationRequest event
      responder.touchHandlers.onResponderReject? event
      return no
    @_onResponderTerminate event
    @_activeResponder = responder
    @_onResponderGrant event
    return yes

  _shouldRespond: (phase, event) ->
    assert @_activeResponder is null
    shouldRespond = no
    sync.search @_responders, (responder) ->
      return yes unless responder.touchHandlers[phase] event
      shouldRespond = @_setActiveResponder responder, event
      return no
    return shouldRespond

  _shouldCapture: (phase, event) ->
    shouldCapture = no
    sync.searchFromEnd @_responders, (responder) ->
      return no if responder is @_activeResponder
      return yes unless responder.touchHandlers[phase] event
      shouldCapture = @_setActiveResponder responder, event
      return no
    return shouldCapture

  _createMixin: ->

    onStartShouldSetResponder: (event) =>
      @_shouldRespond "onStartShouldSetResponder", event

    onMoveShouldSetResponder: (event) =>
      @_shouldRespond "onMoveShouldSetResponder", event

    onEndShouldSetResponder: (event) =>
      @_shouldRespond "onEndShouldSetResponder", event

    onStartShouldSetResponderCapture: (event) =>
      @_shouldCapture "onStartShouldSetResponderCapture", event

    onMoveShouldSetResponderCapture: (event) =>
      @_shouldCapture "onMoveShouldSetResponderCapture", event

    onEndShouldSetResponderCapture: (event) =>
      @_shouldCapture "onEndShouldSetResponderCapture", event

    onResponderReject: (event) =>
      @_activeResponder.touchHandlers.onResponderReject event

    onResponderGrant: (event) =>
      @_activeResponder.touchHandlers.onResponderGrant event

    onResponderStart: (event) =>
      @_activeResponder.touchHandlers.onResponderStart event

    onResponderMove: (event) =>
      @_onMoveShouldSetResponderCapture event
      @_activeResponder.touchHandlers.onResponderMove event

    onResponderEnd: (event) =>
      @_activeResponder.touchHandlers.onResponderEnd event

    onResponderRelease: (event) =>
      @_activeResponder.touchHandlers.onResponderRelease event
      @_activeResponder = null

    onResponderTerminate: (event) =>
      @_activeResponder.touchHandlers.onResponderTerminate event
      @_activeResponder = null

    onResponderTerminationRequest: (event) =>
      @_activeResponder.touchHandlers.onResponderTerminationRequest event

module.exports = type.build()
