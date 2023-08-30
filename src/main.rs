#![no_std]
#![no_main]
#![feature(custom_test_frameworks)]
#![test_runner(rustos::test_runner)]
#![reexport_test_harness_main = "test_main"]

use core::panic::PanicInfo;
use rustos::{print, println};

#[no_mangle]
pub extern "C" fn _start() -> ! {
    println!("Hello World{}", "!");

    rustos::init();

    println!("It did not crash");

    for _ in 0..10000 {
        print!("-");
    }

    #[cfg(test)]
    test_main();

    rustos::hlt_loop();
}

/// This function is called on panic.
#[cfg(not(test))]
#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    println!("{}", info);
    rustos::hlt_loop()
}

#[cfg(test)]
#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    rustos::test_panic_handler(info)
}
