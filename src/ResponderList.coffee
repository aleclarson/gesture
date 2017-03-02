
isDev = require "isDev"
Type = require "Type"
sync = require "sync"

type = Type "ResponderList"

type.defineArgs [Array]

type.defineProperties

  touchHandlers:
    lazy: -> @_createMixin()

type.defineFrozenValues

  _responders: (responders) -> responders

type.defineValues

  _activeResponder: null

type.defineGetters

  _activeHandlers: -> @_activeResponder.touchHandlers

type.defineMethods

  _setActiveResponder: (responder, event) ->

    unless @_activeResponder
      @_activeResponder = responder
      return yes

    {touchHandlers} = this
    unless touchHandlers.onResponderTerminationRequest event
      responder.touchHandlers.onResponderReject? event
      return no

    touchHandlers.onResponderTerminate event
    @_activeResponder = responder
    touchHandlers.onResponderGrant event
    return yes

  _shouldRespond: (phase, event) ->

    if isDev and @_activeResponder isnt null
      throw Error "An active responder already exists!"

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

  _createMixin: -> do =>

    onStartShouldSetResponder: (event) =>
      @_shouldRespond "onStartShouldSetResponder", event

    onMoveShouldSetResponder: (event) =>
      @_shouldRespond "onMoveShouldSetResponder", event

    onStartShouldSetResponderCapture: (event) =>
      @_shouldCapture "onStartShouldSetResponderCapture", event

    onMoveShouldSetResponderCapture: (event) =>
      @_shouldCapture "onMoveShouldSetResponderCapture", event

    onResponderReject: (event) =>
      @_activeHandlers.onResponderReject event

    onResponderGrant: (event) =>
      @_activeHandlers.onResponderGrant event

    onResponderStart: (event) =>
      @_activeHandlers.onResponderStart event

    onResponderMove: (event) =>
      return if @_shouldCapture "onMoveShouldSetResponderCapture", event
      @_activeHandlers.onResponderMove event

    onResponderEnd: (event) =>
      return unless @_activeResponder
      @_activeHandlers.onResponderEnd event

    onResponderRelease: (event) =>
      @_activeHandlers.onResponderRelease event
      @_activeResponder = null

    onResponderTerminate: (event) =>
      @_activeHandlers.onResponderTerminate event
      @_activeResponder = null

    onResponderTerminationRequest: (event) =>
      @_activeHandlers.onResponderTerminationRequest event

module.exports = type.build()
