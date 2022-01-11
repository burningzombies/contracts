// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

/// @title StakingRewards
/// @author Pangolin
/// @author root36x9 (ERC20 -> ERC721)
contract StakingRewards is ReentrancyGuard, Ownable, ERC721Holder {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Rewards token address.
    IERC20 public rewardsToken;

    /// @dev Staking token address.
    IERC721 public stakingToken;

    /// @dev Timestamp of the period finish.
    uint256 public periodFinish = 0;

    /// @dev Reward rate (increase when notifyRewardAmount called).
    uint256 public rewardRate = 0;

    /// @dev Rewards duration.
    uint256 public rewardsDuration = 31556926;

    /// @dev Last updated timestamp.
    uint256 public lastUpdateTime;

    /// @dev Rewards per token stored.
    uint256 public rewardPerTokenStored;

    /// @dev Total staked amount.
    uint256 private _totalSupply;

    /// @dev Mapping from user to paid amount per token.
    mapping(address => uint256) public userRewardPerTokenPaid;

    /// @dev Mapping from user address to rewards.
    mapping(address => uint256) public rewards;

    /// @dev Mapping from accounts to staked amount.
    mapping(address => uint256) private _balances;

    /// @dev Mapping from tokenId to accounts.
    mapping(uint256 => address) private _owners;

    /// @dev Emitted when owner send reward tokens.
    /// @param reward Reward amount.
    event RewardAdded(uint256 reward);

    /// @dev Emitted when user stakes tokens.
    /// @param user Sender address.
    /// @param tokenId Staked token.
    event Staked(address indexed user, uint256 indexed tokenId);

    /// @dev Emitted when user withdrawn the staked tokens.
    /// @param user Sender address.
    /// @param tokenId Withdrawn token.
    event Withdrawn(address indexed user, uint256 indexed tokenId);

    /// @dev Emitted when user claim rewards.
    /// @param user Sender address.
    /// @param reward Claimed amount.
    event RewardPaid(address indexed user, uint256 reward);

    /// @dev Emitted when rewards duration updated.
    /// @param newDuration New duration.
    event RewardsDurationUpdated(uint256 newDuration);

    /// @dev Emitted when ERC20 recovered.
    /// @param token Recovered token address,
    /// @param amount recovered amount.
    event Recovered(address token, uint256 amount);

    /// @param _rewardsToken Rewards token address.
    /// @param _stakingToken Staking token address.
    constructor(address _rewardsToken, address _stakingToken) {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC721(_stakingToken);
    }

    /// @dev Getter for the staked amount.
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @dev Getter for the staked amount by user.
    /// @param account User address.
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /// @dev Staked token's owner.
    /// @param tokenId Token ID.
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _owners[tokenId];
    }

    /// @dev Getter for the last time reward applicable
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /// @dev Getter for the reward per token.
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
    }

    /// @dev Total earned amount for the given account.
    /// @param account Address.
    function earned(address account) public view returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    /// @dev Get rewards for duration..
    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /// @dev Stake the tokens.
    /// @param tokenIds Token IDs.
    function stake(uint256[] calldata tokenIds)
        external
        nonReentrant
        updateReward(_msgSender())
    {
        require(tokenIds.length > 0, "Cannot stake 0");

        for (uint256 i = 0; tokenIds.length > i; i++) {
            IERC721(stakingToken).safeTransferFrom(
                _msgSender(),
                address(this),
                tokenIds[i]
            );

            _owners[tokenIds[i]] = _msgSender();

            emit Staked(_msgSender(), tokenIds[i]);
        }

        _totalSupply = _totalSupply.add(tokenIds.length);
        _balances[_msgSender()] = _balances[_msgSender()].add(tokenIds.length);
    }

    /// @dev Withdraw staked tokens.
    /// @param tokenIds Token IDs.
    function withdraw(uint256[] memory tokenIds)
        public
        nonReentrant
        updateReward(_msgSender())
    {
        require(tokenIds.length > 0, "Cannot withdraw 0");

        for (uint256 i = 0; tokenIds.length > i; i++) {
            require(
                ownerOf(tokenIds[i]) == _msgSender(),
                "Only owner of the token can withdraw"
            );

            IERC721(stakingToken).safeTransferFrom(
                address(this),
                _msgSender(),
                tokenIds[i]
            );

            emit Withdrawn(_msgSender(), tokenIds[i]);
        }

        _totalSupply = _totalSupply.sub(tokenIds.length);
        _balances[_msgSender()] = _balances[_msgSender()].sub(tokenIds.length);
    }

    /// @dev Claim tokens.
    function getReward() public nonReentrant updateReward(_msgSender()) {
        uint256 reward = rewards[_msgSender()];
        if (reward > 0) {
            rewards[_msgSender()] = 0;
            IERC20(rewardsToken).safeTransfer(_msgSender(), reward);
            emit RewardPaid(_msgSender(), reward);
        }
    }

    /// @dev Always needs to update the balance of the contract when calling this method.
    /// @param reward Reward amount.
    function notifyRewardAmount(uint256 reward)
        external
        onlyOwner
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = IERC20(rewardsToken).balanceOf(address(this));
        require(
            rewardRate <= balance.div(rewardsDuration),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /// @dev Added to support recovering LP Rewards from other systems
    /// such as BAL to be distributed to holders
    /// @param tokenAddress Token address.
    /// @param tokenAmount Amount.
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
        nonReentrant
    {
        require(
            tokenAddress != address(stakingToken),
            "Cannot withdraw the staking token"
        );
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /// @dev Setter for finish the period.
    /// @param timestamp Timestamp
    function setPeriodFinish(uint256 timestamp)
        external
        onlyOwner
        updateReward(address(0))
    {
        periodFinish = timestamp;
    }

    /// @dev Setter for the rewards duration
    /// @param _rewardsDuration Duration.
    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        require(_rewardsDuration > 0, "Reward duration can't be zero");
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
}
