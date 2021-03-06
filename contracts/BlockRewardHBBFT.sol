pragma solidity 0.4.25;

import "./abstracts/BlockRewardBase.sol";
import "./interfaces/IERC20Token.sol";


contract BlockRewardHBBFT is BlockRewardBase {

    // ============================================== Constants =======================================================

    // These value must be changed before deploy
    uint256 public constant BLOCK_REWARD = 0 ether; // in ERC20 tokens
    address public constant ERC20_TOKEN_CONTRACT = address(0);

    // ================================================ Events ========================================================

    event RewardedERC20ByBlock(address[] receivers, uint256[] rewards);

    // =============================================== Setters ========================================================

    function reward(address[] benefactors, uint16[] /*kind*/)
        external
        onlySystem
        returns (address[], uint256[])
    {
        // Mint ERC20 tokens to validators and their stakers as block reward.
        // This is not bridge's fee distribution.
        // This call makes sense only if `BLOCK_REWARD` and `ERC20_TOKEN_CONTRACT`
        // constants above are not equal to zero.
        _mintTokensForStakers(benefactors);

        // We don't accrue any block reward in native coins to validator here.
        // We just mint native coins by bridge if needed.
        return _mintNativeCoinsByBridge();
    }

    // =============================================== Private ========================================================

    // Mint ERC20 tokens for each staker of each active validator
    function _mintTokensForStakers(address[] benefactors) internal {
        if (BLOCK_REWARD == 0) return;
        if (ERC20_TOKEN_CONTRACT == 0) return;

        uint256 stakingEpoch = _getStakingEpoch();

        if (stakingEpoch == 0) {
            return;
        }

        uint256 poolReward = BLOCK_REWARD / snapshotValidators(stakingEpoch).length;

        for (uint256 i = 0; i < benefactors.length; i++) {
            (
                address[] memory receivers,
                uint256[] memory rewards
            ) = _distributePoolReward(stakingEpoch, benefactors[i], poolReward);

            IERC20Token(ERC20_TOKEN_CONTRACT).mintReward(receivers, rewards);
            
            emit RewardedERC20ByBlock(receivers, rewards);
        }
    }
}
