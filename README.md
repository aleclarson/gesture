
# gesture v3.0.0 ![stable](https://img.shields.io/badge/stability-stable-4EBA0F.svg?style=flat)

A gesture library for [React](http://github.com/facebook/react) and [React Native](http://github.com/facebook/react-native).

## `Gesture`

For every set of touch events targeting the same view, a `Gesture` instance is created by each potential `Responder` instance.

Any `Responder` subclass may use its own `Gesture` subclass by overriding the `__createGesture` method.

### Options

You don't need to worry about creating `Gesture` instances manually, since the `Responder` instance takes care of that. But here are the options passed to the `__createGesture` method.

```coffee
target: Number | Node
touchHistory: TouchHistory
```

### Properties

```coffee
# Equals 'false' if the gesture has ended. (readonly)
isActive: Boolean

# Equals 'null' if the gesture is still active. (readonly)
# Equals 'false' if the gesture was terminated before it could finish.
finished: Boolean | null

# The number of active touches. (readonly)
touchCount: Number

# The current position. (readonly)
x: Number
y: Number

# The distance travelled. (readonly)
dx: Number
dy: Number

# The starting position. (readonly)
x0: Number
y0: Number

# The distance values from the first `__onTouchMove` event. (readonly)
dx0: Number | null
dy0: Number | null
```

### Instance methods

Subclasses can safely override these methods:

```coffee
# Called when the current responder prevents this gesture from capturing.
__onReject: (event) ->

# Called when the gesture is claimed by its responder.
__onGrant: (event) ->

# Called when the gesture finishes or is terminated.
__onRelease: (event, finished) ->

# Called when a finger starts touching the screen.
__onTouchStart: (event) ->

# Called when a finger moves while touching the screen.
__onTouchMove: (event) ->

# Called when a finger stops touching the screen.
__onTouchEnd: (event) ->
```

### Class properties

```coffee
# The responder class that interacts with React's touch event system.
responder = Gesture.Responder {}

# Merge multiple responders so you can attach them to a single view.
responders = Gesture.ResponderList []
```

&nbsp;

## `Responder`

Typically, you will construct a `Responder` subclass instead of calling the `Responder` constructor directly. But if you ever need to handle both the X and Y axis, feel free to construct the `Responder` class.

### Options

```coffee
# Return true to become the current responder (which is the default behavior).
# This is called when a touch begins (only if no ancestor is the current responder).
shouldRespondOnStart: Function?

# Return true to become the current responder. Returns false by default.
# This is called when a touch moves (only if no ancestor is the current responder).
shouldRespondOnMove: Function?

# Return true to become the current responder (terminating any previous responder). Returns false by default.
# This is called when a touch begins (before any `shouldRespondOnStart` handlers).
shouldCaptureOnStart: Function?

# Return true to become the current responder (terminating any previous responder). Returns false by default.
# This is called when a touch moves (before any `shouldRespondOnMove` handlers).
shouldCaptureOnMove: Function?

# Return false to reject a termination request. Returns true by default.
shouldTerminate: Function?
```

### Properties

```coffee
# A map of event handlers that you must mix into the props of a view constructor. (readonly)
touchHandlers: Object

# Equals true if the responder will handle future touch events.
# Setting this to false while the responder is active causes a termination event.
isEnabled: Boolean

# A boolean indicating whether the gesture is not yet finished. (readonly)
isActive: Boolean

# Equals true if the responder claimed a gesture. (readonly)
isGranted: Boolean

# The current gesture instance. (readonly)
gesture: Gesture.Kind

# The number of recognized touches. (readonly)
# This will equal zero if `terminate` is called (unlike `gesture.touchCount`).
touchCount: Number

# Emits when the current responder rejects a termination request made by this responder.
didReject: Event

# Emits when this responder becomes the current responder.
didGrant: Event

# Emits when this responder finishes or is terminated.
didRelease: Event

# Emits when a new finger starts touching the screen.
didTouchStart: Event

# Emits when a finger moves while touching the screen.
didTouchMove: Event

# Emits when a finger stops touching the screen.
didTouchEnd: Event
```

### Instance methods

```coffee
# Merge this responder with another responder (or an array of responders), returning a `ResponderList` instance.
join: (responder) ->

# Force this responder's gesture to finish early. The `nativeEvent` argument is optional.
finish: (nativeEvent) ->

# Terminate this responder's gesture, if active. The `nativeEvent` argument is optional.
terminate: (nativeEvent) ->
```

Subclasses can safely override these methods:

```coffee
# Create a `Gesture` instance.
__createGesture: (options) ->

# Override the default behavior of `options.shouldRespondOnStart`.
__shouldRespondOnStart: (event) ->

# Override the default behavior of `options.shouldRespondOnMove`.
__shouldRespondOnMove: (event) ->

# Override the default behavior of `options.shouldCaptureOnStart`.
__shouldCaptureOnStart: (event) ->

# Override the default behavior of `options.shouldCaptureOnMove`.
__shouldCaptureOnMove: (event) ->

# Called when a touch starts.
__onTouchStart: (event) ->

# Called when a touch moves.
__onTouchMove: (event) ->

# Called when a touch ends.
__onTouchEnd: (event) ->

# Called when the current responder rejects a termination request made by this responder.
__onReject: (event) ->

# Called when this responder claims an active gesture.
__onGrant: (event) ->

# Called when this responder finishes or is terminated.
__onRelease: (event, finished) ->

# Override the default behavior of `options.shouldTerminate`.
__onTerminationRequest: (event) ->
```

### Static properties

```coffee
# The map of responders which have claimed a gesture.
granted: Object

# Emits when a responder is granted a gesture.
didGrant: Event

# Emits when a responder finishes or is terminated.
didRelease: Event

# An array of keys from the `touchHandlers` map.
eventNames: [String]
```
