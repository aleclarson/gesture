
LazyVar = require "lazy-var"
combine = require "combine"
hook = require "hook"

LAZY_KEYS = [ "_dx", "_dy", "_dt", "_vx", "_vy" ]

module.exports = (config) ->

  combine config.customValues ?= {}, customValues

  hook.after config, "initFrozenValues", (result) ->
    combine result ?= {}, createFrozenValues.call this

  config._resetLazyValues = ->
    LAZY_KEYS.forEach (LAZY_KEY) =>
      this[LAZY_KEY].reset()

#
# Create the public getters.
#

customValues = {}
[ "dx", "dy", "dt", "vx", "vy" ].forEach (key) ->
  LAZY_KEY = "_" + key
  customValues[key] = get: -> this[LAZY_KEY].get()

#
# Create the private computations.
#

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
