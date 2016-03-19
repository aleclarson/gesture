
{ currentCentroidX
  currentCentroidY } = require "TouchHistoryMath"

{ touchHistory } = require "ResponderTouchHistoryStore"
{ assert } = require "type-utils"

ResponderSyntheticEvent = require "ResponderSyntheticEvent"
Factory = require "factory"

module.exports = Factory "Gesture",

  mixins: [
    require "./GestureMath"
  ]

  statics:

    Responder: lazy: ->
      require "./Responder"

    ResponderList: lazy: ->
      require "./ResponderList"

  optionTypes:
    event: [ ResponderSyntheticEvent ]

  customValues:

    isTouching: get: ->
      @finished is null

    needsUpdate: get: ->
      @_currentEvent < touchHistory.mostRecentTimeStamp

    x0: get: ->
      @_x0

    y0: get: ->
      @_y0

  initValues: ->

    _x0: null

    _y0: null

    _prevX: null

    _prevY: null

    _lastMoveTime: null

    _currentEvent: 0

    _prevEvent: null

  initReactiveValues: ->

    touchCount: touchHistory.numberActiveTouches

    finished: null

  init: (options) ->
    { nativeEvent } = options.event
    @_x = @_prevX = @_x0 = nativeEvent.pageX
    @_y = @_prevY = @_y0 = nativeEvent.pageY
    @_dx.set 0
    @_dy.set 0
    @_dt.set 0
    @_vx.set 0
    @_vy.set 0

  _updateEvent: ->
    assert @needsUpdate
    @_prevEvent = @_currentEvent
    @_currentEvent = touchHistory.mostRecentTimeStamp

  _computeFinalVelocity: ->
    return unless @_lastMoveTime
    return if Date.now() - @_lastMoveTime < 150
    @_vx.set 0
    @_vy.set 0

#
# Native handlers
#

  _onReject: ->
    @finished = no

  _onGrant: emptyFunction

  _onEnd: (finished, event) ->
    @_computeFinalVelocity()
    @finished = finished

  _onTouchStart: (event) ->
    @touchCount = touchHistory.numberActiveTouches
    @_onTouchCountChanged()
    @_updateEvent()

  _onTouchMove: (event) ->
    if @touchCount < touchHistory.numberActiveTouches
      @_onTouchStart event
      return no
    else if @touchCount > touchHistory.numberActiveTouches
      @_onTouchEnd event
      return no
    @_lastMoveTime = Date.now()
    @_prevX = @_x
    @_prevY = @_y
    @_x = currentCentroidX touchHistory
    @_y = currentCentroidY touchHistory
    @_resetLazyValues()
    @_updateEvent()
    return yes

  _onTouchEnd: (event) ->
    @touchCount = touchHistory.numberActiveTouches
    @_onTouchCountChanged() if @touchCount > 0

  # When a touch starts or ends, we update the
  # positional values in a way that prevents visual jumps.
  _onTouchCountChanged: ->

    x = currentCentroidX touchHistory
    y = currentCentroidY touchHistory

    dx = x - @_x
    dy = y - @_y

    @_x = x
    @_y = y

    @_x0 += dx
    @_y0 += dy

    @_prevX += dx
    @_prevY += dy

    @_dt.reset()

    @_vx.set 0
    @_vy.set 0
