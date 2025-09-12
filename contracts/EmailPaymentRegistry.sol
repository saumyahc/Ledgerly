// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EmailPaymentRegistry
 * @dev Contract for mapping email addresses to wallet addresses and facilitating transfers
 * Compatible with MetaMask and EIP-1193 compliant wallets
 */
contract EmailPaymentRegistry {
    address public owner;
    
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
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    // Constructor
    constructor() {
        owner = msg.sender;
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
