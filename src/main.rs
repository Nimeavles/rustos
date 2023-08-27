#![no_std]
#![no_main]

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

// Buffer to display on screen
static HELLO: &[u8] = b"Hello World";

#[no_mangle]
pub extern "C" fn _start() -> ! {
    // Cast 0xb8000 into a raw pointer; 0xb8000 is the address
    // where vga buffer is located

    let vga_buffer = 0xb8000 as *mut u8;

    for (i, &byte) in HELLO.iter().enumerate() {
        unsafe {
            *vga_buffer.offset(i as isize * 2) = byte;
            *vga_buffer.offset(i as isize * 2 + 1) = 0x6;
        }
    }

    loop {}
}
