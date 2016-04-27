
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
    x: Number
    y: Number

  customValues:

    isActive: get: ->
      @finished is null

    canUpdate: get: ->
      @_currentTime < touchHistory.mostRecentTimeStamp

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

  initValues: (options) ->

    touchCount: touchHistory.numberActiveTouches

    finished: null

    _currentTime: 0

    _prevTime: null

    _x0: options.x

    _y0: options.y

    _x: options.x

    _y: options.y

    _prevX: options.x

    _prevY: options.y

    _grantDX: 0

    _grantDY: 0

    _lastMoveTime: null

  init: ->
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

  __onEnd: (finished) ->

    @finished = finished

    # Detect a period of inactivity before the gesture ended.
    if @_lastMoveTime and (Date.now() - @_lastMoveTime) >= 150
      @_vx.set 0
      @_vy.set 0

  __onTouchStart: (touchCount) ->

    assert touchCount > 0, "Invalid touch count!"
    @touchCount = touchCount

    return unless @canUpdate
    @_updateTime()
    @_updateCentroid()

  __onTouchMove: ->

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

  __onTouchEnd: (touchCount) ->

    assert touchCount >= 0, "Invalid touch count!"
    @touchCount = touchCount
    return if touchCount is 0

    return unless @canUpdate
    @_updateTime()
    @_updateCentroid()
