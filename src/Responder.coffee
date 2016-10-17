
# TODO: Implement 'minTouchCount' and 'maxTouchCount'.

{touchHistory} = require "ResponderTouchHistoryStore"

ResponderSyntheticEvent = require "ResponderSyntheticEvent"
ResponderEventPlugin = require "ResponderEventPlugin"
emptyFunction = require "emptyFunction"
assertType = require "assertType"
Event = require "Event"
isDev = require "isDev"
Type = require "Type"
hook = require "hook"

ResponderList = require "./ResponderList"
Gesture = require "./Gesture"

TouchEvent = {gesture: Gesture.Kind, event: ResponderSyntheticEvent}

type = Type "Responder"

type.defineOptions
  # minTouchCount: Number.withDefault 1
  # maxTouchCount: Number.withDefault Infinity
  shouldRespondOnStart: Function.withDefault emptyFunction.thatReturnsTrue
  shouldRespondOnMove: Function.withDefault emptyFunction.thatReturnsFalse
  shouldRespondOnEnd: Function.withDefault emptyFunction.thatReturnsFalse
  shouldCaptureOnStart: Function.withDefault emptyFunction.thatReturnsFalse
  shouldCaptureOnMove: Function.withDefault emptyFunction.thatReturnsFalse
  shouldCaptureOnEnd: Function.withDefault emptyFunction.thatReturnsFalse
  shouldTerminate: Function.withDefault emptyFunction.thatReturnsTrue

type.defineValues (options) ->

  _shouldRespondOnStart: options.shouldRespondOnStart

  _shouldRespondOnMove: options.shouldRespondOnMove

  _shouldRespondOnEnd: options.shouldRespondOnEnd

  _shouldCaptureOnStart: options.shouldCaptureOnStart

  _shouldCaptureOnMove: options.shouldCaptureOnMove

  _shouldCaptureOnEnd: options.shouldCaptureOnEnd

  _shouldTerminate: options.shouldTerminate

type.defineProperties

  isEnabled:
    value: yes
    reactive: yes
    didSet: -> @terminate()

  touchHandlers:
    lazy: -> @_createMixin()

  _gesture:
    value: null
    reactive: yes

  _isGranted:
    value: no
    reactive: yes
    didSet: (newValue, oldValue) ->
      return if newValue is oldValue
      if newValue
        Responder.current = this
        Responder.didGrant.emit this
      else
        Responder.current = null
        Responder.didRelease.emit this

type.defineEvents

  didReject: TouchEvent

  didGrant: TouchEvent

  didEnd: TouchEvent

  didTouchStart: TouchEvent

  didTouchMove: TouchEvent

  didTouchEnd: TouchEvent

type.defineGetters

  gesture: -> @_gesture

  isActive: -> @_gesture and @_gesture.isActive

  isGranted: -> @_isGranted

type.defineMethods

  join: (responder) ->
    if Array.isArray responder
      responders = responder.filter (item) -> item instanceof Responder
      return this unless responders.length
      responders.push this
      return ResponderList responders
    return this unless responder instanceof Responder
    return ResponderList [this, responder]

  finish: (nativeEvent) ->
    assertType nativeEvent, Object.Maybe
    if @isActive
      event = @_createEvent nativeEvent
      @_stopTracking()
      @_gestureEnded event, yes
    return

  terminate: (nativeEvent) ->
    assertType nativeEvent, Object.Maybe
    if @isActive
      event = @_createEvent nativeEvent
      @_stopTracking()
      @_gestureEnded event, no
    return

  # TODO: Store most recent `nativeEvent` to use as default values?
  _createEvent: (nativeEvent = {}) ->
    nativeEvent.touches ?= []
    new ResponderSyntheticEvent(
      dispatchConfig = {},
      dispatchMarker = "",
      nativeEvent,
      nativeEvent.target
    )

  _gestureBegan: (event) ->

    if isDev and @_gesture
      throw Error "Must reset '_gesture' before calling '_gestureBegan'!"

    { pageX, pageY } = event.nativeEvent
    @_gesture = @__createGesture { x: pageX, y: pageY }
    assertType @_gesture, Gesture.Kind
    Responder.tracking.push this
    return

  _stopTracking: ->
    {tracking} = Responder
    index = tracking.indexOf this
    tracking.splice index, 1
    return

  _gestureEnded: (event, finished) ->

    if isDev and not @_gesture
      throw Error "Must set '_gesture' before calling '_gestureEnded'!"

    @_touchEnded event
    if @_isGranted
      if finished
      then @__onRelease event
      else @__onTerminate event
    @_gesture = null
    return

  _touchesChanged: (newTouches) ->

    if isDev and not @_gesture
      throw Error "Must set '_gesture' before calling '_touchesChanged'!"

    oldTouches = @_gesture.touches
    touchCount = oldTouches.length
    return yes if touchCount isnt newTouches.length
    index = -1
    while ++index < touchCount
      return yes if oldTouches[index].identifier isnt newTouches[index].identifier
    return no

  # Avoids calling '__onTouchStart' when possible.
  _touchBegan: (event) ->

    if isDev and not @isActive
      throw Error "Must be active when calling '_touchBegan'!"

    {touches} = event.nativeEvent
    if @_touchesChanged touches
      @__onTouchStart event
    return

  _touchMoved: (event) ->

    if isDev and not @isActive
      throw Error "Must be active when calling '_touchMoved'!"

    {touches} = event.nativeEvent

    if isDev and @_touchesChanged touches
      throw Error "Must have same touches!"

    @__onTouchMove event
    return

  _touchEnded: (event) ->

    if isDev and not @isActive
      throw Error "Must be active when calling '_touchEnded'!"

    {touches} = event.nativeEvent
    if @_touchesChanged touches
      @__onTouchEnd event
    return

  _createMixin: -> do =>

    onStartShouldSetResponder: (event) =>

      @_gesture or @_gestureBegan event

      if @__canUpdate()
        @_touchBegan event
        return @__shouldRespondOnStart event
      return no

    onMoveShouldSetResponder: (event) =>
      if @__canUpdate()
        @_touchMoved event
        return @__shouldRespondOnMove event
      return no

    onEndShouldSetResponder: (event) =>

      # If we jump from >1 touches to 0 touches,
      # an event is dispatched when no touches are active.
      return no if touchHistory.numberActiveTouches is 0

      if @__canUpdate()
        @_touchEnded event
        return @__shouldRespondOnEnd event
      return no

    onStartShouldSetResponderCapture: (event) =>

      @_gesture or @_gestureBegan event

      if @__canUpdate()
        @_touchBegan event
        return @__shouldCaptureOnStart event
      return no

    onMoveShouldSetResponderCapture: (event) =>
      if @__canUpdate()
        @_touchMoved event
        return @__shouldCaptureOnMove event
      return no

    onEndShouldSetResponderCapture: (event) =>

      # If we jump from >1 touches to 0 touches,
      # an event is dispatched when no touches are active.
      return no if touchHistory.numberActiveTouches is 0

      if @__canUpdate()
        @_touchEnded event
        return @__shouldCaptureOnEnd event
      return no

    # Called for every new finger that touches the screen.
    # Called even when not `Responder.current`.
    # Simultaneous events are batched.
    onResponderStart: (event) =>
      @__canUpdate() and @_touchBegan event

    # Called for every finger that moves.
    # Called even when not `Responder.current`.
    # Simultaneous events are batched.
    onResponderMove: (event) =>
      @__canUpdate() and @_touchMoved event

    # Called for every finger that stops touching the screen.
    # Called even when not `Responder.current`.
    # Simultaneous events are batched.
    onResponderEnd: (event) =>
      @__canUpdate() and @_touchEnded event

    # This must be implemented in case `Responder.current`
    # returns false in its `shouldTerminate` callback.
    onResponderReject: (event) =>
      @__canUpdate() and @__onReject event

    # Must return true if native responders should be blocked.
    onResponderGrant: (event) =>

      if not @_isGranted

        if Responder.current isnt null
          throw Error "`Responder.current` must be null before a new Responder can be set!"

        @_isGranted = yes
        @__onGrant event

      return yes

    # This event is detected earlier by ResponderEventPlugin.onFinalTouch()
    onResponderRelease: emptyFunction

    onResponderTerminate: (event) =>
      if @__canUpdate()
        @_stopTracking()
        @_gestureEnded event
      return

    # Must return false to block the capturing responder.
    # Must be `Responder.current` before receiving this event.
    onResponderTerminationRequest: (event) =>
      return yes if not @_gesture
      return @__onTerminationRequest event

type.defineHooks

  __canUpdate: ->
    @isEnabled and @isActive

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

  __onTouchStart: (event) ->
    @_gesture.__onTouchStart event
    @__events.didTouchStart @_gesture, event

  __onTouchMove: (event) ->
    @_gesture.__onTouchMove event
    @__events.didTouchMove @_gesture, event

  __onTouchEnd: (event) ->
    @_gesture.__onTouchEnd event
    @__events.didTouchEnd @_gesture, event

  __onReject: (event) ->
    @_gesture.__onReject event
    @__events.didReject @_gesture, event

  __onGrant: (event) ->
    @_gesture.__onGrant event
    @__events.didGrant @_gesture, event

  __onRelease: (event) ->
    @_gesture.__onEnd yes, event
    @_isGranted = no
    @__events.didEnd @_gesture, event

  __onTerminate: (event) ->
    @_gesture.__onEnd no, event
    @_isGranted = no
    @__events.didEnd @_gesture, event

  __onTerminationRequest: (event) ->
    return yes if not @_gesture
    return @_shouldTerminate @_gesture, event

type.defineStatics

  # All responders that are capable of claiming the active touch.
  tracking: []

  # The responder that most recently claimed to the active touch.
  current: null

  # Emits when `Responder.current` is set to a Responder.
  didGrant: Event()

  # Emits when `Responder.current` is set to null.
  didRelease: Event()

module.exports = Responder = type.build()

# Since only `Responder.current` receives the last "onTouchEnd"
# event, we need to hook into `ResponderEventPlugin` for the
# responders in `Responder.tracking`!
# NOTE: 'onFinalTouch' is added by a fork of 'react'.
hook.before ResponderEventPlugin, "onFinalTouch", (event) ->
  {tracking} = Responder

  return if tracking.length is 0
  tracking.forEach (responder) ->
    if responder.__canUpdate()
      responder._gestureEnded event, yes
    return

  tracking.length = 0
  return
