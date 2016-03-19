
{ touchHistory } = require "ResponderTouchHistoryStore"
{ assertType } = require "type-utils"

Gesture = require "./Gesture"

# These handlers should be mixed into the props of a View after they
# are bound to a Responder. Use `responder.touchHandlers` for auto-binding.
module.exports =

  onStartShouldSetResponder: (event) ->
    @_setEligibleResponder() unless @_active
    return no unless @_needsUpdate()
    @_onTouchStart event
    return @_shouldRespondOnStart event

  onMoveShouldSetResponder: (event) ->
    return no unless @_needsUpdate()
    @_onTouchMove event
    return @_shouldRespondOnMove event

  onEndShouldSetResponder: (event) ->
    # If we jump from >1 touches to 0 touches, an event is dispatched when no touches are active.
    return no if touchHistory.numberActiveTouches is 0
    return no unless @_needsUpdate()
    @_onTouchEnd event
    return @_shouldRespondOnEnd event

  onStartShouldSetResponderCapture: (event) ->
    @_setEligibleResponder() unless @_active
    return no unless @_needsUpdate()
    @_onTouchStart event
    return @_shouldCaptureOnStart event

  onMoveShouldSetResponderCapture: (event) ->
    return no unless @_needsUpdate()
    @_onTouchMove event
    return @_shouldCaptureOnMove event

  onEndShouldSetResponderCapture: (event) ->
    # If we jump from >1 touches to 0 touches, an event is dispatched when no touches are active.
    return no if touchHistory.numberActiveTouches is 0
    return no unless @_needsUpdate()
    @_onTouchEnd event
    return @_shouldCaptureOnEnd event

  onResponderStart: (event) ->
    return unless @_needsUpdate()
    @_onTouchStart event
    return

  onResponderMove: (event) ->
    return unless @_needsUpdate()
    @_onTouchMove event
    return

  onResponderEnd: (event) ->
    return unless @_needsUpdate()
    @_onTouchEnd event
    return

  onResponderReject: (event) ->
    return unless @_needsUpdate()
    @_onReject event
    return

  onResponderGrant: (event) ->
    assertType @_gesture, Gesture.Kind
    @_setActiveResponder()
    unless @_captured
      @_onGrant event
    return yes

  onResponderRelease: (event) ->
    return unless @_needsUpdate()
    @_onRelease event
    return

  onResponderTerminate: (event) ->
    return unless @_needsUpdate()
    @_onTerminate event
    return

  onResponderTerminationRequest: (event) ->
    return yes unless @_needsUpdate()
    return @_onTerminationRequest event
