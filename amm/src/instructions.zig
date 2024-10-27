const std = @import("std");
const solana = @import("solana");
const state = @import("state.zig");
const token = @import("token.zig");

pub fn make(accounts: []const solana.AccountInfo, data: []const u8) solana.ProgramResult {
    if (accounts.len < 7) {
        return error.NotEnoughAccountKeys;
    }

    const [_]solana.AccountInfo{
        authority,
        pool,
        token_a_mint,
        token_b_mint,
        token_a_account,
        token_b_account,
        token_program,
    } = accounts[0..7].*;

    if (!authority.is_signer) {
        return error.MissingRequiredSignature;
    }

    const fee_numerator = @ptrCast(*const u64, data[0..8]).*;
    const fee_denominator = @ptrCast(*const u64, data[8..16]).*;

    if (fee_denominator == 0) {
        return error.InvalidFees;
    }

    // Initialize pool data
    const pool_data = state.Pool{
        .authority = authority.key.*,
        .token_a_mint = token_a_mint.key.*,
        .token_b_mint = token_b_mint.key.*,
        .token_a_account = token_a_account.key.*,
        .token_b_account = token_b_account.key.*,
        .fee_numerator = fee_numerator,
        .fee_denominator = fee_denominator,
    };

    @memcpy(pool.data[0..state.Pool.LEN], std.mem.asBytes(&pool_data));

    return solana.SUCCESS;
}

pub fn take(accounts: []const solana.AccountInfo, data: []const u8) solana.ProgramResult {
    if (accounts.len < 8) {
        return error.NotEnoughAccountKeys;
    }

    const [_]solana.AccountInfo{
        user,
        pool,
        user_token_a,
        user_token_b,
        pool_token_a,
        pool_token_b,
        token_program,
    } = accounts[0..7].*;

    if (!user.is_signer) {
        return error.MissingRequiredSignature;
    }

    const amount_in = @ptrCast(*const u64, data[0..8]).*;
    const minimum_amount_out = @ptrCast(*const u64, data[8..16]).*;

    const pool_data = try state.Pool.fromAccountInfo(pool);
    const amount_out = calculateAmountOut(amount_in, pool_data);

    if (amount_out < minimum_amount_out) {
        return error.ExcessiveSlippage;
    }

    // Perform token swaps
    try token.transfer(user_token_a, pool_token_a, user, amount_in);
    try token.transfer(pool_token_b, user_token_b, pool, amount_out);

    return solana.SUCCESS;
}

pub fn refund(accounts: []const solana.AccountInfo, data: []const u8) solana.ProgramResult {
    if (accounts.len < 7) {
        return error.NotEnoughAccountKeys;
    }

    const [_]solana.AccountInfo{
        authority,
        pool,
        token_a_account,
        token_b_account,
        authority_token_a,
        authority_token_b,
        token_program,
    } = accounts[0..7].*;

    if (!authority.is_signer) {
        return error.MissingRequiredSignature;
    }

    const pool_data = try state.Pool.fromAccountInfo(pool);
    if (!pool_data.authority.equals(authority.key.*)) {
        return error.InvalidAuthority;
    }

    // Transfer remaining tokens back to authority
    const token_a_balance = try token.getBalance(token_a_account);
    const token_b_balance = try token.getBalance(token_b_account);

    try token.transfer(token_a_account, authority_token_a, pool, token_a_balance);
    try token.transfer(token_b_account, authority_token_b, pool, token_b_balance);

    // Close the pool account
    const pool_lamports = pool.lamports.*;
    pool.lamports.* = 0;
    authority.lamports.* += pool_lamports;

    return solana.SUCCESS;
}

fn calculateAmountOut(amount_in: u64, pool: state.Pool) u64 {
    const fee = (amount_in * pool.fee_numerator) / pool.fee_denominator;
    const amount_in_with_fee = amount_in - fee;
    return amount_in_with_fee; // Simplified constant product formula
}