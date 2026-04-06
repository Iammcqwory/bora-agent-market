// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BoraMarketplace} from "./BoraMarketplace.sol";

/**
 * @title BoraDispute
 * @notice 3-tier arbitration system for fraud claims
 * @dev Tier 1: AI auto-resolve, Tier 2: Community jury, Tier 3: Bora Council
 */
contract BoraDispute is Ownable {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 private constant AI_RESOLUTION_WINDOW = 24 hours;
    uint256 private constant JURY_RESOLUTION_WINDOW = 72 hours;
    uint256 private constant JURY_SIZE = 5;
    uint256 private constant MIN_REPUTATION_JUROR = 70;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    BoraMarketplace public immutable marketplace;
    address public oracleAddress;  // Chainlink Functions or similar
    
    enum DisputeTier {
        AI,
        JURY,
        COUNCIL
    }

    enum DisputeStatus {
        OPEN,
        RESOLVED_BUYER,
        RESOLVED_VALIDATOR
    }

    struct Dispute {
        uint256 listingId;
        address buyer;
        string evidenceHash;      // IPFS hash of buyer's evidence
        DisputeTier tier;
        DisputeStatus status;
        uint256 createdAt;
        bool aiVerdict;           // true = buyer wins
        address[] jurors;
        mapping(address => bool) juryVotes;  // true = buyer wins
        uint256 buyerVoteCount;
        uint256 validatorVoteCount;
    }

    mapping(uint256 => Dispute) public disputes;  // listingId => Dispute
    mapping(address => uint256) public validatorReputation;  // For jury selection
    mapping(address => bool) public councilMembers;
    
    uint256 public disputeCounter;
    bool public paused;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event DisputeCreated(
        uint256 indexed listingId,
        address indexed buyer,
        DisputeTier tier,
        string evidenceHash
    );

    event AIVerdictSubmitted(
        uint256 indexed listingId,
        bool buyerWins
    );

    event JurorAssigned(
        uint256 indexed listingId,
        address indexed juror
    );

    event JuryVoteCast(
        uint256 indexed listingId,
        address indexed juror,
        bool buyerWins
    );

    event DisputeResolved(
        uint256 indexed listingId,
        DisputeStatus outcome,
        DisputeTier tier
    );

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error Paused();
    error Unauthorized();
    error DisputeNotFound();
    error DisputeAlreadyResolved();
    error TierNotReady();
    error AlreadyVoted();
    error InsufficientReputation();

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _marketplace) Ownable(msg.sender) {
        marketplace = BoraMarketplace(_marketplace);
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) revert Unauthorized();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                         DISPUTE CREATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Create a dispute for a purchased item
     * @param listingId The listing being disputed
     * @param evidenceHash IPFS hash of buyer's evidence
     */
    function createDispute(uint256 listingId, string calldata evidenceHash) 
        external 
        whenNotPaused 
    {
        // Verify listing exists and is purchased
        BoraMarketplace.Listing memory listing = marketplace.getListing(listingId);
        if (listing.buyer != msg.sender) revert Unauthorized();

        // Determine tier based on item value
        DisputeTier tier = _determineTier(listing.price);

        // Create dispute
        Dispute storage dispute = disputes[listingId];
        dispute.listingId = listingId;
        dispute.buyer = msg.sender;
        dispute.evidenceHash = evidenceHash;
        dispute.tier = tier;
        dispute.status = DisputeStatus.OPEN;
        dispute.createdAt = block.timestamp;

        disputeCounter++;

        // For AI tier, request oracle verdict
        if (tier == DisputeTier.AI) {
            // In production: Call Chainlink Functions here
            // For now: Manual oracle submission
        }

        // For JURY tier, select jurors
        if (tier == DisputeTier.JURY) {
            _assignJurors(listingId);
        }

        emit DisputeCreated(listingId, msg.sender, tier, evidenceHash);
    }

    /**
     * @notice Determine dispute tier based on item price
     */
    function _determineTier(uint256 price) internal pure returns (DisputeTier) {
        if (price >= 1000e6) {  // $1,000+
            return DisputeTier.COUNCIL;
        } else if (price >= 100e6) {  // $100-$1,000
            return DisputeTier.JURY;
        } else {  // < $100
            return DisputeTier.AI;
        }
    }

    /*//////////////////////////////////////////////////////////////
                       TIER 1: AI RESOLUTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Submit AI verdict (called by oracle)
     * @param listingId The disputed listing
     * @param buyerWins true if buyer's claim is valid
     */
    function submitAIVerdict(uint256 listingId, bool buyerWins) 
        external 
        onlyOracle 
    {
        Dispute storage dispute = disputes[listingId];
        if (dispute.tier != DisputeTier.AI) revert TierNotReady();
        if (dispute.status != DisputeStatus.OPEN) revert DisputeAlreadyResolved();

        dispute.aiVerdict = buyerWins;
        
        _resolveDispute(listingId, buyerWins);

        emit AIVerdictSubmitted(listingId, buyerWins);
    }

    /*//////////////////////////////////////////////////////////////
                      TIER 2: JURY RESOLUTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Assign jurors to a dispute (high-reputation validators)
     */
    function _assignJurors(uint256 listingId) internal {
        Dispute storage dispute = disputes[listingId];
        
        // In production: Select 5 validators with reputation > 70
        // For now: Manual assignment by calling assignJuror externally
    }

    /**
     * @notice Manually assign a juror (owner function for MVP)
     */
    function assignJuror(uint256 listingId, address juror) external onlyOwner {
        Dispute storage dispute = disputes[listingId];
        if (dispute.tier != DisputeTier.JURY) revert TierNotReady();
        if (validatorReputation[juror] < MIN_REPUTATION_JUROR) {
            revert InsufficientReputation();
        }

        dispute.jurors.push(juror);
        emit JurorAssigned(listingId, juror);
    }

    /**
     * @notice Cast jury vote
     * @param listingId The disputed listing
     * @param buyerWins true if voting for buyer
     */
    function castJuryVote(uint256 listingId, bool buyerWins) external {
        Dispute storage dispute = disputes[listingId];
        if (dispute.tier != DisputeTier.JURY) revert TierNotReady();
        if (dispute.status != DisputeStatus.OPEN) revert DisputeAlreadyResolved();
        if (dispute.juryVotes[msg.sender]) revert AlreadyVoted();

        // Verify caller is assigned juror
        bool isJuror = false;
        for (uint256 i = 0; i < dispute.jurors.length; i++) {
            if (dispute.jurors[i] == msg.sender) {
                isJuror = true;
                break;
            }
        }
        if (!isJuror) revert Unauthorized();

        // Record vote
        dispute.juryVotes[msg.sender] = true;
        if (buyerWins) {
            dispute.buyerVoteCount++;
        } else {
            dispute.validatorVoteCount++;
        }

        emit JuryVoteCast(listingId, msg.sender, buyerWins);

        // If all jurors voted, resolve
        if (dispute.buyerVoteCount + dispute.validatorVoteCount == JURY_SIZE) {
            bool outcome = dispute.buyerVoteCount >= 3;  // Majority
            _resolveDispute(listingId, outcome);
        }
    }

    /*//////////////////////////////////////////////////////////////
                     TIER 3: COUNCIL RESOLUTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Resolve dispute via Bora Council decision
     * @param listingId The disputed listing
     * @param buyerWins Council's verdict
     */
    function resolveViaCouncil(uint256 listingId, bool buyerWins) 
        external 
    {
        if (!councilMembers[msg.sender]) revert Unauthorized();

        Dispute storage dispute = disputes[listingId];
        if (dispute.tier != DisputeTier.COUNCIL) revert TierNotReady();
        if (dispute.status != DisputeStatus.OPEN) revert DisputeAlreadyResolved();

        _resolveDispute(listingId, buyerWins);
    }

    /*//////////////////////////////////////////////////////////////
                        RESOLUTION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Finalize dispute resolution
     */
    function _resolveDispute(uint256 listingId, bool buyerWins) internal {
        Dispute storage dispute = disputes[listingId];

        dispute.status = buyerWins 
            ? DisputeStatus.RESOLVED_BUYER 
            : DisputeStatus.RESOLVED_VALIDATOR;

        // Trigger marketplace resolution
        if (buyerWins) {
            marketplace.resolveDisputeBuyerWins(listingId);
        } else {
            marketplace.resolveDisputeValidatorWins(listingId);
        }

        emit DisputeResolved(listingId, dispute.status, dispute.tier);
    }

    /*//////////////////////////////////////////////////////////////
                     REPUTATION MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Update validator reputation (called by marketplace)
     */
    function updateReputation(address validator, int256 change) external {
        if (msg.sender != address(marketplace)) revert Unauthorized();

        if (change > 0) {
            validatorReputation[validator] += uint256(change);
        } else {
            uint256 decrease = uint256(-change);
            if (validatorReputation[validator] > decrease) {
                validatorReputation[validator] -= decrease;
            } else {
                validatorReputation[validator] = 0;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getDispute(uint256 listingId) external view returns (
        address buyer,
        string memory evidenceHash,
        DisputeTier tier,
        DisputeStatus status,
        uint256 createdAt,
        uint256 buyerVotes,
        uint256 validatorVotes
    ) {
        Dispute storage dispute = disputes[listingId];
        return (
            dispute.buyer,
            dispute.evidenceHash,
            dispute.tier,
            dispute.status,
            dispute.createdAt,
            dispute.buyerVoteCount,
            dispute.validatorVoteCount
        );
    }

    function getJurors(uint256 listingId) external view returns (address[] memory) {
        return disputes[listingId].jurors;
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setOracleAddress(address _oracle) external onlyOwner {
        oracleAddress = _oracle;
    }

    function addCouncilMember(address member) external onlyOwner {
        councilMembers[member] = true;
    }

    function removeCouncilMember(address member) external onlyOwner {
        councilMembers[member] = false;
    }

    function emergencyPause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }
}
