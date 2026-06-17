const Gdt = @import("Gdt.zig");
fn print(comptime str: []const u8) void {
    // a many item pointer so we can index and volatile so compiler doesnt mess with it
    var video_memory: [*]volatile u16 = @ptrFromInt(0xB8000);
    for (str, 0..) |char, i| {
        video_memory[i] = 0x0F00 | @as(u16, char);
    }
}

export fn kmain(multiboot_structure: *anyopaque, magic_number: u32) callconv(.c) noreturn {
    _ = multiboot_structure;
    _ = &magic_number;
    const gdt = Gdt.init();
    _ = gdt;
    print("Hello World! this is my Kernel ~AT");

    while (true) {}
}
