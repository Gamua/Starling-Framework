# Unit Tests

In the past, unit tests relied on old `FlexUnit` libraries, but those are no longer officially available.
To get rid of this dependency, I created a couple of lightweight test classes that together make up `starling.unit`.
Those classes are currently simply a part of the `src` directory – but if there's interest, we could put them into a separate library, too.

In any case, this means that it's now really easy to run the tests.
Simply compile this project just like any other AIR project, e.g. just as Desktop AIR app.
The unit tests will start immediately when that app is launched.

Edit the class `TestSuite` to focus on specific unit tests, e.g. by commenting out any tests you're not interested in.
