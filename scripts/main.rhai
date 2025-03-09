import "scripts/options" as options;
import "scripts/lints" as lints;
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
variable::set("lints", lints::LINTS);

////////////////////////////////////////////////////////////////////////////////
//                               File selection                               //
////////////////////////////////////////////////////////////////////////////////

file::rename(`LICENSE-${license}`, "LICENSE");
for l in options::LICENSES {
    if l != license {
        file::delete(`LICENSE-${l}`);
    }
}

file::rename(project.src.src, project.src.dst);
if project.tests != () {
    file::rename(project.tests.src, project.tests.dst);
}

for type in options::PROJECT_TYPE_INFO.values() {
    if type != project {
        file::delete(type.src.src);
        if type.tests != () {
            file::delete(type.tests.src);
        }
    }
}

if project.kind == "embedded" {
    file::rename("build.rs", "firmware/{{project-name}}-fw/build.rs");
    file::delete("{{project-name}}");
} else {
    if project_type == "Minimal" {
        file::delete("build.rs");
    } else {
        file::rename("build.rs", "{{project-name}}/build.rs");
    }

    file::delete("firmware");
}
