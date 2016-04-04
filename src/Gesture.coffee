
{ touchHistory } = require "ResponderTouchHistoryStore"
{ assert } = require "type-utils"

ResponderSyntheticEvent = require "ResponderSyntheticEvent"
Factory = require "factory"

module.exports =
Gesture = Factory "Gesture",

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

  initValues: ->

    _grantDX: 0

    _grantDY: 0

  initReactiveValues: ->

    touchCount: touchHistory.numberActiveTouches

    finished: null

  init: (options) ->
    { nativeEvent } = options.event
    @_x = @_prevX = @_x0 = nativeEvent.pageX
    @_y = @_prevY = @_y0 = nativeEvent.pageY
    return

  _onReject: ->
    @finished = no
    return

  _onGrant: ->
    @_grantDX = @dx
    @_grantDY = @dy
    return

  _onEnd: (finished, event) ->
    @_computeFinalVelocity()
    @finished = finished
    return

  _onTouchStart: (event) ->
    @touchCount = touchHistory.numberActiveTouches
    @_updateValues "touchStart"
    @_updateEvent()
    return

  _onTouchMove: (event) ->

    if @touchCount < touchHistory.numberActiveTouches
      @_onTouchStart event
      return no

    else if @touchCount > touchHistory.numberActiveTouches
      @_onTouchEnd event
      return no

    @_updateValues "touchMove"
    return yes

  _onTouchEnd: (event) ->
    @touchCount = touchHistory.numberActiveTouches
    @_updateValues "touchEnd" if @touchCount > 0
    return
