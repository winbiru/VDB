-- Ví dụ VDB: quản lý sản phẩm.
CREATE DATABASE kho;
USE kho;
CREATE TABLE san_pham (
    id INT PRIMARY KEY,
    ten VARCHAR(100) NOT NULL,
    gia REAL NOT NULL,
    con_hang BOOLEAN,
    ghi_chu TEXT
);
INSERT INTO san_pham VALUES
    (1, 'Cà phê Buôn Ma Thuột', 120000, TRUE, NULL),
    (2, 'Trà Thái Nguyên', 85000, TRUE, 'Hộp 250g'),
    (3, 'Ca cao', 55000, FALSE, NULL);
SELECT id, ten, gia FROM san_pham WHERE gia >= 60000 ORDER BY gia DESC;
BEGIN;
UPDATE san_pham SET gia = 90000 WHERE id = 2;
ROLLBACK;
SELECT COUNT(*) FROM san_pham WHERE con_hang = TRUE;
SELECT * FROM san_pham ORDER BY id;
