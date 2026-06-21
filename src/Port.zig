const Self = @This();

number: u16, // port number

pub fn init(port_number: u16) Self {
    return .{
        .number = port_number,
    };
}

//--------------8 bit
pub fn read8(this: Self) u8 {
    return asm volatile (
        \\inb %[port], %[result_data] 
        : [result_data] "{al}" (-> u8),
        : [port] "N{dx}" (this.number),
    );
}

pub fn write8(this: Self, data: u8) void {
    asm volatile (
        \\outb %[port] , %[data]
        : [data] "{al}" (data),
        : [port] "N{dx}" (this.number),
    );
}

//--------------16 bit
pub fn read16(this: Self) u16 {
    return asm volatile (
        \\inw %[port], %[result_data] 
        : [result_data] "{ax}" (-> u16),
        : [port] "N{dx}" (this.number),
    );
}

pub fn write16(this: Self, data: u16) void {
    asm volatile (
        \\outw %[port] , %[data]
        : [data] "{ax}" (data),
        : [port] "N{dx}" (this.number),
    );
}

//--------------32 bit
pub fn read32(this: Self) u32 {
    return asm volatile (
        \\inl %[port], %[result_data] 
        : [result_data] "{eax}" (-> u32),
        : [port] "N{dx}" (this.number),
    );
}

pub fn write32(this: Self, data: 32) void {
    asm volatile (
        \\outl %[port] , %[data]
        : [data] "{eax}" (data),
        : [port] "N{dx}" (this.number),
    );
}
