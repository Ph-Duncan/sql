/* ASSIGNMENT 1 */
/* SECTION 2 */


--SELECT
/* 1. Write a query that returns everything in the customer table. */
SELECT * 
FROM customer;


/* 2. Write a query that displays all of the columns and 10 rows from the cus- tomer table, 
sorted by customer_last_name, then customer_first_ name. */
SELECT * 
FROM customer 
ORDER BY customer_last_name ASC	, customer_first_name ASC
LIMIT 10;
--MD: Assume desired sort is alphabetical (ascending) rather than reverse alphabetical (descending)

--WHERE
/* 1. Write a query that returns all customer purchases of product IDs 4 and 9. */
-- option 1
SELECT * 
FROM customer_purchases
WHERE product_id IN (4, 9);

--MD: if you want product names listed first instead of just product IDs 
SELECT  p.product_name, cp.*
FROM customer_purchases AS cp
LEFT JOIN product AS p
ON cp.product_id = p.product_id
WHERE cp.product_id IN (4, 9);


-- option 2
SELECT * 
FROM customer_purchases
WHERE product_id = 4 
	OR product_id = 9;


/*2. Write a query that returns all customer purchases and a new calculated column 'price' (quantity * cost_to_customer_per_qty), 
filtered by vendor IDs between 8 and 10 (inclusive) using either:
	1.  two conditions using AND
	2.  one condition using BETWEEN
*/
-- option 1 - two conditions using AND
SELECT *, ROUND(quantity*cost_to_customer_per_qty, 2) AS price
FROM customer_purchases
WHERE vendor_id >=8 AND vendor_id <=10;

-- MD: Rounded price to two decimals for practicality, as the Point Of Sale is likely to round prices on a per-item basis rather at the end of aggregating all prices in the purchase before rounding 

-- option 2 - one condition using BETWEEN
SELECT *, ROUND(quantity*cost_to_customer_per_qty, 2) AS price
FROM customer_purchases
WHERE vendor_id BETWEEN 8 AND 10;

--MD: Again rounded price to two decimals to reflect likely reality
--MD: Option 2 is how I would choose to write this query


--CASE
/* 1. Products can be sold by the individual unit or by bulk measures like lbs. or oz. 
Using the product table, write a query that outputs the product_id and product_name
columns and add a column called prod_qty_type_condensed that displays the word “unit” 
if the product_qty_type is “unit,” and otherwise displays the word “bulk.” */

SELECT product_id, product_name 
	,CASE WHEN product_qty_type = 'unit' THEN 'unit'
		ELSE 'bulk'
		END AS prod_qty_type_condensed
FROM product;


/* 2. We want to flag all of the different types of pepper products that are sold at the market. 
add a column to the previous query called pepper_flag that outputs a 1 if the product_name 
contains the word “pepper” (regardless of capitalization), and otherwise outputs 0. */

SELECT product_id, product_name 
	,CASE WHEN product_qty_type = 'unit' THEN 'unit'
		ELSE 'bulk'
		END AS prod_qty_type_condensed
	,CASE WHEN product_name LIKE '%pepper%' THEN 1
		ELSE '0'
		END AS 'pepper_flag'
FROM product;


--JOIN
/* 1. Write a query that INNER JOINs the vendor table to the vendor_booth_assignments table on the 
vendor_id field they both have in common, and sorts the result by vendor_name, then market_date. */

SELECT *
FROM vendor AS v
INNER JOIN vendor_booth_assignments AS vba
ON v.vendor_id = vba.vendor_id
ORDER BY vendor_name ASC, market_date DESC;

/* 
MD: No prefered sort orders specified. 
	For vendor_name I assumed alphabetical (ascending) was desired. 
	For order of market_date I assumed most recent to oldest transactions would be desired (descending).
	If ascending market date is preferred, please use the following:
*/

SELECT *
FROM vendor AS v
INNER JOIN vendor_booth_assignments AS vba
ON v.vendor_id = vba.vendor_id
ORDER BY vendor_name ASC, market_date ASC;


/* SECTION 3 */

-- AGGREGATE
/* 1. Write a query that determines how many times each vendor has rented a booth 
at the farmer’s market by counting the vendor booth assignments per vendor_id. */

SELECT vendor_id, COUNT(booth_number) AS freq_booth_assignments
FROM vendor_booth_assignments
GROUP BY vendor_id;

--MD: added vendor names for easy reference
SELECT vba.vendor_id, v.vendor_name, COUNT(booth_number) AS freq_booth_assignments
FROM vendor_booth_assignments AS vba
LEFT JOIN vendor AS v
ON vba.vendor_id = v.vendor_id
GROUP BY vba.vendor_id;


/* 2. The Farmer’s Market Customer Appreciation Committee wants to give a bumper 
sticker to everyone who has ever spent more than $2000 at the market. Write a query that generates a list 
of customers for them to give stickers to, sorted by last name, then first name. 

HINT: This query requires you to join two tables, use an aggregate function, and use the HAVING keyword. */

--Sum of purchases by customer_id

--MD: Once again rounded price variable to two digits prior to calculating SUM to reflect likely behaviour at Point of Sale, 
--see also WHERE:Q2 for rationale
-- interpretting "spent more than $2000" as "spent greater than $2000" and not "spent equal to or greater than $2000"

SELECT c.customer_last_name, c.customer_first_name, SUM(ROUND(cp.quantity*cp.cost_to_customer_per_qty, 2)) AS price
FROM customer_purchases AS cp
FULL JOIN customer as c
ON cp.customer_id = c.customer_id
GROUP BY cp.customer_id
HAVING price > 2000
ORDER BY c.customer_last_name, c.customer_first_name;

/* MD: I know the point is to demonstrate understanding of the HAVING statement, what I would probably do in real life is 
add a flag variable e.g. "bumper_sticker_worthy" via CASE WHEN to indicate if the customer has spent over $2000. Then I would sort the query 
by bumper_sticker_worthy before sorting by last_name and first name. This way stakeholders can know why a customer was not deemed 
worthy of the bumper sticker. */



--Temp Table
/* 1. Insert the original vendor table into a temp.new_vendor and then add a 10th vendor: 
Thomass Superfood Store, a Fresh Focused store, owned by Thomas Rosenthal

HINT: This is two total queries -- first create the table from the original, then insert the new 10th vendor. 
When inserting the new vendor, you need to appropriately align the columns to be inserted 
(there are five columns to be inserted, I've given you the details, but not the syntax) 

-> To insert the new row use VALUES, specifying the value you want for each column:
VALUES(col1,col2,col3,col4,col5) 
*/

DROP TABLE IF EXISTS temp.new_vendor;

CREATE TABLE temp.new_vendor AS

SELECT vendor_id, vendor_name, vendor_type, vendor_owner_first_name, vendor_owner_last_name
FROM vendor;

INSERT INTO temp.new_vendor(vendor_id, vendor_name, vendor_type, vendor_owner_first_name, vendor_owner_last_name)
VALUES(10, "Thomass Superfood Store" , "Fresh Focused" , "Thomas" , "Rosenthal");

SELECT *
FROM temp.new_vendor;

--MD: went specific with the select statement to match the INSERT TO statement

-- Date
/*1. Get the customer_id, month, and year (in separate columns) of every purchase in the customer_purchases table.

HINT: you might need to search for strfrtime modifers sqlite on the web to know what the modifers for month 
and year are! */

--option 1: SELECT all
SELECT  *, STRFTIME('%m', market_date) AS Month, STRFTIME('%Y', market_date) AS Year
FROM customer_purchases;

/* MD: would replace * with customer_id (and probably transaction_time to differentiate multiple transactions on same day) 
if all that is wanted was "customer_id, month, and year", but used * based on the next Question prompt */


/* 2. Using the previous query as a base, determine how much money each customer spent in April 2022. 
Remember that money spent is quantity*cost_to_customer_per_qty. 

HINTS: you will need to AGGREGATE, GROUP BY, and filter...
but remember, STRFTIME returns a STRING for your WHERE statement!! */

--option 1: use WHERE to narrow down query specific month and year only
--dropped * from previous query for just customer_id as several variables (transaction_time, market_date) are no longer relevant after aggregation 

SELECT customer_id, STRFTIME('%m', market_date) AS month, STRFTIME('%Y', market_date) AS year, SUM(ROUND(quantity*cost_to_customer_per_qty, 2)) AS price
FROM customer_purchases
WHERE month = "04" AND year = "2022"
GROUP BY customer_id;

--option 2: aggregate by customer_id, month, and year then filter by month and year in HAVING statement
--MD: this is the option I would use as a basis so that I can get the same data for other months and years if needed

SELECT customer_id,  STRFTIME('%m', market_date) AS month, STRFTIME('%Y', market_date) AS year, SUM(ROUND(quantity*cost_to_customer_per_qty, 2)) AS price
FROM customer_purchases 
GROUP BY customer_id, month, year
HAVING month = "04" AND year = "2022";

--extend option 2: would rather see customer names than just IDs, so I would add a JOIN statement to get the customer names

SELECT cp.customer_id, c.customer_last_name, c.customer_first_name,  STRFTIME('%m', market_date) AS month, STRFTIME('%Y', market_date) AS year, SUM(ROUND(quantity*cost_to_customer_per_qty, 2)) AS price
FROM customer_purchases AS cp
LEFT JOIN customer as c
ON cp.customer_id = c.customer_id
GROUP BY cp.customer_id, month, year
HAVING month = "04" AND year = "2022";