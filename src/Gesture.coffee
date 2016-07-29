
{ currentCentroidX, currentCentroidY } = require "TouchHistoryMath"
{ touchHistory } = require "ResponderTouchHistoryStore"

ResponderSyntheticEvent = require "ResponderSyntheticEvent"
fromArgs = require "fromArgs"
LazyVar = require "LazyVar"
assert = require "assert"
Type = require "Type"

type = Type "Gesture"

type.defineOptions
  x: Number.isRequired
  y: Number.isRequired

type.defineGetters

  isActive: -> @finished is null

  canUpdate: -> @_currentTime < touchHistory.mostRecentTimeStamp

  x0: -> @_x0

  y0: -> @_y0

  x: -> @_x

  y: -> @_y

  dx: -> @_dx.get()

  dy: -> @_dy.get()

  dt: -> @_dt.get()

  vx: -> @_vx.get()

  vy: -> @_vy.get()

type.defineFrozenValues

  _dx: -> LazyVar => @_x - @_x0

  _dy: -> LazyVar => @_y - @_y0

  _dt: -> LazyVar => @_currentTime - @_prevTime

  _vx: -> LazyVar => (@_x - @_prevX) / @_dt.get()

  _vy: -> LazyVar => (@_y - @_prevY) / @_dt.get()

type.defineValues

  touchCount: -> touchHistory.numberActiveTouches

  finished: null

  _currentTime: 0

  _prevTime: null

  _x: fromArgs "x"

  _y: fromArgs "y"

  _x0: -> @_x

  _y0: -> @_y

  _prevX: -> @_x

  _prevY: -> @_y

  _grantDX: 0

  _grantDY: 0

  _lastMoveTime: null

type.initInstance ->
  @_dx.set 0
  @_dy.set 0
  @_dt.set 0
  @_vx.set 0
  @_vy.set 0

type.defineMethods

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

type.defineHooks

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

  __onTouchStart: (event, touchCount) ->

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

  __onTouchEnd: (event, touchCount) ->

    assert touchCount >= 0, "Invalid touch count!"
    @touchCount = touchCount

    return if touchCount is 0
    return unless @canUpdate

    @_updateTime()
    @_updateCentroid()

type.defineStatics

  Responder: lazy: ->
    require "./Responder"

  ResponderList: lazy: ->
    require "./ResponderList"

module.exports = type.build()
