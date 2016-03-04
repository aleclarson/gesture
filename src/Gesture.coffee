
LazyVar = require "lazy-var"
Factory = require "factory"

module.exports = Factory "Gesture",

  statics:

    Responder: LazyVar ->
      require "./Responder"

    Combinator: LazyVar ->
      require "./Combinator"

  optionTypes:
    gesture: Object

  customValues:

    isTouching: get: ->
      @_touching

    finished: get: ->
      @_finished

    x0: get: ->
      @_gesture.x0

    y0: get: ->
      @_gesture.y0

    x: get: ->
      @_gesture.moveX

    y: get: ->
      @_gesture.moveY

    dx: get: ->
      @_gesture.dx

    dy: get: ->
      @_gesture.dy

    vx: get: ->
      @_gesture.vx

    vy: get: ->
      @_gesture.vy

  initFrozenValues: (options) ->

    _gesture: options.gesture

  initValues: ->

    _finished: null

  initReactiveValues: ->

    _touching: no

  _onTouchStart: ->
    @_touching = yes
    return

  _onTouchMove: ->
    # no-op

  _onTouchEnd: (finished) ->
    @_finished = finished
    @_touching = no
    return
