use lazy_static::lazy_static;
use x86_64::instructions::tables::load_tss;
use x86_64::registers::segmentation::{Segment, CS};
use x86_64::structures::gdt::{Descriptor, GlobalDescriptorTable, SegmentSelector};
use x86_64::structures::tss::TaskStateSegment;
use x86_64::VirtAddr;

pub const DOUBLE_FAULT_IST_INDEX: u16 = 0;

/*
    As we don't have implemented yet the memory managment
    in our kernel, this is a basic stack implementation
    where we use an array to simulate it.

    It will be use as the stack of the double fault handler,
    but for now do not do any memory expensive operation,
    or a stack overflow will corrupt the memory below stack.
*/

lazy_static! {
    static ref TSS: TaskStateSegment = {
        let mut tss = TaskStateSegment::new();
        /*
            We are using the first IST entry for defining
            our double fault handler stack.
        */
        tss.interrupt_stack_table[DOUBLE_FAULT_IST_INDEX as usize] = {
            /*
                4096 bytes are the minimum
                page size that the kernel returns
            */
            const STACK_SIZE: usize = 4096 * 5;
            static mut STACK: [u8; STACK_SIZE] = [0; STACK_SIZE];

            let stack_start = VirtAddr::from_ptr(unsafe { &STACK });
            let stack_end = stack_start + STACK_SIZE;
            stack_end
        };
        tss
    };
}

struct Selectors {
    code_selector: SegmentSelector,
    tss_selector: SegmentSelector,
}

/*
    The GDT helps us to switch between kernel space and user space
    and for loading a TSS structure into the CPU as we don't have
    memory paging
*/

lazy_static! {
    static ref GDT: (GlobalDescriptorTable, Selectors) = {
        let mut gdt = GlobalDescriptorTable::new();
        let code_selector = gdt.add_entry(Descriptor::kernel_code_segment());
        let tss_selector = gdt.add_entry(Descriptor::tss_segment(&TSS));
        (
            gdt,
            Selectors {
                code_selector,
                tss_selector,
            },
        )
    };
}

pub fn init() {
    // Load the gdt instance
    GDT.0.load();

    unsafe {
        // Reload CS register
        CS::set_reg(GDT.1.code_selector);
        // Load tss segment
        load_tss(GDT.1.tss_selector);
    }
}
