-- Retrieve All Data from Tables
SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;

-- Insert a New Book Record
INSERT INTO books
VALUES ("978-1-60129-456-2", "The Psychology of Money", 'Finance', '6.00', 'yes', 'Morgan Housel', 'J.B.Lippincott & Co.');

-- Update Member Address
UPDATE members
SET member_address = '123 Pine St'
WHERE member_id = 'C121';

-- Delete a Record from issued_status
DELETE FROM issued_status
WHERE issued_id = "IS121";

-- Retrieve Issued Books by a Specific Employee
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';

-- Identify Members Who Have Issued More Than One Book
SELECT member_name, issued_member_id, COUNT(issued_id) AS 'Total_books'
FROM issued_status AS sta
JOIN members AS mem ON mem.member_id = sta.issued_member_id
GROUP BY 2
HAVING COUNT(issued_id) > 1
ORDER BY 3 DESC;

-- Create a Summary Table for Issued Books
CREATE TABLE book_counts AS
SELECT issued_book_isbn, issued_book_name, COUNT(issued_id) AS "no of books issued"
FROM issued_status
GROUP BY 1,2;

-- Retrieve Books by Category
SELECT * FROM books WHERE category = 'classic';

-- Calculate Total Rental Revenue per Category
SELECT category, SUM(rental_Price) AS 'Total Rental Revenue'
FROM book_counts bkc
JOIN books AS bk ON bkc.issued_book_isbn = bk.isbn
GROUP BY 1
ORDER BY 2 DESC;

-- Insert New Members and Query Recent Registrations
INSERT INTO members (member_id, member_name, member_address, reg_date)
VALUES (120, 'David Hill', '568 LOS Angelas, Metro', '2025-02-10'),
       (121, 'Emma Stone', '659 New Jersey, State', '2025-03-01');

SELECT member_id, member_name, member_address, reg_date
FROM members
WHERE reg_date >= CURDATE() - INTERVAL 180 DAY;

-- Create High-Priced Books Table
CREATE TABLE High_Price AS
SELECT * FROM books
WHERE rental_price > 7;

-- Identify Books Not Yet Returned
SELECT ist.* FROM return_status AS rst
RIGHT JOIN issued_status AS ist ON ist.issued_id = rst.issued_id
WHERE rst.return_id IS NULL;

-- Add Column for Book Quality in return_status
ALTER TABLE return_status
ADD COLUMN book_quality VARCHAR(15) DEFAULT 'Good';

-- Create a Stored Procedure for Book Returns
DELIMITER $$
CREATE PROCEDURE add_return_records(
    IN p_return_id VARCHAR(10),
    IN p_issued_id VARCHAR(10),
    IN p_book_quality VARCHAR(10)
)
BEGIN
    DECLARE v_isbn VARCHAR(50);
    DECLARE v_book_name VARCHAR(100);

    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES (p_return_id, p_issued_id, CURDATE(), p_book_quality);

    SELECT issued_book_isbn, issued_book_name
    INTO v_isbn, v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    SELECT CONCAT("Thank You for returning the book:", v_book_name) AS message;
END $$
DELIMITER ;

-- Generate Branch Revenue Report
SELECT br.branch_id, branch_address, COUNT(ist.issued_id) AS 'Total Issues', COUNT(return_id) AS 'Total Returns', SUM(rental_price) AS 'Total Revenue'
FROM employees emp
JOIN branch br ON br.branch_id = emp.branch_id
JOIN issued_status ist ON emp.emp_id = ist.issued_emp_id
LEFT JOIN return_status rst ON rst.issued_id = ist.issued_id
JOIN books bk ON ist.issued_book_isbn = bk.isbn
GROUP BY 1;

-- Identify Active Members (Issued a Book in Last 2 Months)
CREATE TABLE active_members AS
SELECT mem.* FROM issued_status ist
JOIN members mem ON ist.issued_member_id = mem.member_id
WHERE issued_date > CURDATE() - INTERVAL 2 MONTH;

-- Stored Procedure for Issuing Books
DELIMITER $$
CREATE PROCEDURE book_issue_record(
    IN p_issued_id VARCHAR(50),
    IN p_member_id VARCHAR(50),
    IN p_issued_book_isbn VARCHAR(50),
    IN p_issued_emp_id VARCHAR(50)
)
BEGIN
    DECLARE v_status VARCHAR(10);
    DECLARE v_book_name VARCHAR(100);

    SELECT status, book_title INTO v_status, v_book_name
    FROM books
    WHERE isbn = p_issued_book_isbn;

    IF v_status = 'yes' THEN
        INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES (p_issued_id, p_member_id, CURDATE(), p_issued_book_isbn, p_issued_emp_id);

        UPDATE books
        SET status = 'no'
        WHERE isbn = p_issued_book_isbn;

        SELECT CONCAT("Book '", v_book_name, "' has been issued successfully!") AS message;
    ELSE
        SELECT CONCAT("Sorry, the book '", v_book_name, "' is unavailable.") AS message;
    END IF;
END $$
DELIMITER ;