
# TODO: Implement 'minTouchCount' and 'maxTouchCount'.

{ touchHistory } = require "ResponderTouchHistoryStore"
{ assertType } = require "type-utils"

ResponderEventPlugin = require "ResponderEventPlugin"
emptyFunction = require "emptyFunction"
Immutable = require "immutable"
Factory = require "factory"
Event = require "event"
hook = require "hook"
sync = require "sync"

ResponderMixin = require "./ResponderMixin"
Gesture = require "./Gesture"

activeResponder = null
didSetActiveResponder = Event()

eligibleResponders = Immutable.OrderedSet()
hook.before ResponderEventPlugin, "onFinalTouch", (event) ->
  return if eligibleResponders.size is 0
  eligibleResponders.forEach (responder) ->
    return yes unless responder._gesture
    responder._onTouchEnd event
    responder._deinitGesture()
    return yes
  eligibleResponders = Immutable.OrderedSet()

module.exports =
Responder = Factory "Gesture_Responder",

  statics:

    activeResponder: get: ->
      activeResponder

    didSetActiveResponder: get: ->
      didSetActiveResponder.listenable

  optionTypes:
    minTouchCount: Number
    maxTouchCount: Number
    shouldRespondOnStart: Function
    shouldRespondOnMove: Function
    shouldRespondOnEnd: Function
    shouldCaptureOnStart: Function
    shouldCaptureOnMove: Function
    shouldCaptureOnEnd: Function
    shouldTerminate: Function

  optionDefaults:
    minTouchCount: 1
    maxTouchCount: Infinity
    shouldRespondOnStart: emptyFunction.thatReturnsTrue
    shouldRespondOnMove: emptyFunction.thatReturnsFalse
    shouldRespondOnEnd: emptyFunction.thatReturnsFalse
    shouldCaptureOnStart: emptyFunction.thatReturnsFalse
    shouldCaptureOnMove: emptyFunction.thatReturnsFalse
    shouldCaptureOnEnd: emptyFunction.thatReturnsFalse
    shouldTerminate: emptyFunction.thatReturnsTrue

  customValues:

    isEnabled:
      get: -> @_enabled
      set: (isEnabled) ->
        @_enabled = isEnabled
        @_onTerminate() # TODO: Do we need to create a ResponderSyntheticEvent here?

    isTouching: get: ->
      @_active

    isCaptured: get: ->
      @_captured

    touchHandlers: lazy: ->
      self = this
      sync.map ResponderMixin, (handler) ->
        return -> handler.apply self, arguments

    _gestureType: lazy: ->
      @_getGestureType()

  initFrozenValues: (options) ->

    _options: options

    didReject: Event()

    didGrant: Event()

    didEnd: Event()

    didTouchStart: Event()

    didTouchMove: Event()

    didTouchEnd: Event()

  initReactiveValues: ->

    _enabled: yes

    _active: no

    _captured: no

    _ended: no

    _gesture: null

    _lastGesture: null

  _needsUpdate: ->
    unless @_enabled
      return no
    if @_ended
      return no
    if @_gesture
      return @_gesture.needsUpdate
    return yes

  _setActiveResponder: ->
    return if activeResponder
    didSetActiveResponder.emit activeResponder = this
    return

  _clearActiveResponder: ->
    return if activeResponder isnt this
    didSetActiveResponder.emit activeResponder = null
    return

  _setEligibleResponder: ->
    eligibleResponders = eligibleResponders.add this
    @_ended = no
    return

  _clearEligibleResponder: ->
    eligibleResponders = eligibleResponders.remove this
    return

  _getGestureType: ->
    return Gesture

  _initGesture: (event) ->
    assert not @_active
    @_active = yes
    @_gesture = @_gestureType { event }
    return

  _deinitGesture: ->
    assertType @_gesture, Gesture.Kind
    @_clearEligibleResponder()
    @_active = no
    @_ended = yes
    if @_captured
      @didEnd.emit @_gesture
      @_captured = no
    @_lastGesture = @_gesture
    @_gesture = null
    @_clearActiveResponder()
    return

  _shouldRespondOnStart: ->
    return @_options.shouldRespondOnStart @_gesture

  _shouldRespondOnMove: ->
    return @_options.shouldRespondOnMove @_gesture

  _shouldRespondOnEnd: ->
    return @_options.shouldRespondOnEnd @_gesture

  _shouldCaptureOnStart: ->
    return @_options.shouldCaptureOnStart @_gesture

  _shouldCaptureOnMove: ->
    return @_options.shouldCaptureOnMove @_gesture

  _shouldCaptureOnEnd: ->
    return @_options.shouldCaptureOnEnd @_gesture

  _onTouchStart: (event) ->
    return no if @_active and @_gesture.touchCount is touchHistory.numberActiveTouches
    @_initGesture event unless @_active
    @_gesture._onTouchStart event
    @didTouchStart.emit @_gesture, event
    return yes

  _onTouchMove: (event) ->
    @_gesture._onTouchMove event
    @didTouchMove.emit @_gesture, event
    return

  _onTouchEnd: (event) ->
    return no if @_gesture.touchCount is touchHistory.numberActiveTouches
    @_gesture._onTouchEnd event
    @didTouchEnd.emit @_gesture, event
    return yes

  _onReject: (event) ->
    @_gesture._onReject event
    @didReject.emit @_gesture, event
    return

  _onGrant: (event) ->
    assert not @_captured
    @_captured = yes
    @_gesture._onGrant event
    @didGrant.emit @_gesture, event
    return

  _onEnd: (event) ->
    @_gesture._onEnd yes, event
    @_deinitGesture()
    return

  _onTerminate: (event) ->
    @_gesture._onEnd no, event
    @_deinitGesture()
    return

  _onTerminationRequest: (event) ->
    return @_options.shouldTerminate @_gesture, event
