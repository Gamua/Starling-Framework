# AGENTS.md

Starling is a 2D framework for ActionScript 3 (Adobe AIR and Flash Player), rendering via Stage3D. The library lives in `starling/src`, unit tests in `tests`, sample projects in `samples`.

## Testing

- Run the tests with `tests/run.sh` (on Windows: from Git Bash); exit code 0 means all passed.

- Cover every change with unit tests, and rendering changes with golden image tests (`assertMatchesGolden`).

- Look at every new or changed golden image before committing it.

## Code

- No static state: pass configuration via constructors or properties. `Starling.current` is the one deliberate exception.

- Library code must not depend on AIR-only APIs; it also runs in Flash Player.

- No allocations in per-frame code (rendering, `advanceTime`).

- Imports are sorted alphabetically; `util/import_sorter` checks and fixes that.

- Commit messages: short, lowercase, past tense ("added ...", "fixed ...").
