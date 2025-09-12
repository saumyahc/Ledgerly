-- Create smart_contracts table for storing deployed contract details
CREATE TABLE IF NOT EXISTS smart_contracts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    contract_name VARCHAR(100) NOT NULL,
    contract_address VARCHAR(42) NOT NULL,
    chain_id INT NOT NULL,
    abi TEXT NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    UNIQUE KEY unique_contract (contract_name, chain_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
