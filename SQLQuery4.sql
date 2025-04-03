 

use [adel hasan];
-- Q1A: SQL DDL Definition for Library Database

CREATE TABLE Publisher (
    publisher_id BIGINT PRIMARY KEY,
    name NVARCHAR(255) NOT NULL
);

CREATE TABLE Book (
    book_id BIGINT PRIMARY KEY,
    title NVARCHAR(255) NOT NULL,
    publisher_id BIGINT,
    FOREIGN KEY (publisher_id) REFERENCES Publisher(publisher_id)
);

CREATE TABLE Member (
    member_id BIGINT PRIMARY KEY,
    name NVARCHAR(255) NOT NULL
);

CREATE TABLE Borrowed (
    member_id BIGINT,
    book_id BIGINT,
    borrow_date DATETIME,
    return_date DATETIME,
    PRIMARY KEY (member_id, book_id),
    FOREIGN KEY (member_id) REFERENCES Member(member_id),
    FOREIGN KEY (book_id) REFERENCES Book(book_id)
);

-- Insert Sample Data
INSERT INTO Publisher (publisher_id, name) VALUES (1, 'First Publishing House'), (2, 'Arab Book House'), (3, 'Modern Printing Press');

INSERT INTO Book (book_id, title, publisher_id) VALUES
(101, 'Book A', 1),
(102, 'Book B', 1),
(103, 'Book C', 2),
(104, 'Book D', 3),
(105, 'Book E', 2);

INSERT INTO Member (member_id, name) VALUES (201, 'Ahmad'), (202, 'Adel'), (203, 'Omar');

INSERT INTO Borrowed (member_id, book_id, borrow_date, return_date) VALUES
(201, 104, '2024-07-01', NULL),
(201, 101, '2024-01-01', '2024-01-15'),
(201, 103, '2024-02-01', '2024-02-15'),
(201, 102, '2024-02-05', '2024-02-20'),
(201, 105, '2024-03-01', NULL),

(202, 102, '2024-01-05', '2024-01-20'),
(202, 104, '2024-03-10', NULL),

(202, 101, '2024-03-18', NULL),
(202, 103, '2024-03-22', NULL),
(202, 105, '2024-03-25', NULL),
(203, 101, '2024-02-15', NULL),
(203, 103, '2024-04-01', NULL),
(203, 104, '2024-04-05', NULL);

-- Q1B: SQL Queries

-- (a) Find members who have borrowed at least one book from a specific publisher
SELECT m.member_id, m.name
FROM Member m
WHERE EXISTS (
    SELECT 1 FROM Borrowed b
    JOIN Book bk ON b.book_id = bk.book_id
    WHERE b.member_id = m.member_id
    AND bk.publisher_id = (SELECT publisher_id FROM Publisher WHERE name = 'First Publishing House')
);

-- (b) Find members who borrowed all books from a specific publisher
SELECT m.member_id, m.name
FROM Member m
WHERE NOT EXISTS (
    SELECT bk.book_id FROM Book bk
    WHERE bk.publisher_id = (SELECT publisher_id FROM Publisher WHERE name = 'Penguin Random House')
    EXCEPT
    SELECT b.book_id FROM Borrowed b WHERE b.member_id = m.member_id
);

-- (c) Find members who borrowed more than 5 books from each publisher
SELECT m.member_id, m.name, p.name AS publisher_name
FROM Member m
JOIN Borrowed b ON m.member_id = b.member_id
JOIN Book bk ON b.book_id = bk.book_id
JOIN Publisher p ON bk.publisher_id = p.publisher_id
GROUP BY m.member_id, m.name, p.publisher_id, p.name
HAVING COUNT(b.book_id) > 5;

-- (d) Find the average number of books borrowed per member
SELECT AVG(book_count) AS avg_books_per_member
FROM (
    SELECT b.member_id, COUNT(b.book_id) AS book_count
    FROM Borrowed b
    GROUP BY b.member_id
) book_counts;

-- Q2: SQL Window Functions

-- Table Definition for Demand
CREATE TABLE Demand (
    product_id BIGINT,
    date DATE,
    qty INT,
    PRIMARY KEY (product_id, date)
);

-- Insert Sample Data for Demand
INSERT INTO Demand (product_id, date, qty) VALUES
(1, '2024-01-01', 10),
(1, '2024-01-02', 15),
(1, '2024-01-03', 5),
(2, '2024-01-01', 20),
(2, '2024-01-02', 25),
(2, '2024-01-03', 10);

-- (A) Cumulative total sum for qty from demand table
SELECT product_id, date, qty, 
       SUM(qty) OVER (
           PARTITION BY product_id 
           ORDER BY date 
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS cumulative_qty
FROM Demand;

-- (B) Extract the two worst-performing days of each product
SELECT product_id, date, qty
FROM (
    SELECT product_id, date, qty,
           RANK() OVER (PARTITION BY product_id ORDER BY qty ASC) AS rank_position
    FROM Demand
) ranked
WHERE rank_position <= 2;
