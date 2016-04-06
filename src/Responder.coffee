
# TODO: Implement 'minTouchCount' and 'maxTouchCount'.

{ touchHistory } = require "ResponderTouchHistoryStore"
{ assertType } = require "type-utils"

ResponderEventPlugin = require "ResponderEventPlugin"
emptyFunction = require "emptyFunction"
Factory = require "factory"
Event = require "event"
hook = require "hook"

Gesture = require "./Gesture"

hook.before ResponderEventPlugin, "onFinalTouch", (event) ->
  responders = Responder.activeResponders
  return if responders.length is 0
  for responder in responders
    responder.terminate event, yes
  responders.length = 0

module.exports =
Responder = Factory "Gesture_Responder",

  statics:

    # All responders that are capable of claiming the active touch.
    activeResponders: []

    # The responder that most recently claimed to the active touch.
    capturedResponder: null

    # Emits when the `capturedResponder` has a new value!
    didResponderCapture: Event()

  optionTypes:
    # minTouchCount: Number
    # maxTouchCount: Number
    shouldRespondOnStart: Function
    shouldRespondOnMove: Function
    shouldRespondOnEnd: Function
    shouldCaptureOnStart: Function
    shouldCaptureOnMove: Function
    shouldCaptureOnEnd: Function
    shouldTerminate: Function

  optionDefaults:
    # minTouchCount: 1
    # maxTouchCount: Infinity
    shouldRespondOnStart: emptyFunction.thatReturnsTrue
    shouldRespondOnMove: emptyFunction.thatReturnsFalse
    shouldRespondOnEnd: emptyFunction.thatReturnsFalse
    shouldCaptureOnStart: emptyFunction.thatReturnsFalse
    shouldCaptureOnMove: emptyFunction.thatReturnsFalse
    shouldCaptureOnEnd: emptyFunction.thatReturnsFalse
    shouldTerminate: emptyFunction.thatReturnsTrue

  customValues:

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

    isCaptured: get: ->
      @_isCaptured

    gesture: get: ->
      @_gesture

    _gesture:
      value: null
      reactive: yes

    _isCaptured:
      value: no
      reactive: yes
      didSet: (newValue, oldValue) ->
        return if newValue is oldValue
        responder = if newValue then this else null
        Responder.capturedResponder = responder
        Responder.didResponderCapture.emit responder

  initFrozenValues: ->

    didReject: Event()

    didGrant: Event()

    didEnd: Event()

    didTouchStart: Event()

    didTouchMove: Event()

    didTouchEnd: Event()

  initValues: (options) ->

    _shouldRespondOnStart: options.shouldRespondOnStart

    _shouldRespondOnMove: options.shouldRespondOnMove

    _shouldRespondOnEnd: options.shouldRespondOnEnd

    _shouldCaptureOnStart: options.shouldCaptureOnStart

    _shouldCaptureOnMove: options.shouldCaptureOnMove

    _shouldCaptureOnEnd: options.shouldCaptureOnEnd

    _shouldTerminate: options.shouldTerminate

  terminate: (event, finished) ->

    return unless @isActive

    @__onTouchEnd event, 0

    if @isCaptured
      if finished is yes then @__onRelease event
      else @__onTerminate event

    @_deleteGesture()

    return

  __canUpdate: ->
    return @isEnabled and @_gesture and @_gesture.isActive

  __createGesture: (options) ->
    return Gesture options

  __shouldRespondOnStart: ->
    @_shouldRespondOnStart @_gesture

  __shouldRespondOnMove: ->
    @_shouldRespondOnMove @_gesture

  __shouldRespondOnEnd: ->
    @_shouldRespondOnEnd @_gesture

  __shouldCaptureOnStart: ->
    @_shouldCaptureOnStart @_gesture

  __shouldCaptureOnMove: ->
    @_shouldCaptureOnMove @_gesture

  __shouldCaptureOnEnd: ->
    @_shouldCaptureOnEnd @_gesture

  __onTouchStart: (event, touchCount) ->
    log.it "#{@__id}.__onTouchStart()"
    @_gesture.__onTouchStart event, touchCount
    @didTouchStart.emit @_gesture, event

  __onTouchMove: (event) ->
    @_gesture.__onTouchMove event
    @didTouchMove.emit @_gesture, event

  __onTouchEnd: (event, touchCount) ->
    log.it "#{@__id}.__onTouchEnd()"
    @_gesture.__onTouchEnd event, touchCount
    @didTouchEnd.emit @_gesture, event

  __onReject: (event) ->
    log.it "#{@__id}.__onReject()"
    @_gesture.__onReject event
    @didReject.emit @_gesture, event

  __onGrant: (event) ->
    log.it "#{@__id}.__onGrant()"
    @_gesture.__onGrant event
    @didGrant.emit @_gesture, event

  __onRelease: (event) ->
    log.it "#{@__id}.__onRelease()"
    @_gesture.__onEnd yes, event
    @didEnd.emit @_gesture, event

  __onTerminate: (event) ->
    log.it "#{@__id}.__onTerminate()"
    @_gesture.__onEnd no, event
    @didEnd.emit @_gesture, event

  __onTerminationRequest: (event) ->
    return yes unless @_gesture
    return @_shouldTerminate @_gesture, event

  _setActive: (isActive) ->
    responders = Responder.activeResponders
    if isActive then responders.push this
    else responders.splice (responders.indexOf this), 1

  _createGesture: (event) ->
    return if @_gesture
    @_gesture = @__createGesture { event }
    @_setActive yes
    assertType @_gesture, Gesture.Kind

  _deleteGesture: ->
    assert @isActive, "Gesture not yet created!"
    @_isCaptured = no
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
    # Batches simultaneous events.
    # Responder does NOT need to capture before receiving this event.
    onResponderStart: (event) =>
      return unless @__canUpdate()
      @_onTouchStart event, touchHistory.numberActiveTouches

    # Called for every finger that moves.
    # Batches simultaneous events.
    # Responder does NOT need to capture before receiving this event.
    onResponderMove: (event) =>
      return unless @__canUpdate()
      @_onTouchMove event, touchHistory.numberActiveTouches

    # Called for every finger that stops touching the screen.
    # Batches simultaneous events.
    # Responder does NOT need to capture before receiving this event.
    onResponderEnd: (event) =>
      return unless @__canUpdate()
      @_onTouchEnd event, touchHistory.numberActiveTouches

    # This must be implemented in case the
    # `capturedResponder` rejects a termination request.
    onResponderReject: (event) =>
      return unless @__canUpdate()
      @__onReject event

    # Must return true if native responders should be blocked.
    onResponderGrant: (event) =>

      unless @isCaptured

        assert Responder.capturedResponder is null,
          reason: "The `capturedResponder` must be null before it can be set to a new Responder!"
          failedResponder: this
          capturedResponder: Responder.capturedResponder

        @_isCaptured = yes
        @__onGrant event

      return yes

    # This event is detected earlier by ResponderEventPlugin.onFinalTouch()
    onResponderRelease: emptyFunction

    onResponderTerminate: (event) =>

      return unless @__canUpdate()

      # The `terminate` method was called.
      if @gesture.touchCount is 0
        console.info "Detected the terminate method!"
        @__onTerminate event
        return

      # A higher responder captured the active touch.
      console.info "Higher responder captured the active touch!"
      @__onTouchEnd event, 0
      @__onTerminate event
      @_deleteGesture()
      @_setActive no

    # Must return false to block the capturing responder.
    # responder must capture before receiving this event.
    onResponderTerminationRequest: (event) =>
      return yes unless @_gesture
      return @__onTerminationRequest event
