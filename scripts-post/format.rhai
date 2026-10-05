// Formats the generated project with the formatters of its devshell.

const FORMATTERS = "cargo fmt --all && "
    + "nixpkgs-fmt . && "
    + "taplo fmt && "
    + "prettier --write .";

try {
    system::command("nix", ["develop", ".#ci", "-c", "sh", "-c", FORMATTERS]);
} catch (err) {
    print(`⚠️   The project has not been formatted: ${err}`);
    print("    Run this in its devshell before the first commit:");
    print(`    ${FORMATTERS}`);
}

// NOTE: Post-generation scripts cannot be in the `ignore` list of
// `cargo-generate.toml`, as ignored files are deleted before they run.
file::delete("scripts-post");
