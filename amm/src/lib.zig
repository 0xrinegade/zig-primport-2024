const std = @import("std");
const solana = @import("solana");
const instructions = @import("instructions.zig");
const state = @import("state.zig");

pub const ID: [32]u8 = .{
    0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22,
    0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22,
    0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22,
    0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22,
};

pub const PDA_MARKER = "ProgramDerivedAddress";

pub fn processInstruction(
    program_id: *const solana.Pubkey,
    accounts: []const solana.AccountInfo,
    instruction_data: []const u8,
) solana.ProgramResult {
    if (instruction_data.len < 1) {
        return error.InvalidInstructionData;
    }

    const discriminator = instruction_data[0];
    const data = instruction_data[1..];

    switch (discriminator) {
        0 => return instructions.make(accounts, data),
        1 => return instructions.take(accounts, data),
        2 => return instructions.refund(accounts, data),
        else => return error.InvalidInstructionData,
    }
}

pub export fn entrypoint(
    program_id: *const solana.Pubkey,
    accounts: *const solana.AccountInfo,
    instruction_data: []const u8,
) callconv(.C) u64 {
    return @boolToInt(processInstruction(program_id, accounts, instruction_data) catch false);
}