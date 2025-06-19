/* Δημιουργία της ΒΔ */
CREATE DATABASE eb_Instacart

/* Δημιουργία πινάκων για ΒΔ */

-- aisles
CREATE TABLE raw_aisles (
    aisle_id INT PRIMARY KEY,
    aisle NVARCHAR(100)
)

-- Εισαγωγή δεδομένων
BULK INSERT raw_aisles
FROM 'C:\Temp\instacart\aisles.csv'
WITH (
			FIELDTERMINATOR = ';', 
			ROWTERMINATOR = '\n', 
			FIRSTROW = 2,
			CODEPAGE = '65001' 
)

-- Έλεγχος
SELECT COUNT(*) AS raw_aisles FROM raw_aisles  --134
SELECT TOP 10* FROM raw_aisles

-- departments
CREATE TABLE raw_departments (
    department_id INT PRIMARY KEY,
    department NVARCHAR(100)
)

-- Εισαγωγή δεδομένων
BULK INSERT raw_departments
FROM 'C:\Temp\instacart\departments.csv'
WITH (
			FIELDTERMINATOR = ';',
			ROWTERMINATOR = '\n', 
			FIRSTROW = 2, 
			CODEPAGE = '65001'
)

-- Έλεγχος
SELECT COUNT(*) AS raw_departments FROM raw_departments  --21
SELECT TOP 10* FROM raw_departments

-- products
CREATE TABLE raw_products (
    product_id INT PRIMARY KEY,
    product_name NVARCHAR(255),
    aisle_id INT,
    department_id INT
)

-- Εισαγωγή δεδομένων
BULK INSERT raw_products
FROM 'C:\Temp\instacart\products.csv'
WITH (
			FIELDTERMINATOR = ';',
			ROWTERMINATOR = '\n', 
			FIRSTROW = 2, 
			CODEPAGE = '65001'
)

-- Έλεγχος
SELECT COUNT(*) AS raw_products FROM raw_products  --49688
SELECT TOP 10* FROM raw_products

-- orders
CREATE TABLE raw_orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    eval_set NVARCHAR(10),
    order_number INT,
    order_dow INT,
    order_hour_of_day INT,
    days_since_prior_order INT NULL
)

-- Εισαγωγή δεδομένων
BULK INSERT raw_orders
FROM 'C:\Temp\instacart\orders.csv'
WITH (
			FIELDTERMINATOR = ';',
			ROWTERMINATOR = '0x0a', 
			FIRSTROW = 2, 
			CODEPAGE = '65001',
			KEEPNULLS
)

-- Έλεγχος
SELECT COUNT(*) AS raw_orders FROM raw_orders  -- 3421083
SELECT TOP 10* FROM raw_orders

-- order_products_prior
CREATE TABLE raw_order_products_prior (
    order_id INT,
    product_id INT,
    add_to_cart_order INT,
    reordered BIT
)

-- Εισαγωγή δεδομένων
BULK INSERT raw_order_products_prior
FROM 'C:\Temp\instacart\order_products_prior.csv'
WITH (
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a', 
			FIRSTROW = 2, 
			CODEPAGE = '65001',
			KEEPNULLS
)

-- Έλεγχος
SELECT COUNT(*) AS raw_order_products_prior FROM raw_order_products_prior  -- 32434489
SELECT TOP 10* FROM raw_order_products_prior

-- order_products_train
CREATE TABLE raw_order_products_train (
    order_id INT,
    product_id INT,
    add_to_cart_order INT,
    reordered BIT
)

-- Εισαγωγή δεδομένων
BULK INSERT raw_order_products_train
FROM 'C:\Temp\instacart\order_products_train.csv'
WITH (
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a', 
			FIRSTROW = 2, 
			CODEPAGE = '65001',
			KEEPNULLS
)

-- Έλεγχος
SELECT COUNT(*) AS raw_order_products_train FROM raw_order_products_train  -- 1384617
SELECT TOP 10* FROM raw_order_products_train


/* Προεπεξεργασία - μετασχηματισμός - έλεγχος δεδομένων */

-- NULLs
SELECT COUNT(*) FROM raw_orders WHERE days_since_prior_order IS NULL -- 206209 αλλά είναι σωστό γιατί είναι η πρώτη παραγγελία
SELECT COUNT(*) FROM raw_products WHERE product_name IS NULL OR product_name = '' -- 0

-- Invalid foreign keys
SELECT * FROM raw_products WHERE aisle_id NOT IN (SELECT aisle_id FROM raw_aisles) -- 0
SELECT * FROM raw_products WHERE department_id NOT IN (SELECT department_id FROM raw_departments) --0

-- Το order_hour_of_day πρέπει να είναι από 0 έως 23 -- σωστό
SELECT * FROM raw_orders WHERE order_hour_of_day NOT BETWEEN 0 AND 23 

-- Το order_dow πρέπει να είναι από 0 (Κυριακή) έως 6 (Σάββατο) -- σωστό
SELECT * FROM raw_orders WHERE order_dow NOT BETWEEN 0 AND 6 

-- Στον συνδυασμό order_id + product_id δεν πρέπει να υπάρχουν διπλότυπα (σε κάθε καλάθι κάθε προϊόν μία φορά) -- σωστό
SELECT order_id, product_id, COUNT(*) 
FROM raw_order_products_prior 
GROUP BY order_id, product_id 
HAVING COUNT(*) > 1

SELECT TOP 10* FROM raw_orders order by order_id
SELECT TOP 10* FROM raw_order_products_prior order by order_id
SELECT TOP 10* FROM raw_order_products_train order by order_id

/* Δημιουργία πίνακα DimTime */

-- Δημιουργία πίνακα DimTime βασισμένο σε μοναδικούς συνδυασμούς order_hour_of_day και order_dow από τον πίνακα raw_orders
-- Εξαγωγή μοναδικών συνδυασμών (order_hour_of_day, order_dow)
SELECT DISTINCT
    order_hour_of_day,
    order_dow
FROM raw_orders
ORDER BY order_hour_of_day, order_dow

-- Δημιουργία πίνακα DimTime
CREATE TABLE DimTime (
    time_id INT IDENTITY(1,1) PRIMARY KEY,
    order_hour_of_day INT,
    order_dow INT,
    part_of_day_category NVARCHAR(20),
    day_of_week_name NVARCHAR(15)
)

-- Εισαγωγή δεδομένων με mapping
INSERT INTO DimTime (order_hour_of_day, order_dow, part_of_day_category, day_of_week_name)
SELECT DISTINCT
    order_hour_of_day,
    order_dow,
    CASE 
        WHEN order_hour_of_day BETWEEN 0 AND 5 THEN 'Night'
        WHEN order_hour_of_day BETWEEN 6 AND 11 THEN 'Morning'
        WHEN order_hour_of_day BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS part_of_day_category,
    CASE order_dow
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS day_of_week_name
FROM raw_orders

-- Έλεγχος
SELECT * FROM DimTime ORDER BY time_id

-- Δημιουργία προσωρινού πίνακα με mapping order_id → time_id
SELECT 
    o.order_id,
    t.time_id
INTO order_time_map
FROM raw_orders o
JOIN DimTime t
  ON o.order_hour_of_day = t.order_hour_of_day
 AND o.order_dow = t.order_dow

-- Εξασφαλίζω ότι κάθε order_id έχει ένα και μόνο ένα time_id -- σωστό
SELECT order_id, COUNT(*) AS cnt
FROM order_time_map
GROUP BY order_id
HAVING COUNT(*) > 1

/* Δημιουργία πίνακα FactOrders */

-- Ενοποιώ τους πίνακες raw_order_products_prior και raw_order_products_train
SELECT * 
INTO all_order_products
FROM (
    SELECT * FROM raw_order_products_prior
    UNION ALL
    SELECT * FROM raw_order_products_train
) AS merged

-- Δημιουργία πίνακα FactOrders
SELECT 
    a.order_id,
    r.user_id,
    a.product_id,
    r.order_number,
    a.add_to_cart_order,
    a.reordered,
    r.days_since_prior_order,
    t.time_id
INTO FactOrders
FROM all_order_products a
JOIN raw_orders r
    ON a.order_id = r.order_id
JOIN order_time_map t
    ON a.order_id = t.order_id

-- Έλεγχος 
SELECT COUNT(*) AS total_facts FROM FactOrders -- 33819106
SELECT TOP 10 * FROM FactOrders

-- Ορισμός Primary Key στον FactOrders
-- Ελέγχω αν υπάρχει ο ίδιος συνδυασμός (order_id, product_id) περισσότερες από μία φορές
SELECT 
    TABLE_NAME,
    CONSTRAINT_NAME
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE CONSTRAINT_TYPE = 'PRIMARY KEY'

ALTER TABLE FactOrders
ALTER COLUMN order_id INT NOT NULL

SELECT COUNT(*) AS null_products
FROM FactOrders
WHERE product_id IS NULL

ALTER TABLE FactOrders
ALTER COLUMN product_id INT NOT NULL

ALTER TABLE FactOrders
ADD CONSTRAINT PK_FactOrders
PRIMARY KEY (order_id, product_id)

-- Index για performance
CREATE NONCLUSTERED INDEX idx_fact_time ON FactOrders(time_id)
CREATE NONCLUSTERED INDEX idx_fact_user ON FactOrders(user_id)
CREATE NONCLUSTERED INDEX idx_fact_product ON FactOrders(product_id)

-- Τελικός έλεγχος όλα τα FK
SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS

/* Δημιουργία πίνακα DimUser */

-- DimUser με στατιστικά για τη συμπεριφορά του κάθε πελάτη
WITH OrderStats AS (
    SELECT
        user_id,
        days_since_prior_order
    FROM raw_orders
    WHERE days_since_prior_order IS NOT NULL
),
ReorderStats AS (
    SELECT
        user_id,
        COUNT(*) AS total_products,
        SUM(CAST(reordered AS FLOAT)) AS reordered_products
    FROM FactOrders
    GROUP BY user_id
)

SELECT 
    o.user_id,
    COUNT(*) AS total_orders,
    CAST(AVG(CAST(o.days_since_prior_order AS FLOAT)) AS INT) AS avg_days_between_orders,
    MIN(o.days_since_prior_order) AS min_days,
    MAX(o.days_since_prior_order) AS max_days,
    CASE 
        WHEN AVG(CAST(o.days_since_prior_order AS FLOAT)) <= 4 THEN 'frequent'
        WHEN AVG(CAST(o.days_since_prior_order AS FLOAT)) BETWEEN 5 AND 10 THEN 'regular'
        ELSE 'rare'
    END AS frequency_category,
    CAST(r.reordered_products * 100.0 / r.total_products AS DECIMAL(5,2)) AS percent_reordered,
    CASE 
        WHEN r.reordered_products * 100.0 / r.total_products >= 80 THEN 'loyal'
        WHEN r.reordered_products * 100.0 / r.total_products BETWEEN 40 AND 79.99 THEN 'balanced'
        ELSE 'explorer'
    END AS reorder_category
INTO DimUser
FROM OrderStats o
JOIN ReorderStats r
  ON o.user_id = r.user_id
GROUP BY o.user_id, r.reordered_products, r.total_products

-- Έλεγχοι
SELECT TOP 1000* FROM DimUser ORDER BY avg_days_between_orders DESC

-- λογικές τιμές σε days_since_prior_order
SELECT *
FROM (
    SELECT
        user_id,
        days_since_prior_order
    FROM raw_orders
    WHERE days_since_prior_order IS NOT NULL
) AS OrderStats

-- Έλεγχος σε συγκεκριμένο user
SELECT * FROM raw_orders WHERE user_id = 14433
SELECT * FROM FactOrders WHERE user_id = 14433

-- Ορισμός Primary Key στον DimUser

ALTER TABLE DimUser
ALTER COLUMN user_id INT NOT NULL

ALTER TABLE DimUser
ADD CONSTRAINT PK_DimUser
PRIMARY KEY (user_id)


/* Δημιουργία πίνακα DimProduct */

-- Δημιουργία DimProduct
SELECT 
    p.product_id,
    p.product_name,
    p.aisle_id,
    a.aisle,
    p.department_id,
    d.department
INTO DimProduct
FROM raw_products p
JOIN raw_aisles a ON p.aisle_id = a.aisle_id
JOIN raw_departments d ON p.department_id = d.department_id

-- Έλεγχος
SELECT COUNT(*) AS total_products FROM DimProduct
SELECT TOP 10 * FROM DimProduct ORDER BY product_id

-- Πρωτεύον Κλειδί και Index στο DimProduct
ALTER TABLE DimProduct
ADD CONSTRAINT PK_DimProduct PRIMARY KEY (product_id)

CREATE NONCLUSTERED INDEX idx_dimproduct_department ON DimProduct(department_id)
CREATE NONCLUSTERED INDEX idx_dimproduct_aisle ON DimProduct(aisle_id)
CREATE NONCLUSTERED INDEX idx_fact_order_number ON FactOrders(order_number)


-- Ορισμός Foreign Keys στον FactOrders

-- product_id στο FactOrders που δεν υπάρχουν στη DimProduct
SELECT product_id 
FROM FactOrders 
WHERE product_id NOT IN (SELECT product_id FROM DimProduct)

ALTER TABLE FactOrders
ADD CONSTRAINT FK_FactOrders_Product
FOREIGN KEY (product_id) REFERENCES DimProduct(product_id)

-- user_id στο FactOrders που δεν υπάρχουν στη DimProduct -- όχι
SELECT user_id 
FROM FactOrders 
WHERE user_id NOT IN (SELECT user_id FROM DimUser)

ALTER TABLE FactOrders
ADD CONSTRAINT FK_FactOrders_Time
FOREIGN KEY (time_id) REFERENCES DimTime(time_id)

-- time_id στο FactOrders που δεν υπάρχουν στη DimProduct -- όχι
SELECT time_id 
FROM FactOrders 
WHERE time_id NOT IN (SELECT time_id FROM DimTime)

ALTER TABLE FactOrders
ADD CONSTRAINT FK_FactOrders_User
FOREIGN KEY (user_id) REFERENCES DimUser(user_id)

-- Έλεγχος PRIMARY KEYS, FOREIGN KEYS, INDEXES είναι σωστά ορισμένα
-- PK
SELECT 
    t.name AS TableName,
    c.name AS ColumnName
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
JOIN sys.tables t ON i.object_id = t.object_id
WHERE i.is_primary_key = 1
ORDER BY t.name, i.name

-- FK
SELECT 
    fk.name AS ForeignKey,
    tp.name AS ParentTable,
    cp.name AS ParentColumn,
    tr.name AS ReferencedTable,
    cr.name AS ReferencedColumn
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.tables tp ON fkc.parent_object_id = tp.object_id
INNER JOIN sys.columns cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
INNER JOIN sys.tables tr ON fkc.referenced_object_id = tr.object_id
INNER JOIN sys.columns cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
ORDER BY fk.name

-- INDEXES
SELECT 
    t.name AS TableName,
    ind.name AS IndexName,
    ind.type_desc AS IndexType,
    col.name AS ColumnName,
    ic.is_included_column
FROM sys.indexes ind
INNER JOIN sys.index_columns ic ON ind.object_id = ic.object_id AND ind.index_id = ic.index_id
INNER JOIN sys.columns col ON ic.object_id = col.object_id AND ic.column_id = col.column_id
INNER JOIN sys.tables t ON ind.object_id = t.object_id
WHERE ind.is_primary_key = 0 AND ind.is_unique_constraint = 0
ORDER BY t.name, ind.name, ic.key_ordinal
