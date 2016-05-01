
{ ArrayOf
  isType
  isKind
  assertType } = require "type-utils"

ResponderSyntheticEvent = require "ResponderSyntheticEvent"
Factory = require "factory"
sync = require "sync"

Responder = require "./Responder"

module.exports = Factory "Gesture_ResponderList",

  initArguments: (responders) ->
    assertType responders, ArrayOf [ Responder.Kind, Void ]
    responders = sync.filter responders, (responder) -> isKind responder, Responder
    [ responders ]

  getFromCache: (responders) ->
    return null if responders.length is 0
    return responders[0] if responders.length is 1

  customValues:

    touchHandlers: lazy: ->
      @_createMixin()

    _activeHandlers: get: ->
      @_activeResponder.touchHandlers

  initFrozenValues: (responders) ->

    _responders: responders

  initValues: ->

    _activeResponder: null

  _setActiveResponder: (responder, event) ->
    assertType responder, Responder.Kind
    unless @_activeResponder
      @_activeResponder = responder
      return yes
    unless @_activeHandlers.onResponderTerminationRequest event
      responder.touchHandlers.onResponderReject? event
      return no
    @_activeHandlers.onResponderTerminate event
    @_activeResponder = responder
    @_activeHandlers.onResponderGrant event
    return yes

  _shouldRespond: (phase, event) ->
    assert @_activeResponder is null
    shouldRespond = no
    sync.search @_responders, (responder) =>
      return yes unless responder.touchHandlers[phase] event
      shouldRespond = @_setActiveResponder responder, event
      return no
    return shouldRespond

  _shouldCapture: (phase, event) ->
    shouldCapture = no
    sync.searchFromEnd @_responders, (responder) =>
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
      @_activeHandlers.onResponderReject event

    onResponderGrant: (event) =>
      @_activeHandlers.onResponderGrant event

    onResponderStart: (event) =>
      @_activeHandlers.onResponderStart event

    onResponderMove: (event) =>
      # Allow a responder in this ResponderList to become active.
      @_shouldCapture "onMoveShouldSetResponderCapture", event
      @_activeHandlers.onResponderMove event

    onResponderEnd: (event) =>
      @_activeHandlers.onResponderEnd event

    onResponderRelease: (event) =>
      @_activeHandlers.onResponderRelease event
      @_activeResponder = null

    onResponderTerminate: (event) =>
      @_activeHandlers.onResponderTerminate event
      @_activeResponder = null

    onResponderTerminationRequest: (event) =>
      @_activeHandlers.onResponderTerminationRequest event
