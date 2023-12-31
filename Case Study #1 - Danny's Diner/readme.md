# 🍜 Case Study #1: Danny's Diner 
<img src="https://user-images.githubusercontent.com/81607668/127727503-9d9e7a25-93cb-4f95-8bd0-20b87cb4b459.png" alt="Image" width="500" height="520">

## 📚 Table of Contents
- [Business Task](#business-task)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Question and Solution](#question-and-solution)

Please note that all the information regarding the case study has been sourced from the following link: [here](https://8weeksqlchallenge.com/case-study-1/). 

***

## Business Task
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favorite. 

***

## Entity Relationship Diagram

![image](https://user-images.githubusercontent.com/81607668/127271130-dca9aedd-4ca9-4ed8-b6ec-1e1920dca4a8.png)

***
## Question and Solution
**1. What is the total amount each customer spent at the restaurant?**
````sql
SELECT customer_id, 
		SUM(price) as total_amount
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY customer_id
````
#### Answer:
| customer_id | total_sales |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |

***

**2. How many days has each customer visited the restaurant?**
````sql
SELECT customer_id, 
	COUNT(DISTINCT(order_date)) as days_visited
FROM dannys_diner.sales
GROUP BY customer_id;
````
#### Answer:
| customer_id | visit_count |
| ----------- | ----------- |
| A           | 4          |
| B           | 6          |
| C           | 2          |

***

**3. What was the first item from the menu purchased by each customer?**

````sql
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
````

#### Answer: (Approach_1)
| customer_id | product_name | 
| ----------- | ----------- |
| A           | curry        | 
| A           | sushi        | 
| B           | curry        | 
| C           | ramen        |

#### Answer: (Approach_2)
| customer_id | product_name | 
| ----------- | ----------- |
| A           | curry,sushi | 
| B           | curry        | 
| C           | ramen        |

***
**4. What is the most purchased item on the menu and how many times was it purchased by all customers?**
````sql
SELECT TOP 1 m.product_name most_purchased_item,
	COUNT(1) as count
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY s.product_id, m.product_name
ORDER BY COUNT(1) DESC;
````
#### Answer:
| most_purchased | product_name | 
| ----------- | ----------- |
| 8       | ramen |
***

**5. Which item was the most popular for each customer?**

````sql
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

````

#### Answer:
| customer_id | product_name |
| ----------- | ---------- |
| A           | ramen      |  
| B           | curry,ramen,sushi |     
| C           | ramen     |  
