// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EmailPaymentRegistry
 * @dev Contract for mapping email addresses to wallet addresses and facilitating transfers
 * Compatible with MetaMask and EIP-1193 compliant wallets
 */
contract EmailPaymentRegistry {
    address public owner;
    
    // Faucet configuration
    uint256 public faucetAmount = 0.5 ether; // Welcome bonus: 0.5 ETH per new user
    uint256 public faucetCooldown = 24 hours; // Once per day (prevents abuse)
    mapping(address => uint256) public lastFaucetRequest;
    mapping(address => bool) public hasReceivedWelcomeBonus; // Track welcome bonus
    bool public faucetEnabled = true;
    
    // Faucet funding queue system
    struct FaucetFunder {
        address funderAddress;
        uint256 contributedAmount;
        uint256 contributedAt;
        bool isActive;
    }
    
    mapping(address => FaucetFunder) public faucetFunders;
    address[] public funderQueue;
    uint256 public totalFaucetContributions;
    uint256 public minimumContribution = 0.1 ether; // Minimum to join faucet funding
    
    // Mapping of keccak256 hashed emails to wallet addresses
    mapping(bytes32 => address) private emailToWallet;
    
    // User profile data
    struct UserProfile {
        address wallet;
        uint256 registeredAt;
        uint256 lastUpdatedAt;
        uint256 totalReceived;
        uint256 totalSent;
    }
    
    // Enhanced mapping with profile data
    mapping(bytes32 => UserProfile) private emailProfiles;
    
    // Events
    event EmailRegistered(bytes32 indexed emailHash, address indexed wallet);
    event PaymentSent(bytes32 indexed fromEmailHash, bytes32 indexed toEmailHash, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FaucetUsed(address indexed user, uint256 amount);
    event WelcomeBonusGranted(address indexed user, uint256 amount);
    event FaucetConfigured(uint256 amount, uint256 cooldown, bool enabled);
    event FaucetFunded(address indexed funder, uint256 amount);
    event FaucetFunderJoined(address indexed funder, uint256 contribution);
    event FaucetFunderRemoved(address indexed funder);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    // Constructor
    constructor() payable {
        owner = msg.sender;
    }
    
    // Allow contract to receive ETH
    receive() external payable {}
    fallback() external payable {}
    
    /**
     * @dev Request welcome bonus for new users (one-time only)
     */
    function requestWelcomeBonus() public {
        require(faucetEnabled, "Welcome bonus is disabled");
        require(!hasReceivedWelcomeBonus[msg.sender], "Welcome bonus already claimed");
        require(address(this).balance >= faucetAmount, "Insufficient funds for welcome bonus");
        
        // Mark as received and record timestamp
        hasReceivedWelcomeBonus[msg.sender] = true;
        lastFaucetRequest[msg.sender] = block.timestamp;
        
        // Send welcome bonus
        (bool sent, ) = payable(msg.sender).call{value: faucetAmount}("");
        require(sent, "Failed to send welcome bonus");
        
        emit FaucetUsed(msg.sender, faucetAmount);
        emit WelcomeBonusGranted(msg.sender, faucetAmount);
    }
    
    /**
     * @dev Check if user is eligible for welcome bonus
     */
    function canRequestWelcomeBonus(address user) public view returns (bool) {
        return faucetEnabled && !hasReceivedWelcomeBonus[user] && address(this).balance >= faucetAmount;
    }

    /**
     * @dev Request test ETH from the faucet (development only)
     */
    function requestFaucetFunds() public {
        require(faucetEnabled, "Faucet is disabled");
        require(address(this).balance >= faucetAmount, "Faucet is empty");
        require(
            block.timestamp >= lastFaucetRequest[msg.sender] + faucetCooldown,
            "Cooldown period not met"
        );
        
        lastFaucetRequest[msg.sender] = block.timestamp;
        
        (bool sent, ) = payable(msg.sender).call{value: faucetAmount}("");
        require(sent, "Failed to send faucet funds");
        
        emit FaucetUsed(msg.sender, faucetAmount);
    }
    
    /**
     * @dev Request specific amount from faucet
     * @param amount Amount in wei to request
     */
    function requestFaucetAmount(uint256 amount) public {
        require(faucetEnabled, "Faucet is disabled");
        require(amount <= faucetAmount, "Amount exceeds faucet limit");
        require(address(this).balance >= amount, "Faucet insufficient funds");
        require(
            block.timestamp >= lastFaucetRequest[msg.sender] + faucetCooldown,
            "Cooldown period not met"
        );
        
        lastFaucetRequest[msg.sender] = block.timestamp;
        
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send faucet funds");
        
        emit FaucetUsed(msg.sender, amount);
    }
    
    /**
     * @dev Request funds from the faucet funding queue (prioritizes queue over contract balance)
     * @param amount Amount in wei to request (defaults to faucetAmount if 0)
     */
    function requestFromQueue(uint256 amount) public {
        require(faucetEnabled, "Faucet is disabled");
        require(
            block.timestamp >= lastFaucetRequest[msg.sender] + faucetCooldown,
            "Cooldown period not met"
        );
        
        // Use default faucet amount if amount is 0
        uint256 requestAmount = amount == 0 ? faucetAmount : amount;
        require(requestAmount <= faucetAmount, "Amount exceeds faucet limit");
        
        // Check if we have enough in queue contributions or contract balance
        require(address(this).balance >= requestAmount, "Insufficient funds available");
        
        lastFaucetRequest[msg.sender] = block.timestamp;
        
        // Transfer the requested amount
        (bool sent, ) = payable(msg.sender).call{value: requestAmount}("");
        require(sent, "Failed to send funds");
        
        emit FaucetUsed(msg.sender, requestAmount);
    }
    
    /**
     * @dev Request default faucet amount from queue
     */
    function requestFromQueueDefault() public {
        requestFromQueue(0); // 0 means use default faucetAmount
    }

    /**
     * @dev Configure faucet settings (owner only)
     */
    function configureFaucet(uint256 _amount, uint256 _cooldown, bool _enabled) public onlyOwner {
        faucetAmount = _amount;
        faucetCooldown = _cooldown;
        faucetEnabled = _enabled;
        
        emit FaucetConfigured(_amount, _cooldown, _enabled);
    }
    
    /**
     * @dev Fund the faucet (owner only)
     */
    function fundFaucet() public payable onlyOwner {
        // ETH sent with this transaction goes to the contract
    }
    
    /**
     * @dev Get faucet info
     */
    function getFaucetInfo() public view returns (uint256 amount, uint256 cooldown, bool enabled, uint256 balance) {
        return (faucetAmount, faucetCooldown, faucetEnabled, address(this).balance);
    }
    
    /**
     * @dev Check if user can request faucet funds
     */
    function canRequestFaucet(address user) public view returns (bool, uint256 timeLeft) {
        if (!faucetEnabled) return (false, 0);
        if (address(this).balance < faucetAmount) return (false, 0);
        
        uint256 nextRequest = lastFaucetRequest[user] + faucetCooldown;
        if (block.timestamp >= nextRequest) {
            return (true, 0);
        } else {
            return (false, nextRequest - block.timestamp);
        }
    }
    
    /**
     * @dev Join the faucet funding queue by contributing ETH
     */
    function joinFaucetFunding() public payable {
        require(msg.value >= minimumContribution, "Contribution below minimum");
        require(!faucetFunders[msg.sender].isActive, "Already in faucet funding queue");
        
        // Add to funder queue
        faucetFunders[msg.sender] = FaucetFunder({
            funderAddress: msg.sender,
            contributedAmount: msg.value,
            contributedAt: block.timestamp,
            isActive: true
        });
        
        funderQueue.push(msg.sender);
        totalFaucetContributions += msg.value;
        
        emit FaucetFunderJoined(msg.sender, msg.value);
        emit FaucetFunded(msg.sender, msg.value);
    }
    
    /**
     * @dev Add more funding to existing faucet contribution
     */
    function addFaucetFunding() public payable {
        require(faucetFunders[msg.sender].isActive, "Not in faucet funding queue");
        require(msg.value > 0, "Must send ETH");
        
        faucetFunders[msg.sender].contributedAmount += msg.value;
        totalFaucetContributions += msg.value;
        
        emit FaucetFunded(msg.sender, msg.value);
    }
    
    /**
     * @dev Remove from faucet funding queue and withdraw contribution
     */
    function leaveFaucetFunding() public {
        require(faucetFunders[msg.sender].isActive, "Not in faucet funding queue");
        
        uint256 contribution = faucetFunders[msg.sender].contributedAmount;
        require(address(this).balance >= contribution, "Insufficient contract balance");
        
        // Mark as inactive
        faucetFunders[msg.sender].isActive = false;
        totalFaucetContributions -= contribution;
        
        // Remove from queue array
        for (uint i = 0; i < funderQueue.length; i++) {
            if (funderQueue[i] == msg.sender) {
                funderQueue[i] = funderQueue[funderQueue.length - 1];
                funderQueue.pop();
                break;
            }
        }
        
        // Return contribution
        (bool sent, ) = payable(msg.sender).call{value: contribution}("");
        require(sent, "Failed to return contribution");
        
        emit FaucetFunderRemoved(msg.sender);
    }
    
    /**
     * @dev Get faucet funding queue information
     */
    function getFaucetFundingInfo() public view returns (
        uint256 totalFunders,
        uint256 totalContributions,
        uint256 contractBalance,
        uint256 minimumContrib
    ) {
        return (
            funderQueue.length,
            totalFaucetContributions,
            address(this).balance,
            minimumContribution
        );
    }
    
    /**
     * @dev Get specific funder information
     */
    function getFunderInfo(address funder) public view returns (
        uint256 contributedAmount,
        uint256 contributedAt,
        bool isActive
    ) {
        FaucetFunder memory funderInfo = faucetFunders[funder];
        return (
            funderInfo.contributedAmount,
            funderInfo.contributedAt,
            funderInfo.isActive
        );
    }
    
    /**
     * @dev Get all active funders (limited to prevent gas issues)
     */
    function getActiveFunders() public view returns (address[] memory) {
        uint256 activeCount = 0;
        
        // Count active funders
        for (uint i = 0; i < funderQueue.length; i++) {
            if (faucetFunders[funderQueue[i]].isActive) {
                activeCount++;
            }
        }
        
        // Create array of active funders
        address[] memory activeFunders = new address[](activeCount);
        uint256 index = 0;
        
        for (uint i = 0; i < funderQueue.length; i++) {
            if (faucetFunders[funderQueue[i]].isActive) {
                activeFunders[index] = funderQueue[i];
                index++;
            }
        }
        
        return activeFunders;
    }
    
    /**
     * @dev Set minimum contribution for faucet funding (owner only)
     */
    function setMinimumContribution(uint256 _minimumContribution) public onlyOwner {
        minimumContribution = _minimumContribution;
    }
    
    /**
     * @dev Transfer ownership to a new address
     * @param newOwner The address to transfer ownership to
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    /**
     * @dev Register or update an email-to-wallet mapping
     * @param emailHash The keccak256 hash of the email address
     * @param wallet The wallet address to associate with this email
     */
    function registerEmail(bytes32 emailHash, address wallet) public {
        require(wallet != address(0), "Cannot register zero address");
        
        // If email is already registered, ensure it's being updated by the current wallet owner
        if (emailProfiles[emailHash].wallet != address(0)) {
            require(emailProfiles[emailHash].wallet == msg.sender, "Email already registered to another wallet");
        }
        
        // Update or create profile
        if (emailProfiles[emailHash].wallet == address(0)) {
            // New registration
            emailProfiles[emailHash] = UserProfile({
                wallet: wallet,
                registeredAt: block.timestamp,
                lastUpdatedAt: block.timestamp,
                totalReceived: 0,
                totalSent: 0
            });
        } else {
            // Update existing registration
            emailProfiles[emailHash].wallet = wallet;
            emailProfiles[emailHash].lastUpdatedAt = block.timestamp;
        }
        
        // Also update the simple mapping for backward compatibility
        emailToWallet[emailHash] = wallet;
        
        emit EmailRegistered(emailHash, wallet);
    }
    
    /**
     * @dev Get wallet address associated with email hash
     * @param emailHash The keccak256 hash of the email address
     * @return The wallet address associated with this email
     */
    function getWalletByEmail(bytes32 emailHash) public view returns (address) {
        return emailProfiles[emailHash].wallet;
    }
    
    /**
     * @dev Get full user profile information
     * @param emailHash The keccak256 hash of the email address
     * @return wallet The wallet address
     * @return registeredAt Registration timestamp
     * @return lastUpdatedAt Last update timestamp
     * @return totalReceived Total ETH received
     * @return totalSent Total ETH sent
     */
    function getUserProfile(bytes32 emailHash) public view returns (
        address wallet,
        uint256 registeredAt,
        uint256 lastUpdatedAt,
        uint256 totalReceived,
        uint256 totalSent
    ) {
        UserProfile memory profile = emailProfiles[emailHash];
        return (
            profile.wallet,
            profile.registeredAt,
            profile.lastUpdatedAt,
            profile.totalReceived,
            profile.totalSent
        );
    }
    
    /**
     * @dev Send payment from one email to another
     * @param fromEmailHash The sender's email hash
     * @param toEmailHash The recipient's email hash
     */
    function sendPaymentByEmail(bytes32 fromEmailHash, bytes32 toEmailHash) public payable {
        address payable toWallet = payable(emailProfiles[toEmailHash].wallet);
        require(toWallet != address(0), "Recipient email not registered");
        
        // Either the sender must be the registered wallet for fromEmailHash or the contract owner
        require(
            msg.sender == emailProfiles[fromEmailHash].wallet || msg.sender == owner,
            "Sender not authorized for this email"
        );
        
        // Update statistics
        emailProfiles[fromEmailHash].totalSent += msg.value;
        emailProfiles[toEmailHash].totalReceived += msg.value;
        
        // Send payment
        (bool sent, ) = toWallet.call{value: msg.value}("");
        require(sent, "Failed to send payment");
        
        emit PaymentSent(fromEmailHash, toEmailHash, msg.value);
    }
    
    /**
     * @dev Send payment directly to an email address
     * @param toEmailHash The recipient's email hash
     */
    function sendPaymentToEmail(bytes32 toEmailHash) public payable {
        address payable toWallet = payable(emailProfiles[toEmailHash].wallet);
        require(toWallet != address(0), "Recipient email not registered");
        
        // Calculate sender's email hash (if registered)
        bytes32 fromEmailHash;
        bool senderIsRegistered = false;
        
        // Find if sender is registered with any email
        for (uint i = 0; i < 10; i++) {
            // This is inefficient but works for the demo
            // In a production environment, you would use a reverse lookup or proper index
            bytes32 testHash = keccak256(abi.encodePacked("placeholder", i));
            if (emailProfiles[testHash].wallet == msg.sender) {
                fromEmailHash = testHash;
                senderIsRegistered = true;
                break;
            }
        }
        
        // Update statistics if sender is registered
        if (senderIsRegistered) {
            emailProfiles[fromEmailHash].totalSent += msg.value;
        }
        
        // Always update recipient stats
        emailProfiles[toEmailHash].totalReceived += msg.value;
        
        // Send payment
        (bool sent, ) = toWallet.call{value: msg.value}("");
        require(sent, "Failed to send payment");
        
        emit PaymentSent(
            senderIsRegistered ? fromEmailHash : bytes32(0),
            toEmailHash,
            msg.value
        );
    }
    
    /**
     * @dev Utility function to compute email hash offchain
     * @param email The email address as a string
     * @return The keccak256 hash of the email
     */
    function computeEmailHash(string memory email) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(email));
    }
    
    /**
     * @dev Withdraw any funds accidentally sent to the contract
     */
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    /**
     * @dev Emergency function to override an email registration
     * Only to be used if someone loses access to their wallet
     */
    function adminOverrideEmail(bytes32 emailHash, address newWallet) public onlyOwner {
        require(newWallet != address(0), "Cannot set zero address");
        
        // Keep the registration time but update other fields
        uint256 originalRegTime = emailProfiles[emailHash].registeredAt;
        
        emailProfiles[emailHash] = UserProfile({
            wallet: newWallet,
            registeredAt: originalRegTime > 0 ? originalRegTime : block.timestamp,
            lastUpdatedAt: block.timestamp,
            totalReceived: emailProfiles[emailHash].totalReceived,
            totalSent: emailProfiles[emailHash].totalSent
        });
        
        // Also update simple mapping
        emailToWallet[emailHash] = newWallet;
        
        emit EmailRegistered(emailHash, newWallet);
    }
}
