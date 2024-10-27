const std = @import("std");
const solana = @import("solana");

pub const TOKEN_PROGRAM_ID: [32]u8 = .{
    0x06, 0xa7, 0xd5, 0x17, 0x19, 0x4b, 0xdc, 0x56,
    0x41, 0x4c, 0x42, 0xf7, 0x8c, 0x2c, 0x3e, 0x1c,
    0xb4, 0x1a, 0xb1, 0x9f, 0xa9, 0x4e, 0xc9, 0x41,
    0x49, 0x46, 0x9a, 0x31, 0x5a, 0x65, 0x72, 0x5a,
};

pub fn transfer(
    from: *const solana.AccountInfo,
    to: *const solana.AccountInfo,
    authority: *const solana.AccountInfo,
    amount: u64,
) solana.ProgramResult {
    const instruction_data = [_]u8{3} ++ std.mem.toBytes(amount);
    
    const accounts = [_]solana.AccountMeta{
        .{ .pubkey = from.key.*, .is_writable = true, .is_signer = false },
        .{ .pubkey = to.key.*, .is_writable = true, .is_signer = false },
        .{ .pubkey = authority.key.*, .is_writable = false, .is_signer = true },
    };

    try solana.program.invoke(
        &solana.Instruction{
            .program_id = &TOKEN_PROGRAM_ID,
            .accounts = &accounts,
            .data = &instruction_data,
        },
        &[_]*const solana.AccountInfo{ from, to, authority },
    );

    return solana.SUCCESS;
}

pub fn getBalance(account: *const solana.AccountInfo) !u64 {
    if (account.data_len < 8) {
        return error.InvalidAccountLength;
    }
    return @ptrCast(*const u64, account.data[64..72]).*;
}