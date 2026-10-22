#![no_std]
#![no_main]

use cortex_m::prelude::*;
use embedded_hal::{digital::OutputPin, spi::SpiBus};
use panic_halt as _;
use rp_pico::{
    entry,
    hal::{
        clocks::{init_clocks_and_plls, Clock},
        fugit::RateExtU32,
        gpio::FunctionSpi,
        pac,
        sio::Sio,
        spi::Spi,
        watchdog::Watchdog,
    },
    Pins,
};

const FPGA_BITSTREAM: &[u8] =
    include_bytes!(concat!(env!("OUT_DIR"), "/fpga_bitstream.bin"));
const XTAL_FREQ_HZ: u32 = 12_000_000;

#[entry]
fn main() -> ! {
    let mut pac = pac::Peripherals::take().unwrap();
    let core = pac::CorePeripherals::take().unwrap();
    let mut watchdog = Watchdog::new(pac.WATCHDOG);
    let clocks = init_clocks_and_plls(
        XTAL_FREQ_HZ,
        pac.XOSC,
        pac.CLOCKS,
        pac.PLL_SYS,
        pac.PLL_USB,
        &mut pac.RESETS,
        &mut watchdog,
    )
    .ok()
    .unwrap();
    let mut delay = cortex_m::delay::Delay::new(core.SYST, clocks.system_clock.freq().to_Hz());

    let sio = Sio::new(pac.SIO);
    let pins = Pins::new(
        pac.IO_BANK0,
        pac.PADS_BANK0,
        sio.gpio_bank0,
        &mut pac.RESETS,
    );

    let mut fpga_power = pins.gpio12.into_push_pull_output();
    let mut fpga_enable = pins.gpio13.into_push_pull_output();
    let mut fpga_cs = pins.gpio1.into_push_pull_output();

    fpga_cs.set_high().unwrap();
    fpga_enable.set_low().unwrap();
    fpga_power.set_low().unwrap();
    delay.delay_ms(10);
    fpga_power.set_high().unwrap();
    delay.delay_ms(10);
    fpga_enable.set_high().unwrap();
    delay.delay_ms(10);

    let mosi = pins.gpio3.into_function::<FunctionSpi>();
    let miso = pins.gpio0.into_function::<FunctionSpi>();
    let sclk = pins.gpio2.into_function::<FunctionSpi>();
    let spi = Spi::<_, _, _, 8>::new(pac.SPI0, (mosi, miso, sclk));
    let mut spi = spi.init(
        &mut pac.RESETS,
        clocks.peripheral_clock.freq(),
        1_600_000.Hz(),
        embedded_hal::spi::MODE_0,
    );

    fpga_cs.set_low().unwrap();
    let transfer = spi.write(FPGA_BITSTREAM);
    fpga_cs.set_high().unwrap();
    if transfer.is_err() {
        fpga_enable.set_low().unwrap();
    }

    loop {
        cortex_m::asm::wfi();
    }
}