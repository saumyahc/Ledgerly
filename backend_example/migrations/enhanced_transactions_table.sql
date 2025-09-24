-- Enhanced transactions table for Ledgerly
-- This table supports all types of blockchain transactions including betting

-- Drop existing transactions table if it exists (WARNING: This will delete data!)
DROP TABLE IF EXISTS transactions;

-- Main transactions table
CREATE TABLE transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    
    -- User and Wallet Information
    user_id INT NOT NULL,
    wallet_address VARCHAR(42) NOT NULL,
    
    -- Transaction Details
    transaction_hash VARCHAR(66) UNIQUE NOT NULL,
    block_number BIGINT NULL,
    block_hash VARCHAR(66) NULL,
    transaction_index INT NULL,
    
    -- Transaction Type and Direction
    transaction_type ENUM(
        'send', 'receive', 'contract_deploy', 'contract_call', 
        'faucet', 'betting', 'swap', 'stake', 'unstake'
    ) NOT NULL,
    direction ENUM('incoming', 'outgoing', 'internal') NOT NULL,
    
    -- Addresses
    from_address VARCHAR(42) NOT NULL,
    to_address VARCHAR(42) NOT NULL,
    
    -- Amount and Currency
    amount DECIMAL(30, 18) NOT NULL DEFAULT 0, -- Support up to 18 decimals for ETH
    currency_symbol VARCHAR(10) DEFAULT 'ETH',
    gas_used BIGINT NULL,
    gas_price BIGINT NULL, -- in wei
    gas_cost DECIMAL(30, 18) NULL, -- calculated gas cost in ETH
    
    -- Transaction Status
    status ENUM('pending', 'confirmed', 'failed', 'dropped') DEFAULT 'pending',
    confirmations INT DEFAULT 0,
    
    -- Additional Data
    input_data TEXT NULL, -- contract call data
    logs TEXT NULL, -- transaction logs as JSON
    error_message TEXT NULL,
    
    -- Metadata
    memo TEXT NULL,
    internal_notes TEXT NULL,
    
    -- Contract Information (for betting and other smart contracts)
    contract_address VARCHAR(42) NULL,
    contract_method VARCHAR(100) NULL,
    
    -- Betting specific fields
    bet_id VARCHAR(100) NULL,
    bet_type ENUM('create', 'join', 'resolve', 'claim') NULL,
    
    -- Timestamps
    blockchain_timestamp TIMESTAMP NULL, -- when transaction was mined
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign Key
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    
    -- Indexes for performance
    INDEX idx_user_id (user_id),
    INDEX idx_wallet_address (wallet_address),
    INDEX idx_transaction_hash (transaction_hash),
    INDEX idx_from_address (from_address),
    INDEX idx_to_address (to_address),
    INDEX idx_transaction_type (transaction_type),
    INDEX idx_status (status),
    INDEX idx_block_number (block_number),
    INDEX idx_created_at (created_at),
    INDEX idx_bet_id (bet_id),
    INDEX idx_contract_address (contract_address),
    INDEX idx_direction_type (direction, transaction_type)
);

-- Transaction summaries table for quick balance calculations
CREATE TABLE transaction_summaries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    wallet_address VARCHAR(42) NOT NULL,
    
    -- Daily aggregations
    summary_date DATE NOT NULL,
    
    -- Transaction counts
    total_transactions INT DEFAULT 0,
    incoming_count INT DEFAULT 0,
    outgoing_count INT DEFAULT 0,
    
    -- Amount summaries (in ETH)
    total_incoming DECIMAL(30, 18) DEFAULT 0,
    total_outgoing DECIMAL(30, 18) DEFAULT 0,
    total_gas_fees DECIMAL(30, 18) DEFAULT 0,
    net_amount DECIMAL(30, 18) DEFAULT 0, -- incoming - outgoing - gas_fees
    
    -- Transaction type counts
    send_count INT DEFAULT 0,
    receive_count INT DEFAULT 0,
    faucet_count INT DEFAULT 0,
    betting_count INT DEFAULT 0,
    contract_count INT DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    
    INDEX idx_user_date (user_id, summary_date),
    INDEX idx_wallet_date (wallet_address, summary_date),
    INDEX idx_summary_date (summary_date),
    
    UNIQUE KEY unique_user_date (user_id, summary_date)
);

-- Create views for common queries

-- View for user transaction history
CREATE OR REPLACE VIEW user_transaction_history AS
SELECT 
    t.id,
    t.user_id,
    u.name as user_name,
    u.email as user_email,
    t.wallet_address,
    t.transaction_hash,
    t.transaction_type,
    t.direction,
    t.from_address,
    t.to_address,
    t.amount,
    t.currency_symbol,
    t.gas_cost,
    t.status,
    t.confirmations,
    t.memo,
    t.bet_id,
    t.blockchain_timestamp,
    t.created_at,
    CASE 
        WHEN t.direction = 'incoming' THEN CONCAT('+', t.amount, ' ', t.currency_symbol)
        WHEN t.direction = 'outgoing' THEN CONCAT('-', t.amount, ' ', t.currency_symbol)
        ELSE CONCAT('=', t.amount, ' ', t.currency_symbol)
    END as formatted_amount
FROM transactions t
JOIN users u ON t.user_id = u.id
ORDER BY t.created_at DESC;

-- View for pending transactions
CREATE OR REPLACE VIEW pending_transactions AS
SELECT 
    t.*,
    u.name as user_name,
    u.email as user_email
FROM transactions t
JOIN users u ON t.user_id = u.id
WHERE t.status = 'pending'
ORDER BY t.created_at ASC;

-- View for daily transaction summaries
CREATE OR REPLACE VIEW daily_transaction_stats AS
SELECT 
    ts.*,
    u.name as user_name,
    u.email as user_email
FROM transaction_summaries ts
JOIN users u ON ts.user_id = u.id
ORDER BY ts.summary_date DESC, ts.user_id;

-- Stored procedure to update transaction summaries
DELIMITER //
CREATE PROCEDURE UpdateTransactionSummary(IN target_user_id INT, IN target_date DATE)
BEGIN
    INSERT INTO transaction_summaries (
        user_id, wallet_address, summary_date,
        total_transactions, incoming_count, outgoing_count,
        total_incoming, total_outgoing, total_gas_fees, net_amount,
        send_count, receive_count, faucet_count, betting_count, contract_count
    )
    SELECT 
        user_id,
        wallet_address,
        target_date,
        COUNT(*) as total_transactions,
        SUM(CASE WHEN direction = 'incoming' THEN 1 ELSE 0 END) as incoming_count,
        SUM(CASE WHEN direction = 'outgoing' THEN 1 ELSE 0 END) as outgoing_count,
        SUM(CASE WHEN direction = 'incoming' THEN amount ELSE 0 END) as total_incoming,
        SUM(CASE WHEN direction = 'outgoing' THEN amount ELSE 0 END) as total_outgoing,
        SUM(COALESCE(gas_cost, 0)) as total_gas_fees,
        SUM(CASE WHEN direction = 'incoming' THEN amount ELSE -amount END) - SUM(COALESCE(gas_cost, 0)) as net_amount,
        SUM(CASE WHEN transaction_type = 'send' THEN 1 ELSE 0 END) as send_count,
        SUM(CASE WHEN transaction_type = 'receive' THEN 1 ELSE 0 END) as receive_count,
        SUM(CASE WHEN transaction_type = 'faucet' THEN 1 ELSE 0 END) as faucet_count,
        SUM(CASE WHEN transaction_type = 'betting' THEN 1 ELSE 0 END) as betting_count,
        SUM(CASE WHEN transaction_type IN ('contract_deploy', 'contract_call') THEN 1 ELSE 0 END) as contract_count
    FROM transactions 
    WHERE user_id = target_user_id 
    AND DATE(created_at) = target_date
    AND status = 'confirmed'
    GROUP BY user_id, wallet_address
    ON DUPLICATE KEY UPDATE
        total_transactions = VALUES(total_transactions),
        incoming_count = VALUES(incoming_count),
        outgoing_count = VALUES(outgoing_count),
        total_incoming = VALUES(total_incoming),
        total_outgoing = VALUES(total_outgoing),
        total_gas_fees = VALUES(total_gas_fees),
        net_amount = VALUES(net_amount),
        send_count = VALUES(send_count),
        receive_count = VALUES(receive_count),
        faucet_count = VALUES(faucet_count),
        betting_count = VALUES(betting_count),
        contract_count = VALUES(contract_count),
        updated_at = CURRENT_TIMESTAMP;
END //
DELIMITER ;

-- Trigger to automatically update summaries when transactions are confirmed
DELIMITER //
CREATE TRIGGER update_summary_on_confirm
    AFTER UPDATE ON transactions
    FOR EACH ROW
BEGIN
    IF NEW.status = 'confirmed' AND OLD.status != 'confirmed' THEN
        CALL UpdateTransactionSummary(NEW.user_id, DATE(NEW.created_at));
    END IF;
END //
DELIMITER ;