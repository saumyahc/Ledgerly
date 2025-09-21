-- Create smart_contracts table from scratch with all enhanced features

CREATE TABLE smart_contracts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    contract_name VARCHAR(100) NOT NULL,
    contract_address VARCHAR(42) NOT NULL,
    chain_id INT NOT NULL,
    abi TEXT NOT NULL,
    deployment_tx VARCHAR(66) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version VARCHAR(50) DEFAULT 'v1.0.0',
    network_mode VARCHAR(20) DEFAULT 'unknown',
    deployed_at TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    deactivated_at TIMESTAMP NULL
);

-- Create indexes for faster queries
CREATE INDEX idx_smart_contracts_active ON smart_contracts(is_active, chain_id, contract_name);
CREATE INDEX idx_smart_contracts_created ON smart_contracts(created_at DESC);
CREATE INDEX idx_active_contracts_lookup ON smart_contracts(contract_name, chain_id, is_active);

-- Add comments for documentation
ALTER TABLE smart_contracts 
COMMENT = 'Stores deployed smart contract information with versioning and activation management';

ALTER TABLE smart_contracts 
MODIFY COLUMN id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier',
MODIFY COLUMN contract_name VARCHAR(100) NOT NULL COMMENT 'Name of the contract (e.g., EmailPaymentRegistry)',
MODIFY COLUMN contract_address VARCHAR(42) NOT NULL COMMENT 'Deployed contract address (0x...)',
MODIFY COLUMN chain_id INT NOT NULL COMMENT 'Blockchain network ID (5777=local, 1=mainnet, 11155111=sepolia)',
MODIFY COLUMN abi TEXT NOT NULL COMMENT 'Contract ABI JSON',
MODIFY COLUMN deployment_tx VARCHAR(66) NULL COMMENT 'Transaction hash of deployment (0x...)',
MODIFY COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When record was created',
MODIFY COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'When record was last updated',
MODIFY COLUMN version VARCHAR(50) DEFAULT 'v1.0.0' COMMENT 'Contract version (e.g., v1.0.0)',
MODIFY COLUMN network_mode VARCHAR(20) DEFAULT 'unknown' COMMENT 'Network mode (local, testnet, mainnet)',
MODIFY COLUMN deployed_at TIMESTAMP NULL COMMENT 'When contract was deployed on blockchain',
MODIFY COLUMN is_active BOOLEAN DEFAULT TRUE COMMENT 'Whether this contract version is currently active',
MODIFY COLUMN deactivated_at TIMESTAMP NULL COMMENT 'When contract was deactivated (replaced by newer version)';
