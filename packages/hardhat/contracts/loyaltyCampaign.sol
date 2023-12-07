//SPDX-License-Identifier: UNLICENSED
// This contract is not licensed for any use other than learning.
pragma solidity ^0.8.0;

// Useful for debugging. Remove when deploying to a live network.
import "hardhat/console.sol";

// Interfaces
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title LoyaltyCampaign
 * @dev Implements funding, custom distribution, and redemption of crypto loyalty rewards
 */
contract LoyaltyCampaign is AccessControl, ERC20Burnable {
	// Access control roles
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

	// Campaign structures
	struct Campaign {
		string name;
		string description;
		address creator;
		uint256 goalAmount;
		uint256 rewardRate;
		uint256 totalRewards;
		uint256 startDate;
		uint256 endDate;
		mapping(address => uint256) userRewards; // Track user rewards
		string metadataCID; // Content Id for campaign metadata
	}

	// Campaign ID to Campaign mapping
	mapping(uint256 => Campaign) public campaigns;
	uint256 public nextCampaignId;

	// Events for tracking campaign actions
	event CampaignCreated(
		uint256 indexed campaignId,
		string name,
		address creator
	);
	event CampaignFunded(
		uint256 indexed campaignId,
		uint256 amount
	);
	event RewardsDistributed(
		uint256 indexed campaignId,
		address indexed user,
		uint256 amount
);
	event RewardsRedeemed(
		uint256 indexed campaignId,
		address indexed user,
		uint256 amount
);

	// Contructor to set up the token and access control
	constructor() ERC20("LoyaltyToknX", "LTX") public {
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setupRole(MINTER_ROLE, msg.sender);
		_setupRole(BURNER_ROLE, msg.sender);
	}

	// Create a new campaign
	function createCampaign(
		string memory name,
		string memory description,
		address creator,
		uint256 goalAmount,
		uint256 rewardRate,
		uint256 startDate,
		uint256 endDate,
		string memory metadataCID
	) public onlyRole(DEFAULT_ADMIN_ROLE) {
		uint256 campaignId = nextCampaignId++;
		Campaign storage newCampaign = campaigns[campaignId];
		newCampaign.name = name;
		newCampaign.description = description;
		newCampaign.creator = msg.sender;
		newCampaign.goalAmount = goalAmount;
		newCampaign.rewardRate = rewardRate;
		newCampaign.startDate = startDate;
		newCampaign.endDate = endDate;
		newCampaign.metadataCID = metadataCID;

		emit CampaignCreated(campaignId, name, creator);
	}

	// Fund a campaign and mint tokens
	function fundCampaign(uint256 campaignId, uint256 amount) external onlyRole(MINTER_ROLE) {
		require(campaigns[campaignId].creator != address(0), "Invalid campaign ID");

		campaigns[campaignId].totalRewards += amount;
		_mint(msg.sender, amount); // Mint tokens to the creator's address

		emit CampaignFunded(campaignId, amount);
	}

	// Distribute rewards to users based on campaign criteria
	function distributeRewards(uint256 campaignId, address user, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(campaigns[campaignId].creator != address(0), "Invalid campaign ID");
		require(amount <= campaigns[campaignId].totalRewards, "Insufficient rewards in campaign");
		campaigns[campaignId].userRewards[user] += amount; // Add rewards to the user's balance
		campaigns[campaignId].totalRewards -= amount; // Subtract rewards from the campaign's total rewards

		emit RewardsDistributed(campaignId, user, amount);
	}

	// Add rewards to a user's balance (for simplicity, 1 reward = 1 ERC20 token)
	function addUserReward(uint256 campaignId, address user, uint256 reward) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(campaigns[campaignId].creator != address(0), "Invalid campaign ID");

		// Mint tokens to user's address
		_mint(user, reward);
		campaigns[campaignId].userRewards[user] += reward;
	}

	// Allow users to redeem their rewards
	function redeemRewards(uint256 campaignId, uint256 amount) external onlyRole(BURNER_ROLE) {
		require(campaigns[campaignId].creator != address(0), "Invalid campaign ID");

		require(balanceOf(msg.sender) >= amount, "Insufficient token balance");

		// Burn the token to redeem the rewards
		_burn(msg.sender, amount);

		emit RewardsRedeemed(campaignId, msg.sender, amount);
	}

// Additional functions for campaign management and user interaction can be added later
}
