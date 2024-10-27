const std = @import("std");
const testing = std.testing;
const solana = @import("solana");
const instructions = @import("instructions.zig");
const state = @import("state.zig");

test "make pool" {
    // Setup test accounts
    var authority_account = try createAccount();
    var pool_account = try createAccount();
    var token_a_mint = try createAccount();
    var token_b_mint = try createAccount();
    var token_a_account = try createAccount();
    var token_b_account = try createAccount();
    var token_program = try createAccount();

    const accounts = [_]solana.AccountInfo{
        authority_account,
        pool_account,
        token_a_mint,
        token_b_mint,
        token_a_account,
        token_b_account,
        token_program,
    };

    // Test data
    const data = [_]u8{
        0, 0, 0, 0, 0, 0, 0, 0,  // fee_numerator = 0
        1, 0, 0, 0, 0, 0, 0, 0,  // fee_denominator = 1
    };

    // Execute instruction
    try instructions.make(&accounts, &data);

    // Verify pool state
    const pool = try state.Pool.fromAccountInfo(&pool_account);
    try testing.expectEqual(pool.authority, authority_account.key.*);
    try testing.expectEqual(pool.token_a_mint, token_a_mint.key.*);
    try testing.expectEqual(pool.token_b_mint, token_b_mint.key.*);
}

test "take swap" {
    // Setup test accounts
    var user_account = try createAccount();
    var pool_account = try createAccount();
    var user_token_a = try createAccount();
    var user_token_b = try createAccount();
    var pool_token_a = try createAccount();
    var pool_token_b = try createAccount();
    var token_program = try createAccount();

    const accounts = [_]solana.AccountInfo{
        user_account,
        pool_account,
        user_token_a,
        user_token_b,
        pool_token_a,
        pool_token_b,
        token_program,
    };

    // Test data
    const data = [_]u8{
        100, 0, 0, 0, 0, 0, 0, 0,  // amount_in = 100
        90, 0, 0, 0, 0, 0, 0, 0,   // minimum_amount_out = 90
    };

    // Execute instruction
    try instructions.take(&accounts, &data);
}

fn createAccount() !solana.AccountInfo {
    var key: [32]u8 = undefined;
    try std.crypto.random.bytes(&key);
    
    const lamports = try std.heap.page_allocator.create(u64);
    lamports.* = 1000000;
    
    const data = try std.heap.page_allocator.alloc(u8, 1000);
    
    return solana.AccountInfo{
        .key = &key,
        .is_signer = true,
        .is_writable = true,
        .lamports = lamports,
        .data = data,
        .owner = &ID,
        .rent_epoch = 0,
        .is_executable = false,
    };
}