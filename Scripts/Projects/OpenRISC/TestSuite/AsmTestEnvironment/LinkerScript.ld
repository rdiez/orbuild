
MEMORY
{
    /* The exception vectors actually start at 0x100, but if you specify that address here,
       the "--output-target binary" step will start from address 0 with the contents meant for address 0x100 */
    exception_vectors : ORIGIN =  0 , LENGTH = 8K
    ram               : ORIGIN =  8K, LENGTH = 2M - 8K
}

SECTIONS
{
    .exception_vectors :
    {
        KEEP(*(.exception_vectors))
    } > exception_vectors

    .text :
    {
        *(.text)
        *(.text.*)
        *(.rodata)
        *(.rodata.*)
    } > ram

    .data :
    {
        *(.data)
        *(.data.*)
    } > ram


    .bss :
    {
        *(.bss)
        *(.bss.*)

        /* WARNING about section size alignment:
           The start-up assembly code can only clear BSS section sizes which are aligned to 4 bytes.
           However, the size of the BSS  section may not be aligned, therefore up to 3 bytes more
           could be zeroed on start-up. This is normally not an issue, as the start of the next section
           is usually aligned too, so those extra bytes should be just padding. I did try the following
           trick to align the BSS section size, to no avail:
           . = ALIGN(., 4);
        */
    } > ram

    _bss_begin = ADDR(.bss);
    _bss_end   = _bss_begin + SIZEOF(.bss);


    .stack ALIGN(16) (NOLOAD):
    {
      *(.stack)
    } > ram
}

ENTRY(_start)  /* Otherwise, --gc-sections would throw everything away. */
