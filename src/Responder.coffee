
# TODO: Implement 'minTouchCount' and 'maxTouchCount'.

{ touchHistory } = require "ResponderTouchHistoryStore"

ResponderSyntheticEvent = require "ResponderSyntheticEvent"
ResponderEventPlugin = require "ResponderEventPlugin"
emptyFunction = require "emptyFunction"
assertType = require "assertType"
getArgProp = require "getArgProp"
assert = require "assert"
Event = require "Event"
Type = require "Type"
hook = require "hook"

Gesture = require "./Gesture"

TouchEvent =
  gesture: Gesture.Kind
  event: [ ResponderSyntheticEvent ]

type = Type "Responder"

type.defineOptions

  # minTouchCount:
  #   type: Number
  #   default: 1
  #
  # maxTouchCount:
  #   type: Number
  #   default: Infinity

  shouldRespondOnStart:
    type: Function
    default: emptyFunction.thatReturnsTrue

  shouldRespondOnMove:
    type: Function
    default: emptyFunction.thatReturnsFalse

  shouldRespondOnEnd:
    type: Function
    default: emptyFunction.thatReturnsFalse

  shouldCaptureOnStart:
    type: Function
    default: emptyFunction.thatReturnsFalse

  shouldCaptureOnMove:
    type: Function
    default: emptyFunction.thatReturnsFalse

  shouldCaptureOnEnd:
    type: Function
    default: emptyFunction.thatReturnsFalse

  shouldTerminate:
    type: Function
    default: emptyFunction.thatReturnsTrue

type.defineStatics

  # All responders that are capable of claiming the active touch.
  activeResponders: []

  # The responder that most recently claimed to the active touch.
  grantedResponder: null

  # Emits when the `grantedResponder` has a new value!
  didResponderGrant: Event()

type.defineProperties

  touchHandlers: get: ->
    @_createMixin()

  isEnabled:
    value: yes
    reactive: yes
    didSet: ->
      # TODO: Does this need a ResponderSyntheticEvent?
      @terminate()

  isActive: get: ->
    @_gesture isnt null

  isGranted: get: ->
    @_isGranted

  gesture: get: ->
    @_gesture

  _gesture:
    value: null
    reactive: yes

  _isGranted:
    value: no
    reactive: yes
    didSet: (newValue, oldValue) ->
      return if newValue is oldValue
      responder = if newValue then this else null
      Responder.grantedResponder = responder
      Responder.didResponderGrant.emit responder

type.defineValues

  _shouldRespondOnStart: getArgProp "shouldRespondOnStart"

  _shouldRespondOnMove: getArgProp "shouldRespondOnMove"

  _shouldRespondOnEnd: getArgProp "shouldRespondOnEnd"

  _shouldCaptureOnStart: getArgProp "shouldCaptureOnStart"

  _shouldCaptureOnMove: getArgProp "shouldCaptureOnMove"

  _shouldCaptureOnEnd: getArgProp "shouldCaptureOnEnd"

  _shouldTerminate: getArgProp "shouldTerminate"

type.defineEvents

  didReject:
    types: TouchEvent

  didGrant:
    types: TouchEvent

  didEnd:
    types: TouchEvent

  didTouchStart:
    types: TouchEvent

  didTouchMove:
    types: TouchEvent

  didTouchEnd:
    types: TouchEvent

type.defineMethods

  terminate: (event, finished) ->

    return unless @isActive

    @__onTouchEnd event, 0

    if @isGranted
      if finished is yes then @__onRelease event
      else @__onTerminate event

    @_deleteGesture()

    return

  __canUpdate: ->
    return @isEnabled and @_gesture and @_gesture.isActive

  __createGesture: (options) ->
    return Gesture options

  __shouldRespondOnStart: (event) ->
    @_shouldRespondOnStart @_gesture, event

  __shouldRespondOnMove: (event) ->
    @_shouldRespondOnMove @_gesture, event

  __shouldRespondOnEnd: (event) ->
    @_shouldRespondOnEnd @_gesture, event

  __shouldCaptureOnStart: (event) ->
    @_shouldCaptureOnStart @_gesture, event

  __shouldCaptureOnMove: (event) ->
    @_shouldCaptureOnMove @_gesture, event

  __shouldCaptureOnEnd: (event) ->
    @_shouldCaptureOnEnd @_gesture, event

  __onTouchStart: (event, touchCount) ->
    @_gesture.__onTouchStart event, touchCount
    @_events.emit "didTouchStart", [ @_gesture, event ]

  __onTouchMove: (event) ->
    @_gesture.__onTouchMove event
    @_events.emit "didTouchMove", [ @_gesture, event ]

  __onTouchEnd: (event, touchCount) ->
    @_gesture.__onTouchEnd event, touchCount
    @_events.emit "didTouchEnd", [ @_gesture, event ]

  __onReject: (event) ->
    @_gesture.__onReject event
    @_events.emit "didReject", [ @_gesture, event ]

  __onGrant: (event) ->
    @_gesture.__onGrant event
    @_events.emit "didGrant", [ @_gesture, event ]

  __onRelease: (event) ->
    @_gesture.__onEnd yes, event
    @_events.emit "didEnd", [ @_gesture, event ]
    return

  __onTerminate: (event) ->
    @_gesture.__onEnd no, event
    @_events.emit "didEnd", [ @_gesture, event ]

  __onTerminationRequest: (event) ->
    return yes unless @_gesture
    return @_shouldTerminate @_gesture, event

  _setActive: (isActive) ->
    responders = Responder.activeResponders
    if isActive then responders.push this
    else responders.splice (responders.indexOf this), 1

  _createGesture: (event) ->
    return if @_gesture
    { pageX, pageY } = event.nativeEvent
    @_gesture = @__createGesture { x: pageX, y: pageY }
    @_setActive yes
    assertType @_gesture, Gesture.Kind

  _deleteGesture: ->
    assert @isActive, "Gesture not yet created!"
    @_isGranted = no
    @_gesture = null

  _onTouchStart: (event, touchCount) ->
    return if @_gesture.touchCount is touchCount
    @__onTouchStart event, touchCount

  _onTouchMove: (event, touchCount) ->

    if @_gesture.touchCount < touchCount
      @__onTouchStart event, touchCount
      return

    # TODO: Test this with multiple fingers.
    assert @_gesture.touchCount is touchCount, "Should call '_onTouchEnd' inside '_onTouchMove'!"

    # if @_gesture.touchCount > touchCount
    #   @_onTouchEnd event, touchCount
    #   return

    @__onTouchMove event

  _onTouchEnd: (event, touchCount) ->
    assert @_gesture.touchCount isnt touchCount
    @__onTouchEnd event, touchCount
    return if touchCount > 0
    @_deleteGesture()
    @_setActive no

  _createMixin: ->

    onStartShouldSetResponder: (event) =>
      @_createGesture event
      return no unless @__canUpdate()
      @_onTouchStart event, touchHistory.numberActiveTouches
      return @__shouldRespondOnStart event

    onMoveShouldSetResponder: (event) =>
      return no unless @__canUpdate()
      @_onTouchMove event, touchHistory.numberActiveTouches
      return @__shouldRespondOnMove event

    onEndShouldSetResponder: (event) =>

      # If we jump from >1 touches to 0 touches,
      # an event is dispatched when no touches are active.
      return no if touchHistory.numberActiveTouches is 0

      return no unless @__canUpdate()
      @_onTouchEnd event, touchHistory.numberActiveTouches
      return @__shouldRespondOnEnd event

    onStartShouldSetResponderCapture: (event) =>
      @_createGesture event
      return no unless @__canUpdate()
      @_onTouchStart event, touchHistory.numberActiveTouches
      return @__shouldCaptureOnStart event

    onMoveShouldSetResponderCapture: (event) =>
      return no unless @__canUpdate()
      @_onTouchMove event, touchHistory.numberActiveTouches
      return @__shouldCaptureOnMove event

    onEndShouldSetResponderCapture: (event) =>

      # If we jump from >1 touches to 0 touches,
      # an event is dispatched when no touches are active.
      if touchHistory.numberActiveTouches is 0
        return no

      return no unless @__canUpdate()
      @_onTouchEnd event, touchHistory.numberActiveTouches
      return @__shouldCaptureOnEnd event

    # Called for every new finger that touches the screen.
    # Called even when not the `grantedResponder`.
    # Simultaneous events are batched.
    onResponderStart: (event) =>
      return unless @__canUpdate()
      @_onTouchStart event, touchHistory.numberActiveTouches

    # Called for every finger that moves.
    # Called even when not the `grantedResponder`.
    # Simultaneous events are batched.
    onResponderMove: (event) =>
      return unless @__canUpdate()
      @_onTouchMove event, touchHistory.numberActiveTouches

    # Called for every finger that stops touching the screen.
    # Called even when not the `grantedResponder`.
    # Simultaneous events are batched.
    onResponderEnd: (event) =>
      return unless @__canUpdate()
      @_onTouchEnd event, touchHistory.numberActiveTouches

    # This must be implemented in case the `grantedResponder`
    # returns false in its `shouldTerminate` callback.
    onResponderReject: (event) =>
      return unless @__canUpdate()
      @__onReject event

    # Must return true if native responders should be blocked.
    onResponderGrant: (event) =>

      unless @isGranted

        assert Responder.grantedResponder is null,
          reason: "The `grantedResponder` must be null before it can be set to a new Responder!"
          failedResponder: this
          grantedResponder: Responder.grantedResponder

        @_isGranted = yes
        @__onGrant event

      return yes

    # This event is detected earlier by ResponderEventPlugin.onFinalTouch()
    onResponderRelease: emptyFunction

    onResponderTerminate: (event) =>

      return unless @__canUpdate()

      # The `terminate` method was called.
      if @gesture.touchCount is 0
        @__onTerminate event
        return

      # A higher responder captured the active touch.
      @__onTouchEnd event, 0
      @__onTerminate event
      @_deleteGesture()
      @_setActive no

    # Must return false to block the capturing responder.
    # Must be the 'grantedResponder' before receiving this event.
    onResponderTerminationRequest: (event) =>
      return yes unless @_gesture
      return @__onTerminationRequest event

module.exports = Responder = type.build()

# Since only the 'grantedResponder' receives the
# last 'onTouchEnd' event, we need to hook into
# 'ResponderEventPlugin' to help out the 'activeResponders'.
hook.before ResponderEventPlugin, "onFinalTouch", (event) ->
  responders = Responder.activeResponders
  return if responders.length is 0
  for responder in responders
    responder.terminate event, yes
  responders.length = 0
