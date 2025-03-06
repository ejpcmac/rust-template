import "scripts/options" as options;
import "scripts/license_header" as license_header;

// Get built-in variables.
let project_name = variable::get("project-name");
let author = variable::get("authors");

// Set an author-name variable without email.
let author_name = author.split(" <")[0];

////////////////////////////////////////////////////////////////////////////////
//                               General params                               //
////////////////////////////////////////////////////////////////////////////////

let description = variable::prompt("Short description of the project");
let project_type = variable::prompt("Project type", "", options::PROJECT_TYPES);
let license = variable::prompt("What license to use?", "GPL-3.0", options::LICENSES);
let github_username = variable::prompt("GitHub username or organisation where the project is hosted");

let project = options::PROJECT_TYPE_INFO[project_type];

let license_spdx = if license == "AGPL-3.0" || license == "GPL-3.0" {
    license + "-only"
} else {
    license
};

let license_header = switch license {
    "AGPL-3.0" => license_header::agpl(project_name, description, author),
    "GPL-3.0" => license_header::gpl(project_name, description, author),
    "MPL-2.0" => license_header::mpl(),
    "Apache-2.0" => license_header::apache(author_name),
    _ => "",
};

variable::set("author-name", author_name);
variable::set("description", description);
variable::set("project-type", project_type);
variable::set("project-kind", project.kind);
variable::set("license", license);
variable::set("license-spdx", license_spdx);
variable::set("license-header", license_header);
variable::set("github-username", github_username);

file::rename(`LICENSE-${license}`, "LICENSE");
for l in options::LICENSES {
    if l != license {
        file::delete(`LICENSE-${l}`);
    }
}

file::rename(`${project.src}`, "src");
if project.tests != () {
    file::rename(`${project.tests}`, "tests");
}

for type in options::PROJECT_TYPE_INFO.values() {
    if type != project {
        file::delete(`${type.src}`);
        if type.tests != () {
            file::delete(`${type.tests}`);
        }
    }
}

if project_type == "Minimal" {
    file::delete("build.rs");
}

if project.kind == "embedded" {
    file::rename("build.rs", "firmware/build.rs");
    file::rename("Cargo.toml", "firmware/Cargo.toml");
    file::rename("src", "firmware/src");
} else {
    file::delete("firmware");
}

////////////////////////////////////////////////////////////////////////////////
//                              Embedded params                               //
////////////////////////////////////////////////////////////////////////////////

if project.kind == "embedded" {
    let board_name = variable::prompt("Board", "", options::BOARDS);
    let board = options::BOARD_INFO[board_name];

    let chip_name = if board != () {
        board.chip
    } else {
        variable::prompt("Chip", "", options::CHIPS)
    };

    let chip = if chip_name in options::CHIP_INFO.keys() {
         options::CHIP_INFO[chip_name]
    } else {
        #{
            name: variable::prompt("Chip"),
            target: variable::prompt("Target", "", options::TARGETS),
            memory: #{
                flash: #{
                    origin: variable::prompt("Flash origin"),
                    length: variable::prompt("Flash length"),
                },
                sram: #{
                    origin: variable::prompt("SRAM origin"),
                    length: variable::prompt("SRAM length"),
                },
            },
        }
    };

    variable::set("chip", chip.name);
    variable::set("target", chip.target);
    variable::set("flash-origin", chip.memory.flash.origin);
    variable::set("flash-length", chip.memory.flash.length);
    variable::set("sram-origin", chip.memory.sram.origin);
    variable::set("sram-length", chip.memory.sram.length);

    if chip.hal != () {
        let hal_version = options::HAL_INFO[chip.hal.name].version;
        let hal_package = `${chip.hal.name} = { version = "${hal_version}", features = ["${chip.hal.feature}", "rt" ] }`;
        variable::set("hal-package", hal_package);
        variable::set("hal-crate", chip.hal.crate);
    } else {
        variable::set("hal-crate", "device_hal");
    }
}
