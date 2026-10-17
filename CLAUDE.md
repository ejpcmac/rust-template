# rust-template

A [cargo-generate] template for new Rust projects, and the reference for the
code organisation and practices of the author's projects.

[cargo-generate]: https://github.com/cargo-generate/cargo-generate

## Vocabulary

- **Project type**, or **variant**: one of the five entries of `PROJECT_TYPES`
  in `scripts/options.rhai`. The licence is not part of the variant.
- **Kind**: `std` (`Minimal`, `CLI`) or `embedded` (the three `Embedded`).
- **Answers**: everything that fixes a render: project name, authors,
  description, project type, licence, GitHub username.
- **Render**: a project generated from the template. A **plain** render has
  not been through the formatting hook; a **formatted** one has.

## Layout

- Template files end in `.liquid`. Some exist twice: the `.liquid` one goes to
  generated projects, the plain one configures this repository, as with
  `flake.nix`. They are edited independently.
- Every file at the root reaches generated projects unless it is in the
  `ignore` list of `cargo-generate.toml`. A repository-only file goes in that
  list.
- `scripts/main.rhai` is the `pre` hook: it gets the answers (from `--define`
  when given, from a prompt otherwise), then renames and deletes files to
  select the variant. Each variant has its source directory, `src-<variant>`,
  renamed to `src`.
- `scripts/lints.rhai` holds the whole `[workspace.lints]` block, alphabetical
  inside each section.
- `scripts-post/format.rhai` is the `post` hook. Ignored files are deleted
  between the two hooks, so a `post` script lives outside `scripts` and deletes
  its own directory.
- An `Embedded` render has two workspaces: the root one (`xtask`, and the
  hardware-agnostic `-app` crate) and `firmware/`, with its own `Cargo.toml`,
  lock file and `target`. The `-app` crate of `Embedded (Bare-metal)` has its
  own sources, `src-bare-metal`.

## Template output

- **Readable conditionals come before a formatted output.** Stray spaces and
  unordered lists in a plain render are expected: the `post` hook repairs
  them. Only what the formatters cannot repair needs fixing in the template.
- The formatters of the hook and those verified by `check_format` in
  `xtask/src/main.rs.liquid` are the same list. A formatter goes in both.
- **Nothing is pinned in a render**: the template ships no `flake.lock` and no
  `Cargo.lock`, and its `nixpkgs` input is the `nixpkgs-unstable` branch. A
  render is checked against the `nixpkgs` and the crates of the day, so a
  check can fail without any change to the template.

## Rendering and checking

- `.claude/scripts/render` renders one project type at a jj revision, without
  a prompt. `.claude/scripts/variant-matrix` renders every project type and,
  with `-c`, runs their checks: `-j` runs project types at once, `-u`
  updates kept renders for incremental checks. `.claude/scripts/follow`
  shows a running `variant-matrix -c` to the author;
  `.claude/scripts/follow-pane` opens it in a tmux pane beside the agent, or
  prints its command outside tmux, and closes the pane with `-k`. The agent
  reads the `summary` and the logs of the output directory instead. All four
  print their usage when run with no arguments.
- To verify a change to the template, compare plain renders:

    ```
    .claude/scripts/variant-matrix -r @- <scratch directory>/before
    .claude/scripts/variant-matrix <scratch directory>/after
    diff -r <scratch directory>/before <scratch directory>/after
    ```

    Identical renders need no check. A difference in `Cargo.toml`, Rust
    sources, lints, toolchain, flake, CI or `xtask` needs the checks of the
    affected project types (`-t`, `-c`). A difference in `LICENSE`, source
    headers or the SPDX identifier needs the licence sweep (`-l all`).
- `variant-matrix -c all` takes about 9 minutes for the five project types
  once the Nix store is warm: run it in the background with a timeout of 30
  minutes.
- A background run reads the repository until it ends, as `sh` reads the
  scripts as it goes: edit nothing under `.claude/scripts` until it ends.
- Revisions older than `feat: allow options to be defined from the command
  line` cannot be rendered: `render` fails with `not a terminal`. Read the
  diff of the change instead.

## Changes and commits

- One change per logical unit, committed with `jj commit <files> -m`.
- jj reads `{{project-name}}` in a path as fileset syntax and commits
  nothing: quote the path as `'file:"{{project-name}}/Cargo.toml.liquid"'`.
  A failed `jj commit` in a chain of commands leaves its files in the working
  copy, for the next commit to take: check that each one has succeeded.
- Descriptions follow `type(scope): subject`, with a subject in the
  imperative, lower case, without a final period.
- The type and the scope are among those of `git-z.toml` (the plain one, not
  `git-z.toml.liquid`). When one is missing, add it to `git-z.toml` in the
  same commit.
- A change to the content of the template has the scope `t:<scope>@<variant>`:
  `fix(t:flake@cli): …`. Omit `@<variant>` when every project type is
  affected. `<variant>` is `minimal`, `cli`, `embedded`, `bare-metal`,
  `embassy` or `rtic`.
- A change to a script of `.claude/scripts` has the scope `x:<script>`:
  `env(x:render): …`. A change to several scripts keeps `claude`.
- A change to a skill of `.claude/skills` has the scope `s:<skill>`:
  `env(s:modernise): …`.
- A change to the repository itself has a scope without a prefix, usually
  with the `env` or `chore` type.
- Never add a `Co-Authored-By: Claude` line to a description.
