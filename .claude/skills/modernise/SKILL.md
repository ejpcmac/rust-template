---
name: modernise
description: Bring the template to the current Rust ecosystem without a project: flake inputs of the repository, stable toolchain, nightly date, MSRV, crates, lints, edition, idioms, CI actions.
disable-model-invocation: true
---

# Modernise the template

Bring the template to the Rust ecosystem of the day, without relying on a
project: the flake inputs of this repository, the latest stable toolchain, a
recent nightly, the MSRV, the latest crates, the lints that have appeared since the last update, a new edition when
there is one, the idioms the new version allows, the CI actions. The author
decides once, on the lints and the idioms, before anything is changed; the
rest runs unattended.

The run has six phases, in this order: `flake`, `toolchain`, `deps`, `lints`,
`idioms`, `actions`. Arguments narrow the run to some of them. Without
arguments, run them all.

Out of scope: the `cargo` group of clippy, whose TODO stays.

## Steps

### 1. Start clean

Read `.claude/skills/check-template/SKILL.md` and follow it, its stop for the
approval of fixes included. Run its matrix in the background and prepare
step 2 meanwhile.

Done when the matrix passes at `@`, with the fixes committed.

### 2. Get the decisions, once

Find the versions:

- **new**: the latest stable (see "Versions"). There is no way to ask for
  another one.
- **old**: the `channel` of `rust-toolchain.toml.liquid`. When the `toolchain`
  phase is not run, the channel is the new version already: the old one is the
  line removed by the last change to that file.

When `toolchain` or `lints` is run, start the **probe** in the background
before anything else, once `lint-diff` has listed the new lints and the
unstable ones are known (see "Lints"), and prepare the rest meanwhile:

```
nix develop -c .claude/skills/modernise/scripts/lint-probe <new> <scratch directory>/probe <lint>...
```

The lints are every lint `lint-diff` lists as added, `nursery` included, but
the unstable rustc ones; without `lints`, none. The probe renders every
project type plain, with the new toolchain, the new MSRV and these lints at
`warn`, and prints what fires in each, and every compile error.

Prepare, for the phases that are run:

- `lints`: the **lint changelog** (see "Lints"), with the result of the
  probe.
- `idioms`: the **idiom table**. Read the release notes of every version after
  the old one, up to the new one
  (`https://raw.githubusercontent.com/rust-lang/rust/<new>/RELEASES.md`), and
  match the stabilised features and APIs against the sources of the template.
  One row per idiom the template could use: Idiom, Since, Where, Before →
  after, Suggestion. A **new edition** (see "Edition") is the first row, with
  `migrate` as its suggestion; the idioms it allows are rows as any other, and
  fall with it if the author refuses it.

  Find the sites of an idiom with a search, then sort them by reading:
  reading alone finds only the sites of the files that happen to be read, and
  misses those repeated in each variant.

  1. Write a grep for the code the idiom replaces, and run it on every
     template file, the sources of every variant included. When the code has
     no fixed text, grep for what it involves instead: the types, methods or
     crates.
  2. Write the hits to `<scratch directory>/idioms/<idiom>`, one per line.
  3. Read each hit and sort it: to change, or to keep, by kind and with a
     reason (a single `#[cfg]` has no alternative to select).
  4. In Where, give the grep, the number of sites to change, the kinds kept
     with their counts, and the path of the hits file, never the full list.

  When no grep can approach the code, Where lists the files read and says
  that the sweep is not exhaustive.

Show both and stop. The author answers only the rows they disagree with.
Nothing else stops the run from here, except a render changed by the flake
inputs (step 3) and a toolchain that cannot be made green (step 4). Any other
choice the run meets, it makes itself (step 9).

Done when the author has answered. With neither `lints` nor `idioms`, there is
nothing to show: go on.

### 3. Flake

The `flake.lock` of this repository pins `cargo-generate`, which makes every
render, and the other tools of its devshell. It pins no Rust and reaches no
render: a render has no `flake.lock`, and this phase does not give it one.

1. Before the update, render every project type twice, plain and formatted:

    ```
    nix develop -c .claude/scripts/variant-matrix <scratch directory>/flake-before/plain
    nix develop -c .claude/scripts/variant-matrix -f <scratch directory>/flake-before/formatted
    ```

2. Run `nix flake update`. When `flake.lock` has not changed, the phase ends
   here, without a commit.
3. Build the devshell
   (`nix build --no-link .#devShells.x86_64-linux.default`). When it no longer
   evaluates or builds because a package has been renamed or removed, fix
   `flake.nix`. Fix also each `evaluation warning` the build prints about an
   attribute `flake.nix` uses: it fails nothing today, and breaks the
   devshell when the attribute goes.
4. Render again into `flake-after/plain`, with the same command, and compare:
   `diff -r flake-before/plain flake-after/plain`.
    - **A render fails**: the interface of `cargo-generate` has changed (an
      option, a key of `cargo-generate.toml`, the API of the hooks). Fix
      `.claude/scripts`, `cargo-generate.toml` or the hooks.
    - **The plain renders are identical**: nothing else to verify.
    - **They differ**: render `flake-after/formatted` and compare the
      formatted renders, leaving out `flake.lock` (`diff -r -x flake.lock`).
      A difference the formatters erase is not worth a review: go on, and
      give it in the report. **Any difference left stops the run**: show the
      diff and wait for the author.

    When `cargo-generate` has changed version, read the diff of **its
    source** between the two versions, not only its changelog, which can miss
    a change. Look for what the template uses: the functions of the hooks,
    the keys of `cargo-generate.toml`, the options of
    `.claude/scripts/render`. Read also its package in nixpkgs, which chooses
    the features built: when the override of `cargo-generate` in `flake.nix`
    is no longer needed, remove it.
5. Commit `flake.lock`, with whatever step 3 or 4 had to fix in `flake.nix`,
   `.claude/scripts` or `cargo-generate.toml`: the lock file alone would leave
   a revision that cannot render. A fix in a `.liquid` file, or in a hook that
   changes a render, goes in a `fix(t:…)` of its own, right after.

The description has a body:

```
env(flake): update the inputs

Highlights:

- cargo-generate: <old> → <new>
- git-z: <old> → <new>

Output of `nix store diff-closures`:

<the closure diff>
```

- The closure diff compares the devshell of `HEAD`, which jj keeps on the
  parent of the working copy, with that of the working copy: run it before
  the commit. Nix writes its colours even into a file, and neither `NO_COLOR`
  nor `TERM=dumb` stops it, so strip them:

    ```
    nix store diff-closures \
        '.?ref=HEAD#devShells.x86_64-linux.default' \
        '.#devShells.x86_64-linux.default' |
        sed 's/\x1b\[[0-9;]*[mK]//g'
    ```

    Write the whole description to a file and check it holds no escape
    character (`grep -c "$(printf '\033')"` answers 0) before giving it to
    `jj commit`.

- The highlights are the packages `flake.nix` puts in the devshell, when their
  version has changed. Their versions are in the output below them.
- A fix made in the same commit gets one line of its own, above the
  highlights, naming what changed in `cargo-generate` or in `nixpkgs`.

**From here to the end of the run, prefix every `render` and `variant-matrix`
with `nix develop -c`**: the environment of the session still holds the
devshell of before the update, with the old `cargo-generate`.

Done when the devshell builds, the five project types render, and the
formatted renders are those of before the update or the author has accepted
the difference.

### 4. Toolchain

1. Set `channel` in `rust-toolchain.toml.liquid` to the new version, and
   `rust-version` to its first two components (`"1.99"`) in `Cargo.toml.liquid`
   and `firmware/Cargo.toml.liquid`. Releases skipped since the last update
   are crossed in one jump. Commit the three files together.
2. Set the nightly date of `flake.nix.liquid` to the newest valid one (see
   "Versions"). Commit.
3. Verify (step 9) on every project type.

Done when `build` and `test` pass for every project type. If they cannot be
made to pass with no choice to make, as with a compiler regression or a crate
that no longer builds, stop the run and report: the other phases rest on this
one.

### 5. Crates

1. Find what is behind, in a plain render of each project type and, for an
   `Embedded` one, in its two workspaces (`.` and `firmware`). Add the render
   to its Git repository first (`git add -A`): its flake only sees tracked
   files.

    - The direct dependencies, with their requirements:

        ```
        cd <render>/<workspace> && nix develop <render>#ci -c sh -c \
            'cargo metadata --format-version 1 --no-deps' |
            jq -r '[.packages[].dependencies[]
                    | select(.source != null)
                    | "\(.name) \(.req)"] | unique | .[]'
        ```

    - The latest release of each, from the crates.io API, which needs a
      `User-Agent`:

        ```
        curl -sf -A 'rust-template modernise' \
            https://crates.io/api/v1/crates/<crate> |
            jq -r .crate.max_stable_version
        ```

    - The crates cargo holds back, transitive ones included:

        ```
        cd <render>/<workspace> && nix develop <render>#ci -c sh -c \
            'cargo generate-lockfile && cargo update --dry-run --verbose'
        ```

        A line `Unchanged <crate> (available: <version>)` is a crate that
        cargo resolves below its latest release without a word, as a removed
        feature does (`rtic` held at 2.3.0 in the 1.99 run).

    Do not use `cargo outdated`: it is in the `default` devshell only, whose
    first build compiles `git-z`, and it fails in `firmware/`.

2. Look up on crates.io, with the same call, the crates suggested as comments
   in the manifest of the `CLI` project type: no tool sees them.
3. Read the changelog of every crate behind, from the resolved version to the
   latest, for renamed and removed features as well as for the API. No tool
   reports a feature that has gone: cargo falls back to the last release that
   has it.
4. Bump everything to the latest and migrate the code of the template. One
   commit per crate, or per **coupled set** (see "Crates"), with its manifests
   and its sources. Verify (step 9) after each, on the affected project
   types.

Rules:

- Requirements are carets and a render has no lock file, so a release inside
  the requirement needs no change: only breaking bumps exist.
- A requirement keeps the style of its file: the major alone from 1.0
  (`"1"`), `0.x` before. `"0.7.0"` becomes `"0.10"`.
- A bump whose migration fails after a real attempt, or that needs a redesign
  of the template code, is dropped whole: the old requirement stays, for the
  whole coupled set, and the report gives the error and the changelog entry.
- A stale `#[expect]` fails clippy after a bump: remove it. Recheck the
  workarounds listed in "Crates".
- A commented crate is bumped and reported as not built.

Done when every crate behind is bumped or dropped, and `build` and `test` pass
for every project type.

### 6. Lints

1. Run `.claude/skills/modernise/scripts/lint-diff <old> <new>` again if the
   template has changed since step 2. A patch-only update whose diff is empty
   ends the phase here.
2. When a decision needs a configuration option, set it in
   `clippy.toml.liquid` and commit it on its own, first.
3. Apply the decisions to `scripts/lints.rhai`: replace the renamed entries,
   remove the deprecated ones, add the adopted lints in their section,
   alphabetical. An `allow` of a `pedantic` lint goes under "…except a few".
4. Run `lint-diff` once more: it must exit 0, every entry known to the new
   toolchain.
5. Verify (step 9) on every project type, fix what fires, then commit
   `scripts/lints.rhai`. The description has no body: rejected lints are
   recorded nowhere.

Done when `lint-diff` exits 0 and `build` passes for every project type.

### 7. Idioms

1. Apply what clippy suggests now that the MSRV is raised, without asking:
   it fires in the verification of the phases above.
2. Migrate to the new edition, when there is one and the author has not
   refused its row (see "Edition"). One commit, then verify (step 9) on every
   project type.
3. Apply each approved row of the idiom table, one commit per idiom, to every
   site of its hits file. Before the commit, run its grep again: every hit
   left belongs to a kind kept in the table. A row made moot by a crate
   migration, or that needs an edition whose migration was dropped, is
   dropped and reported.
4. Verify (step 9) on the affected project types.

Done when the template is on the latest stable edition or the migration is
reported as dropped, and every approved idiom is applied or reported as
dropped.

### 8. Actions

In `.github/workflows/*.liquid`, bump every `uses: <action>@v<N>` to the
latest major and replace the runner labels GitHub has retired. Read the
release notes of each major crossed for changed inputs. Keep
`actions/upload-artifact` and `actions/download-artifact` on majors that work
together. Leave the actions on `@main` and the unpinned nightly of the Windows
job as they are.

Done when every action is on its latest major and every runner label exists.
No check runs a workflow: report them as not run.

### 9. Verify, and repair without stopping

After each phase but `flake`, which verifies itself, and `actions`, check
the **kept renders** on every project type, or on the affected ones when the
step says so:

```
nix develop -c .claude/scripts/variant-matrix -u -j all -c build -c test -t <variant> <scratch directory>/kept
```

The **affected project types** are those whose plain render differs between
the revision verified last and the one to verify. Find them with renders,
never from the names of the crates or the scope of the commit: the `-board`
crate, for instance, is shared by the three `Embedded`, and its HALs are
named after Embassy. A plain matrix takes a few seconds:

```
nix develop -c .claude/scripts/variant-matrix -j all -r <revision verified last> <scratch directory>/affected/before
nix develop -c .claude/scripts/variant-matrix -j all -r <revision to verify> <scratch directory>/affected/after
diff -rq <scratch directory>/affected/before <scratch directory>/affected/after
```

Each `<variant>-<licence>` directory named in the output is affected; when
none is, there is nothing to verify. Delete both directories afterwards.

- The first verification renders them fresh and keeps their build artifacts;
  each later one updates them in place, so that their builds are
  incremental. A project type missing from `kept` is rendered fresh.
- A green incremental check is enough to go on, but proves nothing for the
  report: the final matrix is the proof. A failure that does not fit its
  change is checked again on a fresh render, without `-u` and into a new
  directory, before digging.
- A check killed (`Killed`, `No space left on device`) is not a defect:
  the renders running at once have run out of memory or of space. Run it
  again with `-j 1`, and report it.
- Read the outcome in `<output directory>/summary` and the logs. After
  starting each run, show it to the author with
  `.claude/scripts/follow-pane <output directory>`: the pane that follows
  `kept` takes the next run by itself, and the call changes nothing then.
  Once a run has ended and no other is about to start, close the pane with
  `.claude/scripts/follow-pane -k`, before waiting for the author and at the
  end of the skill at the latest.

At the end of the run, delete the renders of `kept`, keeping its logs, then
run the whole matrix once on fresh renders, `-j all -c all`, in the
background, and show it with `follow-pane`. No licence sweep. When the run
is over, delete every render of the scratch directory (the directories next
to the `.log` files), and keep the logs. Search its logs and the devshells of
the renders for evaluation warnings, as step 1 of `check-template` does, and
fix those of `flake.nix.liquid` in a `fix(t:flake)`: the nixpkgs of the day
may have deprecated something since step 1.

On a failure, find the cause and trace it to the template with steps 2 and 3
of `check-template`, fix it and go on:

- A fix goes into the commit that introduced the issue: in the working copy
  when that commit is not made yet, with `jj squash --into <change> <files>`
  otherwise. A scope added to `git-z.toml` for it goes in too. A lint that
  fires after a crate bump is fixed in the commit of that bump. Then check
  with `jj log` that no later commit is in conflict, and resolve it there.
- An issue that no commit of the run introduced, as a change of the
  `nixpkgs` of the day, gets a `fix` of its own.
- Every phase ends green: never go on with a failure that is known, as it
  can hide the next ones.
- When a choice comes up, as a lint that fires on template code, pick one,
  stay green and go on. Give each pick in the report, with its alternative:
    - When the lint is right there, fix the code. This is the default.
    - When the lint is wrong there, as on generated code, suppress it with
      `#[expect(…, reason = "…")]`. `allow_attributes` is on, so never an
      `#[allow]`.
    - When a lint adopted in this run fires on a pattern the template needs,
      drop it from the lints, and flag it in the report.

Done when the final matrix passes, or when its only failures are reported with
their cause.

### 10. Report

Leave the commits stacked on the working copy: `main` is not moved, nothing
is pushed. Then report:

- the flake inputs: the highlights, what had to be fixed, and the
  differences in the renders that the formatters erased;
- the versions before and after: stable, nightly, MSRV, edition;
- the crates bumped, and those dropped with the error and the changelog entry;
- the lints adopted, renamed and removed;
- the edition migration, if there was one: what `cargo fix` rewrote, what
  was kept of it, or the error if it was dropped;
- the idioms applied and dropped;
- the actions and runners changed;
- **the picks** of step 9, each with what it chose, where, and the
  alternative, for the author to approve or reverse; the lints dropped first;
- **everything unverified**: embedded bumps not tried on hardware (the
  firmware is built, never flashed), workflows not run, commented crates not
  built, the MSRV (nothing builds with it).

## Commits

In this order, with the scopes of `CLAUDE.md`:

| What                         | Description                                              |
| ---------------------------- | -------------------------------------------------------- |
| Flake inputs                 | `env(flake): update the inputs`, with its body (step 3)  |
| Toolchain and MSRV           | `feat(t:toolchain): update Rust from <old> to <new>`     |
| Nightly date                 | `feat(t:flake): update Rust nightly to <YYYY-MM-DD>`     |
| One per crate or coupled set | `feat(t:cargo@<variant>): <crate>: <old> -> <new>`       |
| A repair                     | `fix(t:src@<variant>): …`                                |
| `clippy.toml.liquid`         | `feat(t:clippy): …`                                      |
| Lints                        | `feat(t:lints): update the list of lints for Rust <X.Y>` |
| Edition                      | `feat(t:cargo): update to Rust <edition>`                |
| One per idiom                | `refactor(t:src@<variant>): …`                           |
| Actions and runners          | `feat(t:gh-ci): …`                                       |

- For a crate, `<old>` and `<new>` are the requirements, as the manifest has
  them: `rexpect: 0.6 -> 0.7`. A coupled set lists its crates, separated by
  commas: `toml: 0.8 -> 0.9, toml_edit: 0.22 -> 0.23`.
- The lints commit names the version with two components: `Rust 1.99`.
- `<variant>` is the narrowest that covers the change: `@embedded` for a set
  shared by the three `Embedded` project types.
- There is no `deps` type: a bump is a `feat(t:cargo…)`.
- A scope missing from `git-z.toml` is added in the commit that first needs
  it, even when the need comes late.
- Each commit is meant to pass: a fix goes into the commit that introduced the
  issue (step 9). What a commit holds beside its subject shows the issue: a
  crate bump is normally its manifests alone, so code beside them is an API
  change or a lint that broke. The checks stay per phase and per crate bump:
  none runs per commit.

## Versions

```
overlay='let
  overlay = builtins.getFlake "github:oxalica/rust-overlay";
  pkgs = import overlay.inputs.nixpkgs {
    system = builtins.currentSystem;
    overlays = [ overlay.overlays.default ];
  };
in'

# The latest stable.
nix eval --impure --raw --expr "$overlay pkgs.rust-bin.stable.latest.minimal.version"

# Its path in the store.
nix build --impure --no-link --print-out-paths --expr "$overlay pkgs.rust-bin.stable.latest.minimal"

# Whether a nightly date is valid for the template.
nix eval --impure --raw --expr "$overlay (pkgs.rust-bin.nightly.\"<date>\".minimal.override {
  extensions = [ \"llvm-tools\" ];
  targets = [ \"thumbv7em-none-eabihf\" ];
}).drvPath"
```

- **Nightly date**: the day of the update, else the day before, and so on
  backwards. The overlay usually lags a day, so the fallback is the normal
  case. A date the overlay does not have fails with `Did you mean one of`.
- The nightly serves `check coverage` and `check unused-deps` only. It never
  lints.
- **No check verifies the MSRV**: nothing builds with it. It steers the
  resolver and gates the version-aware lints of clippy, so raising it makes
  those lints fire on template code.
- The MSRV and the resolver are set twice: in `Cargo.toml.liquid` and in
  `firmware/Cargo.toml.liquid`. The edition is set three times: in these two
  and in `xtask/Cargo.toml.liquid`.

## Crates

Coupled sets move whole, in one commit:

- **defmt**: `defmt`, `defmt-rtt`, `panic-probe`, and the `defmt` features of
  the Embassy crates and of `embedded-hal`.
- **Embassy**: `embassy-executor`, `embassy-time`, `embassy-nrf`,
  `embassy-stm32`. The two HALs also serve as HAL and PAC in the
  `Embedded (Bare-metal)` and `Embedded (RTIC)` project types.

Before bumping a set, check that its latest releases resolve together: the
crates of a family depend on each other with exact minors.

Workarounds to recheck when their crate moves:

- the two `#[allow]` of `src-bare-metal/main.rs.liquid` (`cortex-m-rt`);
- the `#[expect]` of the board files (Embassy HALs), of
  `src-rtic/main.rs.liquid` (`rtic`) and of `blink.rs.liquid` (`mockall`).

Dependencies are declared per crate: there is no `[workspace.dependencies]`.

## Lints

### Sources

`.claude/skills/modernise/scripts/lint-diff <old> <new>` builds the two
toolchains and prints, from `clippy-driver -W help`, for rustc and clippy
alike:

- the lints added and removed, with their default level and their group;
- the lints whose default level or group has changed;
- the entries of `scripts/lints.rhai` unknown to the new toolchain, with a
  non-zero exit status if there is one.

This last validation is the only one there is: an unknown, renamed or removed
lint is a warning that fails no check, even under `-D warnings`.

`lint-diff` does not know:

- **Renames.** A rename shows as one removal and one addition. For clippy,
  read the tables `DEPRECATED` and `RENAMED` of
  `https://raw.githubusercontent.com/rust-lang/rust-clippy/rust-<new>/clippy_lints/src/deprecated_lints.rs`.
  Read `deprecated_lints.rs` at the tag, not on `master`, which has the
  renames of lints not released yet. For rustc, read `register_renamed` and
  `register_removed` in
  `https://raw.githubusercontent.com/rust-lang/rust/<new>/compiler/rustc_lint/src/lib.rs`.

  A rename of an unstable rustc lint is not registered. Suspect one when a
  removed lint and an added one share a subject, and confirm it with the
  merged pull requests that name the old lint:

    ```
    gh api -X GET search/issues \
        -f q='repo:rust-lang/rust <old_lint> is:pr is:merged' \
        --jq '.items[] | "\(.number) \(.closed_at) \(.title)"'
    ```
- **Feature gates.** rustc lists the lints behind a feature gate as any
  other. Probe each new allow-by-default lint of rustc with the new
  toolchain, whose path `lint-diff` prints, and drop those answered with
  `the lint is unstable`, from the tables and from the probe:

    ```
    echo 'fn main() {}' >probe.rs
    <toolchain>/bin/rustc -W <lint> --emit=metadata --out-dir <scratch directory> probe.rs
    ```

- **What a lint flags.** For clippy, read
  `https://rust-lang.github.io/rust-clippy/rust-<X.Y.0>/index.html`: one
  `<article id="<lint_name>">` per lint, with its description, "Added in" and
  its configuration options. The page exists for `.0` releases only. "Added
  in" is wrong at times: show it as an indication.
- **What a lint fires on in the template.** `lint-probe <new> <output
  directory> <lint>...` answers it (step 2). It runs clippy without
  `-D warnings`, as `check build` stops at the first error and hides the
  lints after it, and prints per lint the places and the files, and a
  summary across project types. Its renders have the new MSRV, so the
  version-aware lints fire as they will after step 4. A lint already on that
  fires there fires because of the new toolchain or the new MSRV.
- **Enhancements.** The `CHANGELOG.md` of clippy and the `RELEASES.md` of
  rustc tell what an existing lint now also catches. They only annotate: both
  miss new lints and moves, so the lists come from `lint-diff`.

  The `CHANGELOG.md` of clippy lags behind its tags: read it on `master`
  (`https://raw.githubusercontent.com/rust-lang/rust-clippy/master/CHANGELOG.md`)
  and keep the sections after the old version, up to the new one. The
  `RELEASES.md` of rustc does not lag: read it at the tag.

### Policy

- **The delta only**, from the old version to the new. Never an audit of the
  older lints that are not enabled: they reach the template from projects.
- Judge from the documentation, with the probe as evidence: a lint that
  fires on a pattern the template needs is not worth adopting, one that
  fires nowhere costs nothing today.
- `warn`, unless the lint guards a real bug. Clippy runs with `-D warnings`
  on the feature powerset, so every `warn` fails `check build` all the same.
- The `xtask` crate has no `[lints]` table and is clipped with the default
  lints: a new lint of a default-on group can break it.

Suggestions:

| Change                                        | Suggestion                              |
| --------------------------------------------- | --------------------------------------- |
| New `restriction`                             | `warn`, `deny` or skip, on judgement    |
| New `pedantic`                                | keep (on through the group), or `allow` |
| New `nursery`                                 | skip: not mature, shown for information |
| New rustc allow-by-default, stable            | on judgement                            |
| Moved from a default-on group to `nursery`    | skip, following the clippy team         |
| Moved from `pedantic` to `restriction`        | `warn`, to keep it on                   |
| Moved into `pedantic` from a default-on group | nothing: it stays on                    |
| New in a default-on group                     | none                                    |

The default-on groups are `correctness`, `suspicious`, `style`, `complexity`
and `perf`.

### The lint changelog

Changelog and decision table are one: Markdown tables grouped by kind, a
suggestion wherever there is a decision.

Decisions:

| Table                              | Columns                                                    |
| ---------------------------------- | ---------------------------------------------------------- |
| New `restriction`                  | Lint, Since, What it flags, Fires, Suggestion, Why         |
| New `pedantic`                     | Lint, Since, What it flags, Fires, Suggestion, Why         |
| New `nursery`                      | Lint, Since, What it flags, Fires, Suggestion              |
| New rustc allow-by-default, stable | Lint, Since, What it flags, Fires, Suggestion, Why         |
| Moved                              | Lint, From → to, Effect on the template, Fires, Suggestion |
| Fires on the template              | Lint, Group, Where, Why it fires, Suggestion               |

Information:

| Table                    | Columns                                     |
| ------------------------ | ------------------------------------------- |
| Renamed                  | Old, New, In `lints.rhai`                   |
| Deprecated               | Lint, Was, Reason, In `lints.rhai`          |
| New in default-on groups | Lint, Group, Since, What it flags (in full) |
| rustc default levels     | Lint, Change                                |
| Configuration options    | Option, Lint, Change, Used in `clippy.toml` |
| Enhanced                 | Lint, Since, What it now also catches       |

- Every table covers every group, rustc included, except "Enhanced", cut to
  the lints the template has on. Leave out the fixes of false positives.
- "Effect on the template" is `was on, now off`, `was off, now on` or
  `stays on`, with the change of level if there is one.
- "Fires" comes from the probe: `no`, or the number of places and the project
  types.
- "Fires on the template" lists the lints that are on with no decision of
  this run, those of the default-on groups and those already enabled, and
  that the probe finds firing. "Why it fires" is a new lint, an enhancement,
  or the new MSRV. The suggestion is to fix the code when the lint is right
  there, `#[expect(…, reason = "…")]` when it is wrong there (generated code,
  as the mock of `mockall`).
- The compile errors and the rustc warnings the probe prints that are not
  lints go under the tables, as information: step 4 deals with them.
- A renamed or deprecated lint that is in `lints.rhai` moves up to the
  decisions.
- An empty table is left out.
- Each lint name in the tables is a Markdown link to its documentation. As
  the terminal of the author (Termite, inside tmux) may show no hyperlinks,
  give also under each table one line per lint with the URL in full, which
  the terminal detects as text: `- <lint_name>: <URL>`. The URL is
  `https://rust-lang.github.io/rust-clippy/rust-<X.Y.0>/index.html#<lint_name>`
  for clippy, and
  `https://doc.rust-lang.org/<new>/rustc/lints/listing/<level>-by-default.html#<lint-name>`
  for rustc, where `<level>` is `allowed`, `warn` or `deny` and the anchor
  has hyphens.

## Edition

`<toolchain>/bin/rustc --help` names the latest stable edition, under
`--edition`. It is new when it is later than the `edition` of
`Cargo.toml.liquid`. It needs the new toolchain: without the `toolchain`
phase, the template is on it already.

`cargo fix` works on a render, never on a `.liquid` file. In a formatted
render of each project type (`variant-matrix -f`), copied first so that the
rewrites can be read with `diff -r`:

```
cd <render> && nix develop .#ci -c \
    cargo fix --edition --workspace --all-targets --all-features --allow-no-vcs
```

In the `firmware/` workspace of an `Embedded` render, run it with the devshell
of the root (`nix develop ..#ci`) and with the targets and the features
`check build` uses there: the boards exclude each other, so once per board.

Then:

1. Read the guide of the edition
   (`https://doc.rust-lang.org/edition-guide/rust-<edition>/index.html`).
   `cargo fix` rewrites only the code it compiles: it misses what is behind
   an inactive `cfg`, inside a macro, and the doc-tests.
2. Judge each rewrite. `cargo fix` keeps the old behaviour at any cost, so
   many are noise: port to the `.liquid` file only those the template code
   needs, in every project type that renders the file. Fix by hand what the
   guide lists and `cargo fix` missed.
3. Set `edition` in the three manifests. When the edition changes the default
   resolver, set `resolver` to it in the two workspace manifests.
4. Leave the formatting: the style of rustfmt follows the edition and the
   `post` hook repairs the render.

The manifests and the sources go in one commit. A migration that fails after
a real attempt is dropped whole, as a crate bump is: the old edition stays and
the report gives the error.
