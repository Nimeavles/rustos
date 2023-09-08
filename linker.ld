ENTRY(main)
OUTPUT_FORMAT(binary)

MEMORY {
    ram : org = 0x7c00, l = 12K
}

SECTIONS {
    . = 0x7c00;

    .text : {
        *(.text)
    } >ram

    /DISCARD/ : {
        *(.comment)
        *(.eh_frame)
        *(.rel.eh_frame)
    }
}
