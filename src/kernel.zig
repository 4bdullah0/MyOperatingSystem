const Gdt = @import("Gdt.zig");
const Port = @import("Port.zig");
const console = @import("console.zig");
export fn kmain(multiboot_structure: *anyopaque, magic_number: u32) callconv(.c) noreturn {
    _ = multiboot_structure;
    _ = &magic_number;
    const gdt = Gdt.init();
    _ = gdt;

    console.print("Hello World! this is my Kernel ~AT\n");
    console.print("Hello World! this is my Kernel ~AT~2\n");

    while (true) {}
}
