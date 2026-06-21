// a `static` many item pointer so we can index out of bounds &
// volatile so compiler doesnt mess with it
const video_memory: [*]volatile u16 = @ptrFromInt(0xB8000);
var cursor_position: usize = 0;

// VGA is 80 columns and 25 rows

pub fn print(comptime str: []const u8) void {
    for (str) |char| {
        if (char == '\n') {
            const row_current = cursor_position / 80; // integer divison -> no remainder
            const row_next = row_current + 1;
            // multiply by 80 to get the first column of the next row
            cursor_position = row_next * 80;
            continue; // to not print an actual \n on the screen
        }
        video_memory[cursor_position] = 0x0F00 | @as(u16, char);
        cursor_position += 1;

        if (cursor_position >= 80 * 25) {
            cursor_position = 0;
        }
    }
}
