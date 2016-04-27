
# gesture v1.0.0 [![stable](http://badges.github.io/stability-badges/dist/stable.svg)](http://github.com/badges/stability-badges)

A gesture library for [React Native](http://github.com/facebook/react-native).

### Gesture

A base class for gesture types.

Options:

- `gesture: Object`

Properties:

- `isTouching: Boolean { get }`
- `finished: [ Boolean, Null ] { get }`
- `x: Number { get }`
- `y: Number { get }`
- `x0: Number { get }`
- `y0: Number { get }`
- `dx: Number { get }`
- `dy: Number { get }`
- `vx: Number { get }`
- `vy: Number { get }`

### Gesture.Responder

A base class for responder types.

Options:

- `shouldRespondOnStart: Function`
- `shouldRespondOnMove: Function`
- `shouldCaptureOnStart: Function`
- `shouldCaptureOnMove: Function`
- `shouldTerminate: Function`

Properties:

- `isEnabled: Boolean { get, set }`
- `isTouching: Boolean { get }`
- `touchHandlers: Object { get }`

Events:

- `didTouchStart(Gesture)`
- `didTouchMove(Gesture)`
- `didTouchEnd(Gesture)`

### Gesture.ResponderList

Combines multiple `Gesture.Responder` instances into an ordered list.

This allows you to add multiple responders to a single `View`.

```coffee
# In this example, `dragY` can capture `dragX`.
dragXY = Gesture.ResponderList [ dragX, dragY ]

# A props mixin just like Responder has.
dragXY.touchHandlers
```
