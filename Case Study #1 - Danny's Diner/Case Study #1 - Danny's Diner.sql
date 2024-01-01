

--Case Study #1 - Danny's Diner

/*

Each of the following case study questions can be answered using a single SQL statement:

1 - What is the total amount each customer spent at the restaurant?
2 - How many days has each customer visited the restaurant?
3 - What was the first item from the menu purchased by each customer?
4 - What is the most purchased item on the menu and how many times was it purchased by all customers?
5 - Which item was the most popular for each customer?
6 - Which item was purchased first by the customer after they became a member?
7 - Which item was purchased just before the customer became a member?
8 - What is the total items and amount spent for each member before they became a member?
9 - If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10 - In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
	how many points do customer A and B have at the end of January?

*/

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question 1  - What is the total amount each customer spent at the restaurant?

SELECT customer_id, 
		SUM(price) as total_amount
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY customer_id


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question 2  - How many days has each customer visited the restaurant?

SELECT customer_id, 
	COUNT(DISTINCT(order_date)) as days_visited
FROM dannys_diner.sales
GROUP BY customer_id;


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question 3  - What was the first item from the menu purchased by each customer?

--Approach_1
WITH cte AS(
	SELECT *,
		DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date)	as order_chronology
	FROM 
	dannys_diner.sales
)
SELECT customer_id, 
  product_name
FROM cte c
JOIN dannys_diner.menu m
ON c.product_id = m.product_id
WHERE order_chronology = 1
GROUP BY customer_id, product_name;	

--Approach_2 (Using sting_agg function)
WITH cte AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_chronology
    FROM dannys_diner.sales
),cte2 AS (
	SELECT DISTINCT c.customer_id, m.product_name, c.order_date
	FROM cte c
	JOIN dannys_diner.menu m ON c.product_id = m.product_id
	WHERE c.order_chronology = 1
)
SELECT customer_id,
	STRING_AGG(product_name, ',') WITHIN GROUP(ORDER BY order_date) as first_order
FROM cte2
GROUP BY customer_id


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question 4 - What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 m.product_name most_purchased_item, COUNT(1) as count
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY s.product_id, m.product_name
ORDER BY COUNT(1) DESC;


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question 5 - Which item was the most popular for each customer?

WITH cte AS (
	SELECT s.customer_id,
		   m.product_name,
		   COUNT(1) as popular_fg
	FROM dannys_diner.sales s
	LEFT JOIN dannys_diner.menu m
	ON s.product_id = m.product_id
	GROUP BY customer_id, product_name
),cte2 AS (
	SELECT *,
			MAX(popular_fg) OVER(PARTITION BY customer_id) as most_popular
	FROM cte
)
SELECT customer_id,
	   STRING_AGG(product_name,', ') WITHIN GROUP(ORDER BY customer_id) as most_popular
	FROM cte2
WHERE popular_fg = most_popular
GROUP BY customer_id
GO


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question 6 - Which item was purchased first by the customer after they became a member?

WITH cte AS (
	SELECT s.customer_id,
			s.order_date,
			mu.product_name,
			DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date) as rnk
	FROM dannys_diner.sales s
	JOIN dannys_diner.members m
	ON s.customer_id = m.customer_id
	JOIN dannys_diner.menu mu
	ON s.product_id = mu.product_id
	WHERE order_date >= join_date
)
SELECT *
FROM cte
WHERE rnk = 1


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question 7 - Which item was purchased just before the customer became a member?

WITH cte AS (
	SELECT s.customer_id,
		   s.order_date,
		   mu.product_name,
		   DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as rnk
	FROM dannys_diner.sales s
	LEFT JOIN dannys_diner.members m
	ON s.customer_id = m.customer_id
	LEFT JOIN dannys_diner.menu mu
	ON s.product_id = mu.product_id
	WHERE order_date < join_date
),cte2 AS (
	SELECT *,
		MAX(rnk) OVER(PARTITION BY customer_id) as order_identifier
	FROM cte
)SELECT customer_id,
		STRING_AGG(product_name, ', ') WITHIN GROUP(ORDER BY order_date) items
FROM cte2 
WHERE rnk = order_identifier
GROUP BY customer_id


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question 8 - What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id,
	   COUNT(1) as total_items,
	   CONCAT('$', SUM(price)) as total_spent
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.members m
ON s.customer_id = m.customer_id
LEFT JOIN dannys_diner.menu mu
ON s.product_id = mu.product_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question 9 - If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id,
	   SUM(CASE WHEN product_name = 'sushi' THEN price * 20 ELSE price * 10 END) as points
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY customer_id


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question 10 - In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


	SELECT s.customer_id,
			SUM(CASE WHEN product_name = 'sushi' THEN price * 20
				WHEN order_date >= join_date AND DATEPART(DAY,s.order_date) <  DATEPART(DAY,DATEADD(DAY,6,join_date)) THEN mu.price*20
			ELSE price * 10
			END) as total_points
	FROM dannys_diner.sales s
	JOIN dannys_diner.menu mu 
	ON s.product_id = mu.product_id
	JOIN dannys_diner.members m
	ON s.customer_id = m.customer_id
	WHERE order_date <= '2021-01-31'
	AND order_date >= join_date
	GROUP BY s.customer_id


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question 11 - Bonus Questions - Join All The Things


SELECT s.customer_id,
       s.order_date,
	   m.product_name,
	   m.price,
	   CASE WHEN s.order_date >= mb.join_date THEN 'Y' ELSE 'N' END as member
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
LEFT JOIN dannys_diner.members mb
ON s.customer_id = mb.customer_id


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question 12 -Bonus Questions - Ranking All The Things


WITH cte AS (
	SELECT s.customer_id,
		   s.order_date,
		   m.product_name,
		   m.price,
		   CASE WHEN s.order_date >= mb.join_date THEN 'Y' ELSE 'N' END as member
	FROM dannys_diner.sales s
	LEFT JOIN dannys_diner.menu m
	ON s.product_id = m.product_id
	LEFT JOIN dannys_diner.members mb
	ON s.customer_id = mb.customer_id
)
SELECT *,
		CASE WHEN member = 'N' THEN null 
			ELSE DENSE_RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date) 
		END as ranking
FROM cte




