
{currentCentroidX, currentCentroidY} = require "TouchHistoryMath"

ResponderSyntheticEvent = require "ResponderSyntheticEvent"
emptyFunction = require "emptyFunction"
TouchHistory = require "TouchHistory"
LazyVar = require "LazyVar"
isDev = require "isDev"
Type = require "Type"

type = Type "Gesture"

type.defineArgs
  target: Number
  touchHistory: TouchHistory

type.defineValues (options) ->

  target: options.target

  touchHistory: options.touchHistory

  finished: null

  _currentTime: 0

  _prevTime: null

  _lastMoveTime: null

type.defineValues ->

  _x: x = currentCentroidX @touchHistory

  _y: y = currentCentroidY @touchHistory

  _x0: x

  _y0: y

  _dx0: null

  _dy0: null

  _prevX: x

  _prevY: y

type.defineFrozenValues -> do =>

  _dx: LazyVar => @_x - @_x0

  _dy: LazyVar => @_y - @_y0

  _dt: LazyVar => @_currentTime - @_prevTime

  _vx: LazyVar => roundVelocity (@_x - @_prevX) / @_dt.get()

  _vy: LazyVar => roundVelocity (@_y - @_prevY) / @_dt.get()

type.initInstance ->
  @_dx.set 0
  @_dy.set 0
  @_dt.set 0
  @_vx.set 0
  @_vy.set 0

type.defineGetters

  isActive: -> @finished is null

  canUpdate: -> @_currentTime < @touchHistory.mostRecentTimeStamp

  x0: -> @_x0

  y0: -> @_y0

  x: -> @_x

  y: -> @_y

  dt: -> @_dt.get()

  dx: -> @_dx.get()

  dy: -> @_dy.get()

  dx0: -> @_dx0

  dy0: -> @_dy0

  vx: -> @_vx.get()

  vy: -> @_vy.get()

type.defineMethods

  _updateTime: ->
    @_prevTime = @_currentTime
    @_currentTime = @touchHistory.mostRecentTimeStamp
    return

  # Called when a touch starts or ends.
  # It prevents large visual jumps by the centroid.
  _updateCentroid: ->

    x = currentCentroidX @touchHistory
    y = currentCentroidY @touchHistory

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
    return

type.defineHooks

  __onReject: emptyFunction

  __onGrant: emptyFunction

  __onRelease: (event, finished) ->

    if isDev and not @isActive
      throw Error "Gesture already ended!"

    @finished = finished

    # Detect a period of inactivity before the gesture ended.
    if @_lastMoveTime and (Date.now() - @_lastMoveTime) >= 150
      @_vx.set 0
      @_vy.set 0
    return

  __onTouchStart: (event) ->
    if @canUpdate
      @_updateTime()
      @_updateCentroid()
    return

  __onTouchMove: ->

    return unless @canUpdate
    @_updateTime()

    @_lastMoveTime = Date.now()
    @_prevX = @_x
    @_prevY = @_y
    @_x = currentCentroidX @touchHistory
    @_y = currentCentroidY @touchHistory

    @_dx.reset()
    @_dy.reset()
    @_dt.reset()
    @_vx.reset()
    @_vy.reset()

    if @_dx0 is null
      @_dx0 = @dx
      @_dy0 = @dy
    return

  __onTouchEnd: (event) ->
    return unless @canUpdate
    if @touchHistory.numberActiveTouches > 0
      @_updateTime()
      @_updateCentroid()
    return

module.exports = type.build()

roundVelocity = (v) ->
  if 0.05 >= Math.abs v
  then 0
  else v
