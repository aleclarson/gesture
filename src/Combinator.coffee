
{ isType, assertType, ArrayOf } = require "type-utils"
{ sync } = require "io"

Factory = require "factory"

Responder = require "./Responder"

RESPONDER_METHODS = {
  "onStartShouldSetResponder"
  "onMoveShouldSetResponder"
  "onStartShouldSetResponderCapture"
  "onMoveShouldSetResponderCapture"
  "onResponderReject"
  "onResponderGrant"
  "onResponderMove"
  "onResponderRelease"
  "onResponderTerminate"
  "onResponderTerminationRequest"
}

module.exports =
Combinator = Factory "Gesture_Combinator",

  initArguments: (responders) ->
    assertType responders, ArrayOf [ Responder.Kind, Object ]
    arguments

  customValues:

    touchHandlers: lazy: ->
      sync.map RESPONDER_METHODS, (key) =>
        this["_" + key].bind this

  initFrozenValues: (responders) ->

    _responders: sync.map responders, (responder) ->
      return responder if isType responder, Object
      return responder.touchHandlers

  initValues: ->

    _activeResponder: null

  # This is only called when '_activeResponder' is null.
  _onStartShouldSetResponder: (e) ->
    for responder in @_responders
      continue if responder.onStartShouldSetResponder?(e) isnt yes
      @_activeResponder = responder
      break
    @_activeResponder?

  # This is only called when '_activeResponder' is null.
  _onMoveShouldSetResponder: (e) ->
    for responder in @_responders
      continue if responder.onMoveShouldSetResponder?(e) isnt yes
      @_activeResponder = responder
      break
    @_activeResponder?

  # This is only called when '_activeResponder' is null.
  _onStartShouldSetResponderCapture: (e) ->
    index = @_responders.length
    while --index >= 0
      responder = @_responders[index]
      continue if responder.onStartShouldSetResponderCapture?(e) isnt yes
      @_activeResponder = responder
      break
    @_activeResponder?

  _onMoveShouldSetResponderCapture: (e) ->
    shouldCapture = no
    index = @_responders.length
    while --index >= 0
      responder = @_responders[index]
      break if responder is @_activeResponder
      continue if responder.onMoveShouldSetResponderCapture?(e) isnt yes
      if @_activeResponder?
        unless @_onResponderTerminationRequest e
          responder.onResponderReject? e
          break
        @_onResponderTerminate e
        @_activeResponder = responder
        @_onResponderGrant e
      else @_activeResponder = responder
      shouldCapture = yes
      break
    shouldCapture

  _onResponderReject: (e) ->
    @_activeResponder.onResponderReject? e

  _onResponderGrant: (e) ->
    @_activeResponder.onResponderGrant? e

  _onResponderMove: (e) ->
    @_onMoveShouldSetResponderCapture e
    @_activeResponder.onResponderMove? e

  _onResponderRelease: (e) ->
    @_activeResponder.onResponderRelease? e
    @_activeResponder = null

  _onResponderTerminate: (e) ->
    @_activeResponder.onResponderTerminate? e
    @_activeResponder = null

  _onResponderTerminationRequest: (e) ->
    @_activeResponder.onResponderTerminationRequest?(e) isnt no
