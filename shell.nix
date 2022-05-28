{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
  buildInputs = [
    # Build toolchain.
    rustup{% if project-kind == "embedded" %}

    # Debugging tools.
    openocd
    gcc-arm-embedded{% endif %}
  ];
}
