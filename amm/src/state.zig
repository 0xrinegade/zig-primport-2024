const std = @import("std");
const solana = @import("solana");

pub const Pool = struct {
    const Self = @This();

    authority: solana.Pubkey,
    token_a_mint: solana.Pubkey,
    token_b_mint: solana.Pubkey,
    token_a_account: solana.Pubkey,
    token_b_account: solana.Pubkey,
    fee_numerator: u64,
    fee_denominator: u64,

    pub const LEN: usize = 32 * 5 + 8 * 2;

    pub fn fromAccountInfo(account_info: *const solana.AccountInfo) !Self {
        if (account_info.data_len != Self.LEN) {
            return error.InvalidAccountLength;
        }
        
        const data = account_info.data;
        return Self{
            .authority = @ptrCast(*const solana.Pubkey, data[0..32]).*,
            .token_a_mint = @ptrCast(*const solana.Pubkey, data[32..64]).*,
            .token_b_mint = @ptrCast(*const solana.Pubkey, data[64..96]).*,
            .token_a_account = @ptrCast(*const solana.Pubkey, data[96..128]).*,
            .token_b_account = @ptrCast(*const solana.Pubkey, data[128..160]).*,
            .fee_numerator = @ptrCast(*const u64, data[160..168]).*,
            .fee_denominator = @ptrCast(*const u64, data[168..176]).*,
        };
    }
};