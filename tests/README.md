# Unit Tests

In the past, unit tests relied on old `FlexUnit` libraries, but those are no longer officially available.
To get rid of this dependency, I created a couple of lightweight test classes that together make up `starling.unit`.
Those classes are currently simply a part of the `src` directory – but if there's interest, we could put them into a separate library, too.

In any case, this means that it's now really easy to run the tests.
Simply compile this project just like any other AIR project, e.g. just as Desktop AIR app.
The unit tests will start immediately when that app is launched.

Edit the class `TestSuite` to focus on specific unit tests, e.g. by commenting out any tests you're not interested in.

To run the tests from the terminal, use `run.sh`. It runs them in a hidden window and prints the log to the console. It needs the AIR SDK, either via the `AIR_HOME` environment variable or with its `bin` folder on the `PATH`. The exit code tells you if all tests passed. On Windows, run it from Git Bash.

Starling's code paths differ between Stage3D profiles (e.g. AGAL 1 vs. AGAL 2 shaders, power-of-two textures in "baselineConstrained"). That's why `run.sh` runs all tests once per profile: by default, in "standard", "baseline" and "baselineConstrained". To pick other profiles, pass a comma-separated list:

    ./run.sh                                  # standard, baseline, baselineConstrained
    ./run.sh --profile=standard               # just one profile, for a quick run
    ./run.sh --profile=standard,baseline

Rendering features are tested with golden images (e.g. `QuadTest.testRendering`, with helpers from `utils.GoldenFixture`): the output is compared with the reference images in `fixtures/golden`. All profiles share the same goldens. On a mismatch, the actual image and a diff (differing pixels in red) are saved to `out/golden-failures/<profile>`. After an intended change in the output, run `./run.sh --record` to update the goldens (they are recorded in the first profile and compared in the others), check them visually, and commit them.
