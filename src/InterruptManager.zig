const Self = @This();

const IdtEntry = packed struct(u128) {
    offset_low: u16, // ISR (interrupt handler) address
    // zig fmt: off
    segment_selector: u16, // is the code selector the cpu will load into
                           // before running the interrupt handler
    // zig fmt: on
    ist: u3 = 0, //Interrupt stack table set to 0 if u dont use it
    reserved1: u5 = 0,

    //attirbutes
    gate_type: u4 = 0xE, //0xE means its a 64bit interrupt gate 0xF is a 64bit Trap gate
    s: u1 = 0,
    dpl: u2 = 0, // Descriptor Privilage Level
    present_bit: u1 = 1,

    offset_mid: u16,
    offset_high: u32,
    reserved2: u32 = 0,
};

var IdtPtr = packed struct {
    limit: u16,
    base: u64,
};

const idt_entry_count = 256;
const idt_entries: [idt_entry_count]IdtEntry = undefind;
var idt_ptr = undefind;
pub fn init() void {
    idt_ptr.base = @intFromPtr(&idt_entries);
    idt_ptr.limit = @as(u16, @sizeOf(@TypeOf(idt_entries))) - 1;
    asm volatile ("lidt %[idt_ptr]"
        :
        : [idt_ptr] "*m" (idt_ptr),
    );
}

pub fn setIdtEntry(this: *Self, vector: u8, isr_address: u64, selector: u16, flags: u8) void {
    // zig fmt: off
    self.idt_entries[vector] = .{
        .offset_low       = @truncate(isr_address),
        .segment_selector = selector, 
        .ist              = 0,
        .reserved1        = 0,
        
        .gate_type        = @truncate(flags & 0x0F),        
        .s                = @truncate((flags >> 4) & 0x01),
        .dpl              = @truncate((flags >> 5) & 0x03),
        .present_bit      = @truncate((flags >> 7) & 0x01),
        
        .offset_mid       = @truncate(isr_address >> 16),
        .offset_high      = @truncate(isr_address >> 32),
        .reserved2        = 0,
    };
    // zig fmt: on
}
