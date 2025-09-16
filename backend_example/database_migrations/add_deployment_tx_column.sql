-- Migration to add deployment_tx column to existing smart_contracts table
-- Run this SQL on your hosted database

ALTER TABLE smart_contracts 
ADD COLUMN deployment_tx VARCHAR(66) NULL COMMENT 'Transaction hash of deployment (0x...)' 
AFTER abi;

-- Update the table comment to reflect the new column
ALTER TABLE smart_contracts 
COMMENT = 'Stores deployed smart contract information with versioning, activation management, and deployment transaction tracking';