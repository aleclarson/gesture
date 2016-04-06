
{ currentCentroidX, currentCentroidY } = require "TouchHistoryMath"
{ touchHistory } = require "ResponderTouchHistoryStore"
{ assert } = require "type-utils"

ResponderSyntheticEvent = require "ResponderSyntheticEvent"
LazyVar = require "lazy-var"
Factory = require "factory"

module.exports =
Gesture = Factory "Gesture",

  statics:

    Responder: lazy: ->
      require "./Responder"

    ResponderList: lazy: ->
      require "./ResponderList"

  optionTypes:
    event: ResponderSyntheticEvent

  customValues:

    isActive: get: -> @finished is null

    canUpdate: get: ->
      return @_currentTime < touchHistory.mostRecentTimeStamp

    x0: get: -> @_x0

    y0: get: -> @_y0

    x: get: -> @_x

    y: get: -> @_y

    dx: get: -> @_dx.get()

    dy: get: -> @_dy.get()

    dt: get: -> @_dt.get()

    vx: get: -> @_vx.get()

    vy: get: -> @_vy.get()

  initFrozenValues: ->

    _dx: LazyVar =>
      @_x - @_x0

    _dy: LazyVar =>
      @_y - @_y0

    _dt: LazyVar =>
      @_currentTime - @_prevTime

    _vx: LazyVar =>
      (@_x - @_prevX) / @_dt.get()

    _vy: LazyVar =>
      (@_y - @_prevY) / @_dt.get()

  initValues: ->

    touchCount: touchHistory.numberActiveTouches

    finished: null

    _currentTime: 0

    _prevTime: null

    _x0: null

    _y0: null

    _x: null

    _y: null

    _prevX: null

    _prevY: null

    _grantDX: 0

    _grantDY: 0

    _lastMoveTime: null

  init: (options) ->

    { nativeEvent } = options.event
    @_x = @_prevX = @_x0 = nativeEvent.pageX
    @_y = @_prevY = @_y0 = nativeEvent.pageY

    @_dx.set 0
    @_dy.set 0
    @_dt.set 0
    @_vx.set 0
    @_vy.set 0

  _updateTime: ->
    @_prevTime = @_currentTime
    @_currentTime = touchHistory.mostRecentTimeStamp

  # Called when a touch starts or ends.
  # It prevents large visual jumps by the centroid.
  _updateCentroid: ->

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

  __onReject: ->
    @finished = no

  __onGrant: ->
    @_grantDX = @dx
    @_grantDY = @dy

  __onEnd: (finished, event) ->

    @finished = finished

    # Detect a period of inactivity before the gesture ended.
    if @_lastMoveTime and (Date.now() - @_lastMoveTime) >= 150
      @_vx.set 0
      @_vy.set 0

  __onTouchStart: (event, touchCount) ->

    assert touchCount > 0, "Invalid touch count!"
    @touchCount = touchCount

    return unless @canUpdate
    @_updateTime()
    @_updateCentroid()

  __onTouchMove: (event) ->

    return unless @canUpdate
    @_updateTime()

    @_lastMoveTime = Date.now()
    @_prevX = @_x
    @_prevY = @_y
    @_x = currentCentroidX touchHistory
    @_y = currentCentroidY touchHistory

    @_dx.reset()
    @_dy.reset()
    @_dt.reset()
    @_vx.reset()
    @_vy.reset()

  __onTouchEnd: (event, touchCount) ->

    assert touchCount >= 0, "Invalid touch count!"
    @touchCount = touchCount
    return if touchCount is 0

    return unless @canUpdate
    @_updateTime()
    @_updateCentroid()
