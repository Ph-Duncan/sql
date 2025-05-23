/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT 
product_name || ', ' || COALESCE(product_size, '')|| ' (' || COALESCE(product_qty_type, 'unit') || ')'
FROM product;

--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

--option 1: "display all rows in the customer_purchases table, with the counter changing on each NEW market date for each customer" 
--MD: Emphasis above is mine. I'm interpretting this as each unique date rather than each entry

SELECT 
*, dense_rank() OVER(PARTITION BY customer_id ORDER BY market_date) as market_visit_number
FROM  customer_purchases
ORDER BY customer_id, market_date, transaction_time
;



/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

--MD: Building from option 1 above, because it seems like we probably want to see what they bought on their most recent visit.

DROP TABLE IF EXISTS temp.customer_purchases_recent_visits;

CREATE TABLE temp.customer_purchases_recent_visits AS
SELECT *, DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY market_date DESC) as ranked_recent_market_visit
FROM customer_purchases
ORDER BY customer_id, market_date DESC, transaction_time DESC;

SELECT *
FROM temp.customer_purchases_recent_visits
WHERE ranked_recent_market_visit = 1
ORDER BY customer_id, transaction_time DESC;

/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

SELECT *, COUNT(product_id) OVER(PARTITION BY product_id, customer_id) AS total_times_purchased
FROM customer_purchases
ORDER BY customer_id, market_date DESC;

-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

SELECT *, 
CASE WHEN INSTR(product_name, '-') = 0 
	THEN NULL 
	ELSE RTRIM(LTRIM(SUBSTR(product_name, INSTR(product_name, '-')+1, LENGTH(product_name)))) 
	END AS description
FROM product;



/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */
SELECT *, 
CASE WHEN INSTR(product_name, '-') = 0 
	THEN NULL 
	ELSE RTRIM(LTRIM(SUBSTR(product_name, INSTR(product_name, '-')+1, LENGTH(product_name)))) 
	END AS description
FROM product
WHERE product_size REGEXP '[0-9]'
;


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */


--Step 1: create a customer_purchases table with price column (from Assignment 1)
DROP TABLE IF EXISTS temp.customer_purchases_with_price;
CREATE TABLE temp.customer_purchases_with_price AS
SELECT *, ROUND(quantity*cost_to_customer_per_qty, 2) AS price
FROM customer_purchases;

--Step 2 create a sales_per_day temp table (or could use as a sub-query for Step 3, but this avoids typos)
DROP TABLE IF EXISTS temp.sales_per_day;
CREATE TABLE temp.sales_per_day AS
SELECT DISTINCT market_date, sum(price) OVER (PARTITION BY market_date) AS total_sales
FROM temp.customer_purchases_with_price
ORDER BY total_sales DESC;

--Step 3: Query for Max & Min sales with union to row bind into a single table
SELECT 'Best Day' as best_vs_worst, market_date, MAX(total_sales) as total_sales
FROM temp.sales_per_day

UNION

SELECT 'Worst Day' as best_vs_worst, market_date, MIN(total_sales) as total_sales
FROM temp.sales_per_day;


/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

SELECT DISTINCT v.vendor_name, p.product_name,  vi.original_price * 5 * number_of_customers AS if_five_sales_per_customer
FROM vendor_inventory vi
LEFT JOIN product p
ON vi.product_id = p.product_id
LEFT JOIN vendor v
ON vi.vendor_id = v.vendor_id
CROSS JOIN
	(SELECT COUNT(customer_id) as number_of_customers
	FROM customer)
ORDER BY vendor_name, product_name;


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

--Create & View new product_units table
DROP TABLE IF EXISTS product_units;

CREATE TABLE product_units AS
	SELECT *, CURRENT_TIMESTAMP as 'snapshot_timestamp'
	FROM product
	WHERE product_qty_type = 'unit';
	
SELECT *
FROM product_units;

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units
VALUES (30, "Mark's Butter Tarts", "4 pack", 3, "unit", CURRENT_TIMESTAMP);

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

--MD: Which older record? This is a new product. Sorry Apple Pie, but I guess you are getting replaced.
DELETE FROM product_units
WHERE product_id = 7;


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.*/

ALTER TABLE product_units
ADD current_quantity INT;

/* Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product.
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.)
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

DROP TABLE IF EXISTS temp.current_inventory;

CREATE TEMP TABLE temp.current_inventory AS
SELECT pu.product_id, coalesce (vi.quantity, 0) AS most_recent_inventory
FROM product_units pu
LEFT JOIN 
	(
	SELECT *
	FROM
		(
		SELECT *, 
		row_number() OVER(PARTITION BY product_id ORDER BY market_date DESC) AS latest_entry
		FROM vendor_inventory
		)
	WHERE latest_entry = 1) vi
ON pu.product_id = vi.product_id 
ORDER BY  pu.product_id;

SELECT *
FROM current_inventory;


UPDATE product_units
SET current_quantity = 
	(
	SELECT current_inventory.most_recent_inventory
	FROM current_inventory
	WHERE current_inventory.product_id = product_units.product_id
	);

SELECT *
FROM product_units ;




