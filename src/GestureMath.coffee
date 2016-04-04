
{ currentCentroidX
  currentCentroidY } = require "TouchHistoryMath"

{ touchHistory } = require "ResponderTouchHistoryStore"

LazyVar = require "lazy-var"
combine = require "combine"
hook = require "hook"
sync = require "sync"

module.exports = (config) ->

  combine config.customValues ?= {}, customValues

  hook.after config, "initValues", (result) ->
    combine result ?= {}, createValues.call this

  hook.after config, "initFrozenValues", (result) ->
    combine result ?= {}, createFrozenValues.call this

  hook.after config, "init", init

  combine config, {
    _updateEvent
    _updateValues
    _computeFinalVelocity
    _resetLazyValues: _resetLazyValues.get()
  }

#
# Setup value getters.
#

customValues =

  needsUpdate: get: ->
    @_currentEvent < touchHistory.mostRecentTimeStamp

publicValues = [ "x0", "y0", "x", "y" ]

sync.each publicValues, (key) ->
  backingKey = "_" + key
  customValues[key] = get: -> this[backingKey]

lazyValues = [ "dx", "dy", "dt", "vx", "vy" ]

sync.each lazyValues, (key) ->
  backingKey = "_" + key
  customValues[key] = get: -> this[backingKey].get()

#
# Setup backing values.
#

createValues = ->

  _currentEvent: 0

  _prevEvent: null

  _x0: null

  _y0: null

  _x: null

  _y: null

  _prevX: null

  _prevY: null

  _lastMoveTime: null

createFrozenValues = ->

  _dx: LazyVar =>
    @_x - @_x0

  _dy: LazyVar =>
    @_y - @_y0

  _dt: LazyVar =>
    @_currentEvent - @_prevEvent

  _vx: LazyVar =>
    (@_x - @_prevX) / @_dt.get()

  _vy: LazyVar =>
    (@_y - @_prevY) / @_dt.get()

init = ->
  @_dx.set 0
  @_dy.set 0
  @_dt.set 0
  @_vx.set 0
  @_vy.set 0

#
# Setup private methods.
#

_resetLazyValues = LazyVar ->
  backingKeys = sync.map lazyValues, (key) -> "_" + key
  return -> this[key].reset() for key in backingKeys

_updateEvent = ->
  assert @needsUpdate
  @_prevEvent = @_currentEvent
  @_currentEvent = touchHistory.mostRecentTimeStamp

_updateValues = (phase) ->
  _updateValues[phase].call this

_updateValues.touchMove = ->
  @_lastMoveTime = Date.now()
  @_prevX = @_x
  @_prevY = @_y
  @_x = currentCentroidX touchHistory
  @_y = currentCentroidY touchHistory
  @_resetLazyValues()
  @_updateEvent()

# When a touch starts or ends, we update the
# positional values in a way that prevents visual jumps.
_updateValues.touchStart =
_updateValues.touchEnd = ->

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

_computeFinalVelocity = ->
  return unless @_lastMoveTime
  return if Date.now() - @_lastMoveTime < 150
  log.it "Gesture detected no movement!"
  @_vx.set 0
  @_vy.set 0
