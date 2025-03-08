// Options and their associated data.

export const PROJECT_TYPES = [
    "Minimal",
    "CLI",
    "Embedded (Bare-metal)",
    "Embedded (RTIC)",
];

export const PROJECT_TYPE_INFO = #{
    "Minimal": #{
        kind: "std",
        src: "src-minimal",
        tests: (),
    },
    "CLI": #{
        kind: "std",
        src: "src-cli",
        tests: "tests-cli",
    },
    "Embedded (Bare-metal)": #{
        kind: "embedded",
        src: "src-bare-metal",
        tests: (),
    },
    "Embedded (RTIC)": #{
        kind: "embedded",
        src: "src-rtic",
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
