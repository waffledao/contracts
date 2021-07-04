//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// ============ Imports ============

import "./Waffle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WaffleFactory {
  // ================ Constants ================
  uint256 private constant MIN_DURATION = 1 hours; // seems reasonable
  uint256 private constant MAX_DURATION = 100 days; // capping to protect against raffle's never expiring
  // ============ Immutable storage ============

  // Chainlink LINK token
  IERC20 public immutable LINKToken;
  // Chainlink oracle fee
  uint256 public immutable ChainlinkFee;
  // Chainlink network VRF key hash
  bytes32 public immutable ChainlinkKeyHash;
  // Chainlink LINK token address
  address public immutable ChainlinkLINKToken;
  // Chainlink VRF coordinator address
  address public immutable ChainlinkVRFCoordinator;

  // ============ Events ============

  event WaffleCreated(
    address indexed waffle,
    address indexed owner,
    address indexed nftContract,
    uint256 nftID,
    uint256 slotPrice,
    uint256 numSlotsAvailable,
    uint256 raffleExpiry
  );

  // ============ Constructor ============

  constructor(
    uint256 _ChainlinkFee,
    bytes32 _ChainlinkKeyHash,
    address _ChainlinkLinkToken,
    address _ChainlinkVRFCoordinator
  ) {
    ChainlinkFee = _ChainlinkFee;
    ChainlinkKeyHash = _ChainlinkKeyHash;
    LINKToken = IERC20(_ChainlinkLinkToken);
    ChainlinkLINKToken = _ChainlinkLinkToken;
    ChainlinkVRFCoordinator = _ChainlinkVRFCoordinator;
  }

  // ============ Functions ============
  function createWaffle(
    address _nftContract,
    uint256 _nftID,
    uint256 _slotPrice,
    uint256 _numSlotsAvailable,
    uint256 _raffleExpiry

  ) external {
    // Require slot price > 0
    require(_slotPrice > 0, "WaffleFactory: Price per slot must be above 0.");
    // Require number of available slots > 0
    require(_numSlotsAvailable > 0, "WaffleFactory: Number of available slots must be above 0.");
    // Check if WalletFactory is approved to spend msg.sender LINK
    require(LINKToken.allowance(msg.sender, address(this)) >= ChainlinkFee, "WalletFactory: Insufficient LINK allowance.");
    // Require LINK balance of creator >= Chainlink VRF fee
    require(LINKToken.balanceOf(msg.sender) >= ChainlinkFee, "WaffleFactory: Insufficient LINK.");

    require((_raffleExpiry - MIN_DURATION) >= block.timestamp, "WaffleFactory: Raffle duration must be greater than 1 hour");

    require((_raffleExpiry - block.timestamp) <= MAX_DURATION , "WaffleFactory: Raffle duration must be less than 100 days");

    Waffle raffle = new Waffle(
      msg.sender,
      _nftContract,
      ChainlinkVRFCoordinator,
      ChainlinkLINKToken,
      ChainlinkKeyHash,
      ChainlinkFee,
      _nftID,
      _slotPrice,
      _numSlotsAvailable,
      _raffleExpiry
    );

    // Transfer LINK fee to waffle contract
    LINKToken.transferFrom(msg.sender, address(raffle), ChainlinkFee);

    // Emit creation event
    emit WaffleCreated(address(raffle), msg.sender, _nftContract, _nftID, _slotPrice, _numSlotsAvailable, _raffleExpiry);
  }
}