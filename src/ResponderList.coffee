
{ ArrayOf
  isType
  isKind
  assertType } = require "type-utils"

ResponderSyntheticEvent = require "ResponderSyntheticEvent"
Factory = require "factory"
sync = require "sync"

ResponderMixin = require "./ResponderMixin"
Responder = require "./Responder"

module.exports = Factory "Gesture_ResponderList",

  initArguments: (responders) ->
    assertType responders, ArrayOf [ Responder.Kind, Void ]
    arguments

  customValues:

    touchHandlers: lazy: ->
      self = this
      sync.map ResponderMixin, (_, key) ->
        handler = self["_" + key]
        return -> handler.apply self, arguments

  initFrozenValues: (responders) ->

    _responders: sync.filter responders, (responder) ->
      isKind responder, Responder

  initValues: ->

    _activeResponder: null

  _setActiveResponder: (responder, event) ->
    assertType responder, Responder.Kind
    unless @_activeResponder
      @_activeResponder = responder
      return yes
    unless @_onResponderTerminationRequest event
      responder.touchHandlers.onResponderReject? event
      return no
    @_onResponderTerminate event
    @_clearActiveResponder()
    @_activeResponder = responder
    @_onResponderGrant event
    return yes

  _clearActiveResponder: (event) ->
    @_activeResponder = null
    return

  _shouldRespond: (phase, event) ->
    assert @_activeResponder is null
    shouldRespond = no
    sync.search @_responders, (responder) ->
      return yes unless responder.touchHandlers.onStartShouldSetResponder event
      shouldRespond = @_setActiveResponder responder, event
      return no
    return shouldRespond

  _shouldCapture: (phase, event) ->
    shouldCapture = no
    sync.searchFromEnd @_responders, (responder) ->
      return no if responder is @_activeResponder
      return yes unless responder.touchHandlers.onEndShouldSetResponderCapture event
      shouldCapture = @_setActiveResponder responder, event
      return no
    return shouldCapture

  _onStartShouldSetResponder: (event) ->
    return @_shouldRespond "onStartShouldSetResponder", event

  _onMoveShouldSetResponder: (event) ->
    return @_shouldRespond "onMoveShouldSetResponder", event

  _onEndShouldSetResponder: (event) ->
    return @_shouldRespond "onEndShouldSetResponder", event

  _onStartShouldSetResponderCapture: (event) ->
    return @_shouldCapture "onStartShouldSetResponderCapture", event

  _onMoveShouldSetResponderCapture: (event) ->
    return @_shouldCapture "onMoveShouldSetResponderCapture", event

  _onEndShouldSetResponderCapture: (event) ->
    return @_shouldCapture "onEndShouldSetResponderCapture", event

  _onResponderReject: (event) ->
    @_activeResponder.touchHandlers.onResponderReject event
    return

  _onResponderGrant: (event) ->
    return @_activeResponder.touchHandlers.onResponderGrant event

  _onResponderStart: (event) ->
    @_activeResponder.touchHandlers.onResponderStart event
    return

  _onResponderMove: (event) ->
    @_onMoveShouldSetResponderCapture event
    @_activeResponder.touchHandlers.onResponderMove event
    return

  _onResponderEnd: (event) ->
    @_activeResponder.touchHandlers.onResponderEnd event
    return

  _onResponderRelease: (event) ->
    @_activeResponder.touchHandlers.onResponderRelease event
    @_clearActiveResponder event
    return

  _onResponderTerminate: (event) ->
    @_activeResponder.touchHandlers.onResponderTerminate event
    @_clearActiveResponder event
    return

  _onResponderTerminationRequest: (event) ->
    return @_activeResponder.touchHandlers.onResponderTerminationRequest event
