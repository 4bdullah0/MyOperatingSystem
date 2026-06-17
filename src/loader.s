// dest , src


.set MAGIC, 0x1badb002 // magic number for GRUB
.set FLAGS, (1<<0 | 1<<1)
.set CHECKSUM, -(MAGIC + FLAGS)


.section .multiboot
.long MAGIC
.long FLAGS
.long CHECKSUM


.section .text
.extern kmain
.global loader // entry point

loader:
    mov $kernel_stack , %esp // setting the stack pointer to a pointer of the stack
    push %eax // this pushes the multiboot structure from the AX register to kmain (C callconv)
    push %ebx // this pushes the magic number from the BX register to kmain (````)
    call kmain


_stop:
    cli      // clears the interrupt flag
    hlt      // hults the cpu (pauses it until next interrupt)
    jmp _stop// infinite loop 






.section .bss
.space 2*1024*1024 // adding space between the kernel stack 
                   // and other things like the bootloader etc.. 
                   // because the stack grows to the left 
                   // this way is a saftey thing to not overwrite anything
kernel_stack:



