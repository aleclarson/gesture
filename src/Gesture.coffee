
{currentCentroidX, currentCentroidY} = require "react-native/lib/TouchHistoryMath"
TouchHistory = require "react-native/lib/TouchHistory"

emptyFunction = require "emptyFunction"
Type = require "Type"

type = Type "Gesture"

type.defineArgs ->
  required: yes
  types:
    target: Number
    touchHistory: TouchHistory

type.defineValues (options) ->

  target: options.target

  finished: null

  x: x = currentCentroidX options.touchHistory

  y: y = currentCentroidY options.touchHistory

  x0: x

  y0: y

  dx: 0

  dy: 0

  dx0: null

  dy0: null

  _touchHistory: options.touchHistory

type.defineGetters

  isActive: -> @finished is null

  touchCount: -> @_touchHistory.numberActiveTouches

type.defineMethods

  # Called when a touch starts or ends.
  # It prevents large visual jumps by the centroid.
  _updateCentroid: ->
    prevX = @x
    prevY = @y
    @x = currentCentroidX @_touchHistory
    @y = currentCentroidY @_touchHistory
    @x0 += @x - prevX
    @y0 += @y - prevY
    return

type.defineHooks

  __onReject: emptyFunction

  __onGrant: emptyFunction

  __onRelease: emptyFunction

  __onTouchStart: ->
    @_updateCentroid()
    return

  __onTouchMove: ->

    @x = currentCentroidX @_touchHistory
    @y = currentCentroidY @_touchHistory

    @dx = @x - @x0
    @dy = @y - @y0

    if @dx0 is null
      @dx0 = @dx
      @dy0 = @dy
    return

  __onTouchEnd: ->
    if @touchCount > 0
      @_updateCentroid()
    return

module.exports = type.build()
