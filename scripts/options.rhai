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
        main: "main-minimal",
    },
    "CLI": #{
        kind: "std",
        main: "main-cli",
    },
    "Embedded (Bare-metal)": #{
        kind: "embedded",
        main: "main-bare-metal",
    },
    "Embedded (RTIC)": #{
        kind: "embedded",
        main: "main-rtic",
    },
};

export const LICENSES = [
    "AGPL-3.0",
    "GPL-3.0",
    "MPL-2.0",
    "Apache-2.0",
    "MIT",
];

export const BOARDS = [
    "ST Nucleo-L476RG",
    "Custom",
];

export const BOARD_INFO = #{
    "ST Nucleo-L476RG": #{
        chip: "STM32L476RGTx",
        openocd: #{
            target: "stm32l4x",
            interface: "stlink-v2-1",
        },
    },
};

export const CHIPS = [
    "STM32L476RGTx",
    "Custom",
];

export const CHIP_INFO = #{
    "STM32L476RGTx": #{
        name: "STM32L476RGTx",
        target: "thumbv7em-none-eabihf",
        memory: #{
            flash: #{ origin: "0x08000000", length: "1M" },
            sram: #{ origin: "0x20000000", length: "96K" },
        },
        hal: #{
            name: "stm32l4xx-hal",
            feature: "stm32l476",
            crate: "stm32l4xx_hal"
        },
    },
};

export const TARGETS = [
    "thumbv6m-none-eabi",
    "thumbv7em-none-eabi",
    "thumbv7em-none-eabihf",
    "thumbv7m-none-eabi",
    "thumbv8m.base-none-eabi",
    "thumbv8m.main-none-eabi",
    "thumbv8m.main-none-eabihf",
];

export const HAL_INFO = #{
    "stm32l4xx-hal": #{ version: "0.7.1" },
};
