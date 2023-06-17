{{license-header}}
{{module-attributes}}
use defmt_rtt as _;
use panic_probe as _;

#[rtic::app(device = {{hal-crate}}::pac, dispatchers = [])]
mod app {
    use {{hal-crate}}::prelude::*;

    #[shared]
    struct SharedResources {}

    #[local]
    struct LocalResources {}

    #[init]
    fn init(
        cx: init::Context,
    ) -> (SharedResources, LocalResources, init::Monotonics) {
        defmt::info!("Firmware starting...");

        let _cp = cx.core;
        let dp = cx.device;

        // Clock configuration.
        let mut rcc = dp.RCC.constrain();
        let mut flash = dp.FLASH.constrain();
        let mut pwr = dp.PWR.constrain(&mut rcc.apb1r1);
        let _clocks = rcc.cfgr.freeze(&mut flash.acr, &mut pwr);

        defmt::info!("Firmware initialised!");

        (SharedResources {}, LocalResources {}, init::Monotonics())
    }

    #[idle]
    fn idle(_: idle::Context) -> ! {
        loop {
            continue;
        }
    }
}
