
{ sync } = require "io"

emptyFunction = require "emptyFunction"
PanResponder = require "PanResponder"
Factory = require "factory"
Event = require "event"

PAN_METHODS = {
  "onStartShouldSetPanResponder"
  "onMoveShouldSetPanResponder"
  "onStartShouldSetPanResponderCapture"
  "onMoveShouldSetPanResponderCapture"
  "onPanResponderReject"
  "onPanResponderGrant"
  "onPanResponderMove"
  "onPanResponderRelease"
  "onPanResponderTerminate"
  "onPanResponderTerminationRequest"
}

module.exports = Factory "Gesture_Responder",

  optionTypes:
    shouldRespondOnStart: Function
    shouldRespondOnMove: Function
    shouldCaptureOnStart: Function
    shouldCaptureOnMove: Function
    shouldTerminate: Function

  optionDefaults:
    shouldRespondOnStart: emptyFunction.thatReturnsTrue
    shouldRespondOnMove: emptyFunction.thatReturnsFalse
    shouldCaptureOnStart: emptyFunction.thatReturnsFalse
    shouldCaptureOnMove: emptyFunction.thatReturnsFalse
    shouldTerminate: emptyFunction.thatReturnsTrue

  customValues:

    isEnabled:
      get: -> @_enabled
      set: (isEnabled) ->
        @_enabled = isEnabled
        @_onPanResponderTerminate()

    isTouching: get: ->
      @_gesture?.isTouching is yes

    touchHandlers: lazy: ->
      panMethods = sync.map PAN_METHODS, (key) => this["_" + key].bind this
      (PanResponder.create panMethods).panHandlers

  initFrozenValues: ->

    didTouchStart: Event()

    didTouchMove: Event()

    didTouchEnd: Event()

  initValues: (options) ->

    _shouldRespondOnStart: options.shouldRespondOnStart

    _shouldRespondOnMove: options.shouldRespondOnMove

    _shouldCaptureOnStart: options.shouldCaptureOnStart

    _shouldCaptureOnMove: options.shouldCaptureOnMove

    _shouldTerminate: options.shouldTerminate

  initReactiveValues: ->

    _enabled: yes

    _gesture: null

  _onStartShouldSetPanResponder: ->
    return no unless @_enabled
    @_shouldRespondOnStart @_gesture

  _onMoveShouldSetPanResponder: ->
    return no unless @_enabled
    @_shouldRespondOnMove @_gesture

  _onStartShouldSetPanResponderCapture: (gesture) ->
    return no unless @_enabled
    @_gesture = Gesture { gesture, @axis }
    @_shouldCaptureOnStart @_gesture

  _onMoveShouldSetPanResponderCapture: ->
    return no unless @_enabled
    @_shouldCaptureOnMove @_gesture

  _onPanResponderReject: emptyFunction

  _onPanResponderGrant: ->
    @_gesture._onTouchStart()
    @didTouchStart.emit @_gesture

  _onPanResponderMove: ->
    return unless @_gesture
    @_gesture._onTouchMove()
    @didTouchMove.emit @_gesture

  _onPanResponderEnd: ->
    @didTouchEnd.emit @_gesture
    @_gesture = null

  _onPanResponderRelease: ->
    return unless @_gesture
    @_gesture._onTouchEnd yes
    @_onPanResponderEnd()

  _onPanResponderTerminate: ->
    return unless @_gesture
    @_gesture._onTouchEnd no
    @_onPanResponderEnd()

  _onPanResponderTerminationRequest: ->
    return yes unless @_gesture
    @_shouldTerminate @_gesture
