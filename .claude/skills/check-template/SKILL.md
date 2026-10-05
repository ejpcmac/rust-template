---
name: check-template
description: Generate every project type of the template, run the checks of each generated project, report the defects and propose fixes.
disable-model-invocation: true
---

# Check the template

Generate the template for each project type, run the checks of the generated
projects, and turn every failure into a **defect**: one root cause, traced to
the template file that produces it, with a proposed fix. The author decides
which fixes are applied.

Arguments narrow the run: a project type, a licence, a revision, a check.
Without arguments, check every project type at `@` with all the checks.

## Steps

### 1. Run the matrix

```
.claude/scripts/variant-matrix -c all <scratch directory>/matrix
```

Done when the script has printed one `passed` or `FAILED` line per render, or
one error from `render`. A render error is a defect too: skip to step 3 with
it.

- `cannot render`: the generation scripts or a template file are at fault. The
  output of cargo-generate above the error names the file.
- `cannot format`: the formatting hook has failed, and cargo-generate hides the
  output of its command. Reproduce it in a plain render:

    ```
    .claude/scripts/render -t <project type> <scratch directory>/plain
    cd <scratch directory>/plain && nix develop .#ci -c true
    ```

    Then run the formatters of `scripts-post/format.rhai` one by one in that
    devshell.

If every render has passed, report it and stop.

### 2. Find the cause of every failed check

For each `FAILED` render, list its failed checks:

```
grep -aE '==>|FAILED' <render>.log | grep -B1 FAILED | grep '==>'
```

Then read the log of each failed check up to its **first** error: the later
ones usually follow from it. A step with several commands reports `FAILED`
under its last title, so read from the first title of the step.

Done when every failed check of every render is attributed to a cause.

### 3. Turn the causes into defects

Merge the causes: one defect per root cause, with the project types it
affects. A single cause often fails several checks in several project types.

For each defect:

1. Trace it to the template: the `.liquid` file and the line or conditional
   that produces the faulty output, or the script under `scripts/`.
2. Classify it:
    - **drift**: the template has not changed, the world has (see "Drift").
    - **regression**: a change to the template has introduced it.
    - **harness**: the scratch render differs from a real project in a way that
      matters. The fix goes into `.claude/scripts/`, not into the template.
3. Check that the proposed fix works before proposing it: evaluate the Nix
   attribute, query the binary cache, read the documentation of the tool. For
   a drift, find what replaces what has gone, not a pin to the past.

Done when every defect has a file, a class and a verified fix.

### 4. Report

One table, most blocking defect first:

| Defect | Project types | Class | Template file | Proposed fix |

Then, for each defect: the error line from the log, the cause in one sentence,
and the fix as a diff. Say plainly when a fix is a design choice rather than a
correction, and give the options.

Stop here and wait for the author to choose the fixes.

### 5. Fix

For each approved fix, in its own change:

1. Edit the template.
2. Rerun the matrix on the affected project types and the failed checks only
   (`-t`, `-c`).
3. Commit the fix in its own change, as a `fix`.

When all the fixes are in, run the whole matrix once more. Done when it passes,
or when the only failures left are defects the author has declined.

## Reading the results

### Formatting is not a defect

The checks run on a formatted render. Only what the formatters cannot repair
is a defect, such as a line over 80 columns in `flake.nix`, reported by
`eclint`.

A formatter present in the formatting hook and not in `check_format`, or the
reverse, is a defect.

### Drift

Usual forms:

- **A package removed or renamed in `nixpkgs`**: the devshell fails to
  evaluate, every check fails within seconds, and the error names the
  attribute.
- **A dependency that needs a newer compiler**: `rustc <version> is not
supported by the following packages`. Either the workspace does not resolve
  with the Rust version in mind (`resolver = "3"` and `rust-version`), or the
  toolchain of the template is behind.

To tell a drift from a regression, rerun the failed check with `-r` on the
revision before the change.

### A check that compiles a compiler

A check silent for minutes whose log shows clang, gcc or LLVM being built
(`[386/2258] Building CXX object`) is compiling a package absent from the
binary cache. Stop the run: this is a drift, not a slow check. Find the
attribute in the flake and test it:

```
path=$(nix eval --raw 'github:NixOS/nixpkgs#legacyPackages.x86_64-linux.<attribute>.outPath')
nix path-info --store https://cache.nixos.org "$path"
```

Test the neighbouring attributes the same way and propose one that is cached.
For a cross-compiler, `pkgsCross.<platform>.buildPackages.<compiler>` runs on
the build platform and is cached; `pkgsCross.<platform>.<compiler>` runs on the
target platform and is not.
