CREATE TABLE IF NOT EXISTS skapdevzstash (
    id INT AUTO_INCREMENT PRIMARY KEY,
    citizenid VARCHAR(50),
    item_name VARCHAR(100),
    amount INT,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS skapdevzstash_pins (
    stash_key VARCHAR(100) PRIMARY KEY,
    pin VARCHAR(10)
);
