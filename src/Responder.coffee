
# TODO: Implement 'minTouchCount' and 'maxTouchCount'.

ResponderSyntheticEvent = require "react-native/lib/ResponderSyntheticEvent"
ResponderEventPlugin = require "react-native/lib/ResponderEventPlugin"
EventPluginUtils = require "react-native/lib/EventPluginUtils"
EventPluginHub = require "react-native/lib/EventPluginHub"
ResponderCache = require "react-native/lib/ResponderCache"

emptyFunction = require "emptyFunction"
assertType = require "assertType"
Event = require "eve"
isDev = require "isDev"
Type = require "Type"

ResponderList = require "./ResponderList"
Gesture = require "./Gesture"

type = Type "Responder"

type.defineArgs ->

  types:
    # minTouchCount: Number
    # maxTouchCount: Number
    shouldRespondOnStart: Function
    shouldRespondOnMove: Function
    shouldRespondOnEnd: Function
    shouldCaptureOnStart: Function
    shouldCaptureOnMove: Function
    shouldCaptureOnEnd: Function
    shouldTerminate: Function

  defaults:
    # minTouchCount: 1
    # maxTouchCount: Infinity
    shouldRespondOnStart: emptyFunction.thatReturnsTrue
    shouldRespondOnMove: emptyFunction.thatReturnsFalse
    shouldRespondOnEnd: emptyFunction.thatReturnsFalse
    shouldCaptureOnStart: emptyFunction.thatReturnsFalse
    shouldCaptureOnMove: emptyFunction.thatReturnsFalse
    shouldCaptureOnEnd: emptyFunction.thatReturnsFalse
    shouldTerminate: emptyFunction.thatReturnsTrue

type.defineValues (options) ->

  didReject: Event()

  didGrant: Event()

  didRelease: Event()

  didTouchStart: Event()

  didTouchMove: Event()

  didTouchEnd: Event()

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
        Responder.granted[@_gesture.target] = this
        Responder.didGrant.emit this
      else
        delete Responder.granted[@_gesture.target]
        Responder.didRelease.emit this

type.defineGetters

  gesture: -> @_gesture

  isActive: -> if @_gesture then @_gesture.isActive else no

  isGranted: -> @_isGranted

type.defineMethods

  join: (responder) ->

    if Array.isArray responder
      responders = responder.filter (item) ->
        item instanceof Responder

      if responders.length
        responders.unshift this
        return ResponderList responders
      return this

    if responder instanceof Responder
    then ResponderList [this, responder]
    else this

  finish: (nativeEvent) ->
    assertType nativeEvent, Object.Maybe
    if @isActive
      event = @_createEvent nativeEvent
      @_gestureEnded event, yes
    return

  terminate: (nativeEvent) ->
    assertType nativeEvent, Object.Maybe
    if @isActive
      event = @_createEvent nativeEvent
      @_gestureEnded event, no
    return

  # TODO: Store most recent `nativeEvent` to use as default values?
  _createEvent: (nativeEvent = {}) ->
    nativeEvent.touches ?= []
    # TODO: Use `ResponderSyntheticEvent.getPooled`
    new ResponderSyntheticEvent dispatchConfig = {}, dispatchMarker = "", nativeEvent, nativeEvent.target

  _gestureBegan: ({ nativeEvent }) ->

    if isDev and @_gesture
      throw Error "Must reset '_gesture' before calling '_gestureBegan'!"

    @_gesture = @__createGesture
      target: nativeEvent.target
      touchHistory: nativeEvent.touchHistory

    if isDev
      assertType @_gesture, Gesture.Kind
    return

  _gestureEnded: (event, finished) ->

    if isDev and not @_gesture
      throw Error "Must call '_gestureBegan' before '_gestureEnded'!"

    if isDev and not @_gesture.isActive
      throw Error "Must only call '_gestureEnded' once!"

    @__onTouchEnd event

    if @_isGranted
      @_isGranted = no
      @__onRelease event, finished
    else
      @_gesture.__onRelease event, finished

    @_gesture = null
    return

  _createMixin: -> do =>

    onStartShouldSetResponder: (event) =>

      unless @_gesture
        @_gestureBegan event

      if @__canUpdate()
      then @__shouldRespondOnStart event
      else no

    onMoveShouldSetResponder: (event) =>
      if @__canUpdate()
      then @__shouldRespondOnMove event
      else no

    onStartShouldSetResponderCapture: (event) =>
      @_gesture or @_gestureBegan event
      if @__canUpdate()
        @__onTouchStart event
        return @__shouldCaptureOnStart event
      return no

    onMoveShouldSetResponderCapture: (event) =>
      if @__canUpdate()
        @__onTouchMove event
        return @__shouldCaptureOnMove event
      return no

    onResponderStart: (event) =>
      if @__canUpdate()
        @__onTouchStart event
      return

    onResponderMove: (event) =>
      if @__canUpdate()
        @__onTouchMove event
      return

    onResponderEnd: (event) =>

      if @_isGranted
        return unless @__canUpdate()
        @__onTouchEnd event

      else if @isActive and @_gesture.touchHistory.numberActiveTouches is 0
        @_gestureEnded event, yes
      return

    onResponderReject: (event) =>
      if @__canUpdate()
        @__onReject event
        @_gestureEnded event, no
      return

    onResponderGrant: (event) =>

      unless @_isGranted
        @_isGranted = yes
        @__onGrant event

      # Block the native responder.
      return yes

    onResponderRelease: (event) =>
      if @__canUpdate()
        @_gestureEnded event, yes
      return

    onResponderTerminate: (event) =>
      if @__canUpdate()
        @_gestureEnded event, no
      return

    # Must return false to block the capturing responder.
    # Must be in `Responder.granted` before receiving this event.
    onResponderTerminationRequest: (event) =>
      if @_gesture
      then @__onTerminationRequest event
      else yes

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
    @didTouchStart.emit @_gesture, event

  __onTouchMove: (event) ->
    @_gesture.__onTouchMove event
    @didTouchMove.emit @_gesture, event

  __onTouchEnd: (event) ->
    @_gesture.__onTouchEnd event
    @didTouchEnd.emit @_gesture, event

  __onReject: (event) ->
    @_gesture.__onReject event
    @didReject.emit @_gesture, event

  __onGrant: (event) ->
    @_gesture.__onGrant event
    @didGrant.emit @_gesture, event

  __onRelease: (event, finished) ->
    @_gesture.__onRelease event, finished
    @didRelease.emit @_gesture, event

  __onTerminationRequest: (event) ->
    return yes if not @_gesture
    return @_shouldTerminate @_gesture, event

type.defineStatics

  # Responders that have "captured" a gesture
  granted: Object.create null

  # Emits when a Responder is added to `Responder.granted`
  didGrant: Event()

  # Emits when a Responder is removed from `Responder.granted`
  didRelease: Event()

  eventNames: [
    "onStartShouldSetResponder"
    "onStartShouldSetResponderCapture"
    "onMoveShouldSetResponder"
    "onMoveShouldSetResponderCapture"
    "onResponderReject"
    "onResponderGrant"
    "onResponderStart"
    "onResponderMove"
    "onResponderEnd"
    "onResponderRelease"
    "onResponderTerminate"
    "onResponderTerminationRequest"
  ]

module.exports = Responder = type.build()

ResponderEventPlugin.injection.injectGlobalTouchHandler
  onTouchEnd: (event) ->
    {target, touchHistory} = event

    # If the target is granted, exclude it from the dispatch.
    targetInst = EventPluginUtils.getInstanceFromNode target
    parentInst =
      if ResponderCache.hasResponder targetInst
      then EventPluginUtils.getParentInstance targetInst
      else targetInst

    listeners = []
    instances = []
    while parentInst isnt null
      if listener = EventPluginHub.getListener parentInst, "onResponderEnd"
        listeners.push listener
        instances.push parentInst
      parentInst = EventPluginUtils.getParentInstance parentInst

    # Call listeners top-down.
    for listener, index in listeners
      listener event, instances[index]
    return
