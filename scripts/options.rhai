// Options and their associated data.

export const PROJECT_TYPES = [
    "Minimal",
    "CLI",
    "Embedded (Bare-metal)",
    "Embedded (Embassy)",
    "Embedded (RTIC)",
];

export const PROJECT_TYPE_INFO = #{
    "Minimal": #{
        kind: "std",
        src: #{
            src: "{{project-name}}/src-minimal",
            dst: "{{project-name}}/src",
        },
        tests: (),
    },
    "CLI": #{
        kind: "std",
        src: #{
            src: "{{project-name}}/src-cli",
            dst: "{{project-name}}/src",
        },
        tests: #{
            src: "{{project-name}}/tests-cli",
            dst: "{{project-name}}/tests",
        },
    },
    "Embedded (Bare-metal)": #{
        kind: "embedded",
        src: #{
            src: "firmware/{{project-name}}-fw/src-bare-metal",
            dst: "firmware/{{project-name}}-fw/src",
        },
        tests: (),
    },
    "Embedded (Embassy)": #{
        kind: "embedded",
        src: #{
            src: "firmware/{{project-name}}-fw/src-embassy",
            dst: "firmware/{{project-name}}-fw/src",
        },
        tests: (),
    },
    "Embedded (RTIC)": #{
        kind: "embedded",
        src: #{
            src: "firmware/{{project-name}}-fw/src-rtic",
            dst: "firmware/{{project-name}}-fw/src",
        },
        tests: (),
    },
};

export const LICENSES = [
    "AGPL-3.0",
    "GPL-3.0",
    "MPL-2.0",
    "Apache-2.0",
    "MIT",
];
