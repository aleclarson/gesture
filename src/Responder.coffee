
# TODO: Implement 'minTouchCount' and 'maxTouchCount'.

{ touchHistory } = require "ResponderTouchHistoryStore"
{ assertType } = require "type-utils"

ResponderEventPlugin = require "ResponderEventPlugin"
emptyFunction = require "emptyFunction"
Factory = require "factory"
Event = require "event"
hook = require "hook"

Gesture = require "./Gesture"

# Hooking into 'ResponderEventPlugin.onFinalTouch' allows us
# to detect when a gesture ends for the `activeResponders`.
isTerminatingActiveResponders = no
hook.before ResponderEventPlugin, "onFinalTouch", ->
  responders = Responder.activeResponders
  return if responders.length is 0
  isTerminatingActiveResponders = yes
  responder.finish() for responder in responders
  responders.length = 0
  isTerminatingActiveResponders = no

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
    minTouchCount: Number
    # maxTouchCount: Number
    shouldRespondOnStart: Function
    shouldRespondOnMove: Function
    shouldCaptureOnStart: Function
    shouldCaptureOnMove: Function
    shouldTerminate: Function

  optionDefaults:
    minTouchCount: 1
    # maxTouchCount: Infinity
    shouldRespondOnStart: emptyFunction.thatReturnsTrue
    shouldRespondOnMove: emptyFunction.thatReturnsFalse
    shouldCaptureOnStart: emptyFunction.thatReturnsFalse
    shouldCaptureOnMove: emptyFunction.thatReturnsFalse
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

  initFrozenValues: (options) ->

    minTouchCount: options.minTouchCount

    didReject: Event()

    didGrant: Event()

    didEnd: Event()

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

    _gesture: null

    _isCaptured: no

  capture: ->

    return if @isCaptured

    assert Responder.capturedResponder is null,
      reason: "The `capturedResponder` must be null before it can be set to a new Responder!"
      failedResponder: this
      capturedResponder: Responder.capturedResponder

    @_setCaptured yes
    @__onGrant()
    return

  finish: ->
    @_interrupt yes
    return

  terminate: ->
    return unless @__onTerminationRequest()
    @_interrupt no
    return

  __canUpdate: ->
    return @isEnabled and @_gesture and @_gesture.isActive

  __createGesture: (options) ->
    return Gesture options

  __shouldRespondOnStart: ->
    @_shouldRespondOnStart @_gesture

  __shouldRespondOnMove: ->
    @_shouldRespondOnMove @_gesture

  __shouldCaptureOnStart: ->
    @_shouldCaptureOnStart @_gesture

  __shouldCaptureOnMove: ->
    @_shouldCaptureOnMove @_gesture

  __onTouchStart: (touchCount) ->
    @_gesture.__onTouchStart touchCount
    @didTouchStart.emit @_gesture

  __onTouchMove: ->
    @_gesture.__onTouchMove()
    @didTouchMove.emit @_gesture

  __onTouchEnd: (touchCount) ->
    @_gesture.__onTouchEnd touchCount
    @didTouchEnd.emit @_gesture

  __onReject: ->
    @_gesture.__onReject()
    @didReject.emit @_gesture

  __onGrant: ->
    @_gesture.__onGrant()
    @didGrant.emit @_gesture

  __onRelease: ->
    @_gesture.__onEnd yes
    @didEnd.emit @_gesture

  __onTerminate: ->
    @_gesture.__onEnd no
    @didEnd.emit @_gesture

  __onTerminationRequest: ->
    return yes unless @_gesture
    return @_shouldTerminate @_gesture

  _interrupt: (finished) ->

    return unless @isActive

    @__onTouchEnd 0

    if @_isCaptured
      if finished is yes
        @__onRelease()
      else @__onTerminate()

    @_deleteGesture()
    return

  _createGesture: (event) ->
    return if @_gesture
    { pageX, pageY } = event.nativeEvent
    @_gesture = @__createGesture { x: pageX, y: pageY }
    @_setActive yes
    assertType @_gesture, Gesture.Kind

  _deleteGesture: ->
    assert @isActive, "Gesture not yet created!"
    wasCaptured = @_isCaptured
    @_setCaptured no
    @_setActive no
    @_gesture = null

  _setActive: (isActive) ->
    return if isTerminatingActiveResponders and not isActive # Avoid an expensive 'splice' operation during 'ResponderEventPlugin.onFinalTouch'!
    responders = Responder.activeResponders
    if isActive then responders.push this
    else responders.splice (responders.indexOf this), 1

  _setCaptured: (isCaptured) ->
    return if isCaptured is @_isCaptured
    @_isCaptured = isCaptured
    responder = if isCaptured then this else null
    Responder.capturedResponder = responder
    Responder.didResponderCapture.emit responder

  _onTouchStart: (touchCount) ->
    return if @_gesture.touchCount is touchCount
    @__onTouchStart touchCount

  _onTouchMove: (touchCount) ->

    if @_gesture.touchCount < touchCount
      @__onTouchStart touchCount
      return

    else if @_gesture.touchCount > touchCount
      @_onTouchEnd touchCount
      return

    @__onTouchMove()

  _onTouchEnd: (touchCount) ->
    assert @_gesture.touchCount isnt touchCount
    @__onTouchEnd touchCount
    return if touchCount > 0
    @_deleteGesture()

  _createMixin: ->

    onStartShouldSetResponder: (event) =>

      if Responder.capturedResponder # This event falsely fires when a second touch starts and 'capturedResponder' is already set.
        return no

      if touchHistory.numberActiveTouches < @minTouchCount
        return no

      @_createGesture event

      unless @__canUpdate()
        return no

      @_onTouchStart touchHistory.numberActiveTouches

      return @__shouldRespondOnStart()

    onMoveShouldSetResponder: =>

      if touchHistory.numberActiveTouches < @minTouchCount
        return no

      unless @__canUpdate()
        return no

      @_onTouchMove touchHistory.numberActiveTouches

      return @__shouldRespondOnMove()

    onStartShouldSetResponderCapture: (event) =>

      if touchHistory.numberActiveTouches < @minTouchCount
        return no

      @_createGesture event

      unless @__canUpdate()
        return no

      @_onTouchStart touchHistory.numberActiveTouches

      return @__shouldCaptureOnStart event

    onMoveShouldSetResponderCapture: (event) =>

      if touchHistory.numberActiveTouches < @minTouchCount
        return no

      unless @__canUpdate()
        return no

      @_onTouchMove touchHistory.numberActiveTouches

      return @__shouldCaptureOnMove event

    onEndShouldSetResponderCapture: (event) =>

      # If we jump from >1 touches to 0 touches,
      # an event is dispatched when no touches are active.
      if touchHistory.numberActiveTouches is 0
        return no

      unless @__canUpdate()
        return no

      @_onTouchEnd touchHistory.numberActiveTouches

      # For now, don't allow capturing when a touch ends.
      return no

    # Called for every new finger that touches the screen.
    # Batches simultaneous events.
    # Responder does NOT need to capture before receiving this event.
    onResponderStart: =>

      unless @__canUpdate()
        return

      @_onTouchStart touchHistory.numberActiveTouches

    # Called for every finger that moves.
    # Batches simultaneous events.
    # Responder does NOT need to capture before receiving this event.
    onResponderMove: =>

      unless @__canUpdate()
        return

      @_onTouchMove touchHistory.numberActiveTouches

    # Called for every finger that stops touching the screen.
    # Batches simultaneous events.
    # Responder does NOT need to capture before receiving this event.
    onResponderEnd: =>

      unless @__canUpdate()
        return

      @_onTouchEnd touchHistory.numberActiveTouches

    # This must be implemented in case the
    # `capturedResponder` rejects a termination request.
    onResponderReject: =>

      unless @__canUpdate()
        return

      @__onReject()

    # Must return true if native responders should be blocked.
    onResponderGrant: =>

      assert @_gesture isnt null,
        reason: "A gesture must be created before 'onResponderGrant'!"

      unless @_isCaptured
        @capture()

      # This blocks native responders.
      return yes

    # This event is detected earlier by ResponderEventPlugin.onFinalTouch()
    onResponderRelease: emptyFunction

    onResponderTerminate: =>

      unless @__canUpdate()
        return

      # The `terminate` method was called.
      if @gesture.touchCount is 0
        @__onTerminate()
        return

      # A higher responder captured the active touch.
      @__onTouchEnd 0
      @__onTerminate()
      @_deleteGesture()

    # Must return false to block the capturing responder.
    # Responder must capture before receiving this event.
    onResponderTerminationRequest: =>

      unless @_gesture
        return yes

      return @__onTerminationRequest()
