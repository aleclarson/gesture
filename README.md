
# gesture v2.5.0 ![stable](https://img.shields.io/badge/stability-stable-4EBA0F.svg?style=flat)

A gesture library for [React Native](http://github.com/facebook/react-native).

• Each `Gesture.Responder` creates its own `Gesture`.

### Gesture.optionTypes

```coffee
x: Number
y: Number
```

### Gesture.properties

```coffee
# Equals 'false' if the gesture has ended. (read-only)
gesture.isActive

# Equals 'null' if the gesture is still active. (read-only)
# Equals 'false' if the gesture was terminated before it could finish.
gesture.finished

# The number of active touches. (read-only)
gesture.touchCount

# The starting position. (read-only)
gesture.x0
gesture.y0

# The current position. (read-only)
gesture.x
gesture.y

# The distance travelled. (read-only)
gesture.dx
gesture.dy

# The elapsed time in milliseconds. (read-only)
gesture.dt

# The current velocity. (read-only)
gesture.vx
gesture.vy
```

### Gesture.prototype

The methods below are recommended for overriding with subclasses.

```coffee
# Called when the responder is denied the 'capturedResponder'.
gesture.__onReject event

# Called when the responder becomes the 'capturedResponder'.
gesture.__onGrant event

# Called when all fingers have stopped touching the screen
# or the gesture was terminated manually.
gesture.__onEnd event

# Called when a finger starts touching the screen.
gesture.__onTouchStart event, touchCount

# Called when a finger moves while touching the screen.
gesture.__onTouchMove event

# Called when a finger stops touching the screen.
gesture.__onTouchEnd event, touchCount
```

### Gesture.statics

```coffee
# The responder class that interacts with
# React Native's touch event system.
responder = Gesture.Responder {}

# A class that allows multiple responders
# to be used on a single 'View'.
responders = Gesture.ResponderList []
```

-

**TODO:** Write sections for `Responder` and `ResponderList`!
