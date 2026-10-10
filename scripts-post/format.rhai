// Formats the generated project with the formatters of its devshell.

const FORMATTERS = [
    ["cargo", "fmt", "--all"],
    ["nixpkgs-fmt", "."],
    ["taplo", "fmt"],
    ["prettier", "--write", "."],
];

try {
    for formatter in FORMATTERS {
        system::command("nix", ["develop", ".#ci", "-c"] + formatter);
    }
} catch (err) {
    let commands = FORMATTERS.map(
        |formatter| formatter.extract(1).reduce(|command, arg| `${command} ${arg}`, formatter[0])
    );
    let commands = commands
        .extract(1)
        .reduce(|commands, command| `${commands} && ${command}`, commands[0]);

    print(`⚠️   The project has not been formatted: ${err}`);
    print("    Run this in its devshell before the first commit:");
    print(`    ${commands}`);
}

// NOTE: Post-generation scripts cannot be in the `ignore` list of
// `cargo-generate.toml`, as ignored files are deleted before they run.
file::delete("scripts-post");
