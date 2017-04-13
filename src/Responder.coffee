
# TODO: Implement 'minTouchCount' and 'maxTouchCount'.

ResponderSyntheticEvent = require "react-native/lib/ResponderSyntheticEvent"

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
    shouldCaptureOnStart: Function
    shouldCaptureOnMove: Function
    shouldTerminate: Function

  defaults:
    # minTouchCount: 1
    # maxTouchCount: Infinity
    shouldRespondOnStart: emptyFunction.thatReturnsTrue
    shouldRespondOnMove: emptyFunction.thatReturnsFalse
    shouldCaptureOnStart: emptyFunction.thatReturnsFalse
    shouldCaptureOnMove: emptyFunction.thatReturnsFalse
    shouldTerminate: emptyFunction.thatReturnsTrue

type.defineValues ->

  touchHandlers: @_createTouchHandlers()

  didReject: Event()

  didGrant: Event()

  didRelease: Event()

  didTouchStart: Event()

  didTouchMove: Event()

  didTouchEnd: Event()

type.defineGetters

  touchCount: -> @_touchCount

  gesture: -> @_gesture

  isActive: -> if @_gesture then @_gesture.isActive else no

  isGranted: -> @_isGranted

type.definePrototype

  isEnabled:
    get: -> @_isEnabled
    set: (newValue, oldValue) ->
      if newValue isnt oldValue
        @_isEnabled = newValue
        @terminate()
      return

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
    @_terminate nativeEvent, yes

  terminate: (nativeEvent) ->
    @_terminate nativeEvent, no

type.defineStatics

  # Responders that have "captured" a gesture
  granted: Object.create null

  # Emits when a Responder is added to `Responder.granted`
  didGrant: Event()

  # Emits when a Responder is removed from `Responder.granted`
  didRelease: Event()

  eventNames: get: ->
    Object.keys ResponderMixin

#
# Subclassing
#

type.defineHooks

  __createGesture: Gesture

  __shouldRespondOnStart: (event) ->
    @_shouldRespondOnStart @_gesture, event

  __shouldRespondOnMove: (event) ->
    @_shouldRespondOnMove @_gesture, event

  __shouldCaptureOnStart: (event) ->
    @_shouldCaptureOnStart @_gesture, event

  __shouldCaptureOnMove: (event) ->
    @_shouldCaptureOnMove @_gesture, event

  __onTouchStart: (event) ->
    @_gesture.__onTouchStart event
    @didTouchStart.emit @_gesture, event
    return

  __onTouchMove: (event) ->
    @_gesture.__onTouchMove event
    @didTouchMove.emit @_gesture, event
    return

  __onTouchEnd: (event) ->
    @_gesture.__onTouchEnd event
    @didTouchEnd.emit @_gesture, event
    return

  __onReject: (event) ->
    @_gesture.__onReject event
    @didReject.emit @_gesture, event
    return

  __onGrant: (event) ->
    @_gesture.__onGrant event
    @didGrant.emit @_gesture, event
    return

  __onRelease: (event, finished) ->
    @_gesture.__onRelease event, finished
    @didRelease.emit @_gesture, event
    return

  __onTerminationRequest: (event) ->
    if @_gesture
    then @_shouldTerminate @_gesture, event
    else yes

#
# Internal
#

type.defineValues (options) ->

  _touchCount: 0

  _shouldRespondOnStart: options.shouldRespondOnStart

  _shouldRespondOnMove: options.shouldRespondOnMove

  _shouldCaptureOnStart: options.shouldCaptureOnStart

  _shouldCaptureOnMove: options.shouldCaptureOnMove

  _shouldTerminate: options.shouldTerminate

type.defineReactiveValues

  _isEnabled: yes

  _isGranted: no

  _gesture: null

type.defineMethods

  _createTouchHandlers: ->
    handlers = {}
    for key, handler of ResponderMixin
      handlers[key] = handler.bind this
    return handlers

  _updateTouchCount: (event) ->
    {numberActiveTouches} = event.nativeEvent.touchHistory
    if @_touchCount isnt numberActiveTouches
      @_touchCount = numberActiveTouches
      return yes
    return no

  _grant: (event) ->

    @_isGranted = yes
    @__onGrant event

    Responder.granted[@_gesture.target] = this
    Responder.didGrant.emit this, event
    return

  _release: (event, finished) ->

    if isDev and not @_isGranted
      throw Error "Cannot call '_release' when '_isGranted' equals false!"

    if isDev and @_touchCount > 0
      throw Error "Cannot call '_release' when '_touchCount' is greater than zero!"

    @_isGranted = no
    @_gesture.finished = finished

    @__onRelease event, finished
    @__onTouchEnd event

    delete Responder.granted[@_gesture.target]
    Responder.didRelease.emit this, event, finished

    @_gesture = null
    return

  _terminate: (nativeEvent, finished) ->

    return unless @isActive
    @_touchCount = 0

    nativeEvent ?= {}
    nativeEvent.target ?= @_gesture.target
    nativeEvent.touches ?= []
    nativeEvent.timestamp ?= Date.now()
    nativeEvent.touchHistory ?= @_gesture._touchHistory

    event = new ResponderSyntheticEvent null, null, nativeEvent, nativeEvent.target
    event.touchHistory = nativeEvent.touchHistory

    if @_isGranted
      @_release event, finished
      return

    @_gesture.finished = finished
    @__onTouchEnd event
    @_gesture = null
    return

module.exports = Responder = type.build()

ResponderMixin =

  onGestureStart: (event) ->
    if @_isEnabled and not @_gesture
      @_gesture = @__createGesture
        target: event.nativeEvent.target
        touchHistory: event.nativeEvent.touchHistory
      return

  onGestureEnd: (event) ->
    return unless @isActive
    @_gesture.finished = yes

    if @_touchCount
      @_touchCount = 0
      @__onTouchEnd event

    @_gesture = null
    return

  onStartShouldSetResponder: (event) ->
    if @_isEnabled and @isActive
    then @__shouldRespondOnStart event
    else no

  onMoveShouldSetResponder: (event) ->
    if @_isEnabled and @isActive
    then @__shouldRespondOnMove event
    else no

  onStartShouldSetResponderCapture: (event) ->
    if @_isEnabled and @isActive
      @_updateTouchCount event
      @__onTouchStart event
      return @__shouldCaptureOnStart event
    return no

  onMoveShouldSetResponderCapture: (event) ->
    if @_isEnabled and @isActive
      @__onTouchMove event
      return @__shouldCaptureOnMove event
    return no

  onResponderStart: (event) ->
    return unless @_isEnabled and @isActive
    if @_updateTouchCount event
      @__onTouchStart event
      return

  onResponderMove: (event) ->
    if @_isEnabled and @isActive
      @__onTouchMove event
      return

  onResponderEnd: (event) ->
    if @_isEnabled and @isActive
      @_updateTouchCount event
      @_touchCount and @__onTouchEnd event
      return

  onResponderReject: (event) ->
    if @_isEnabled and @isActive
      @__onReject event
      return

  onResponderGrant: (event) ->
    @_isGranted or @_grant event
    return yes # Block the native responder.

  onResponderRelease: (event) ->
    if @_isEnabled and @isActive
      @_release event, yes
      return

  onResponderTerminate: (event) ->
    if @_isEnabled and @isActive
      @_touchCount = 0
      @_release event, no
      return

  onResponderTerminationRequest: (event) ->
    if @_gesture
    then @__onTerminationRequest event
    else yes
