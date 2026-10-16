// Formats the generated project with the formatters of its devshell.

let formatters = [
    ["cargo", "fmt", "--all"],
    ["nixpkgs-fmt", "."],
    ["taplo", "fmt"],
    ["prettier", "--write", "."],
];

if variable::get("project-kind") == "embedded" {
    formatters.insert(1, ["cargo", "fmt", "--manifest-path=firmware/Cargo.toml", "--all"]);
}

const SCRIPT = "scripts-post/format.sh";

let commands = formatters.map(
    |formatter| formatter.extract(1).reduce(|command, arg| `${command} ${arg}`, formatter[0])
);

try {
    file::write(SCRIPT, ["set -e"] + commands);
    system::command("nix", ["develop", ".#ci", "-c", "sh", SCRIPT]);
} catch (err) {
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
