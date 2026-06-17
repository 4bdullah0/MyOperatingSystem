const size = @import("constants.zig");

const Self = @This();
// this is the actual definition of a GDT **entry**
// each entry is 64bit long -> 8 bytes
// NOTE: arrangment here need to meet
//       the actual memory alignment of a CPU
const SegmentDescriptor = packed struct(u64) {
    limit_low: u16, // Bits 0-15
    base_low: u16, //  Bits 16-31
    base_mid: u8, //   Bits 32-39
    permissions: u8, //Bits 40-47
    limit_high: u4, // Bits 48-51
    flags: u4, //      Bits 52-55
    base_high: u8, //  Bits 56-63
    //              methods
    pub fn getBase(this: SegmentDescriptor) u32 {
        //base_low -> 0 ~ 15
        //base_mid -> 16 ~ 23
        //base_high -> 24 ~ 31
        return @as(u32, this.base_low) | (@as(u32, this.base_mid) << 16) | (@as(u32, this.base_high)) << 24;
    }
    pub fn getLimit(this: SegmentDescriptor) u32 {
        //limit_low -> 0 ~ 15
        //limit_high -> 16 ~ 19
        return @as(u20, this.limit_low) | (@as(u32, this.limit_high) << 16);
    }

    //             functions
    pub fn create(base: u32, limit: u32, permissions: u8) SegmentDescriptor {
        var final_limit = limit;
        // byte granularity means the cpu will read the number as raw bytes no multiplier here
        // maximum 1MB
        var architecture_flags: u4 = 0x4; // Default: 32-bit mode Byte granularity (0x40 in his code)

        if (limit >= size.max_u32) {
            // page granularity means that the cpu will multiply the given number with 4KB
            // maximum here is 4GB of the ram
            architecture_flags = 0xC; // Switch to Page granularity (0xC0 in his code)

            if ((limit & 0xFFF) != 0xFFF) { // is the limit divisable by 4096 by checking the last 12 digits if there all 1 then yes
                final_limit = (limit >> 12) - 1;
            } else {
                final_limit = limit >> 12;
            }
        }

        const base_low: u16 = @truncate(base);
        const base_mid: u8 = @truncate(base >> 16);
        const base_high: u8 = @truncate(base >> 24);

        const limit_low: u16 = @truncate(final_limit);
        const limit_high: u4 = @truncate(final_limit >> 16);

        return .{
            .limit_low = limit_low,
            .base_low = base_low,
            .base_mid = base_mid,
            .permissions = permissions,
            .limit_high = limit_high,
            .flags = architecture_flags,
            .base_high = base_high,
        };
    }
};

// kerenel segments indexes
// zig fmt: off
pub const segment_null_index  = 0;
pub const segment_unused_index= 1;
pub const segment_code_index  = 2;
pub const segment_data_index  = 3;
// zig fmt: on

// ds -> data segment
// cs -> code segment
pub const selector_kernel_ds = segment_data_index * 8; // we multiply by 8 because the first 3 bits are reserved for other uses
// and 3 shift left operations equal to 2*2*2 = 8
pub const selector_kernel_cs = segment_code_index * 8;

const gdt_entry_count = 4;

pub const gdt_table align(8) = block: {
    var arr: [gdt_entry_count]SegmentDescriptor = @splat(SegmentDescriptor.create(0, 0, 0));
    arr[segment_code_index] = SegmentDescriptor.create(0, 64 * size.mega_byte, 0x9A);
    arr[segment_data_index] = SegmentDescriptor.create(0, 64 * size.mega_byte, 0x92);
    break :block arr; // return it to the gdt_table
};

const GdtPtr = packed struct(u48) {
    limit: u16,
    base: u32,
};

//sub system pattern (single GDT instnace for the whole OS)
pub fn init() void {
    //first we create a gdt pointer
    const gdt_ptr = GdtPtr{
        .limit = @sizeOf(@TypeOf(gdt_table)) - 1, // we subtract 1 byte from the total size of table
        // because thats the last addressable byte in the table
        // remember arrays go from 0 ~ N
        .base = @intFromPtr(&gdt_table),
    };
    // asm : output : input : clobbers
    asm volatile (
    //load gdt and  parenthesis to dereference the pointer
        \\lgdt (%[ptr]) 
        //pushl pushes stuff to the stack
        \\pushl %[cs_selector]
        //the next line means push `the address of` 1 Label and because its a numric name
        //you can add an f suffix meaning assembler can find it forward
        \\pushl $1f 
        //retf or lret does two pop on the stack the first pop value its gonna load
        //it into the instruction pointer register and the seconds gonna
        //load it in the code segment register
        \\lret 
        // this label block flushes the data segment registers
        // and replaces them with our data segment selector
        \\1:
        //the first commands moves the ds to a register because segment registers doesnt accept literals
        \\  mov %[ds_selector], %%ax
        \\  mov %%ax , %%ds
        //es -> extra segment
        \\  mov %%ax , %%es
        \\  mov %%ax , %%fs
        \\  mov %%ax , %%gs
        //ss -> stack segment
        \\  mov %%ax , %%ss
        :
        // r -> compiler gonna pick any general purpose register
        : [ptr] "r" (&gdt_ptr),
          // n -> instead of r to tell the compiler that this is
          // an immediate numeric value to not waste a register
          [cs_selector] "n" (selector_kernel_cs),
          [ds_selector] "n" (selector_kernel_ds),
        : .{ .ax = true });
}
