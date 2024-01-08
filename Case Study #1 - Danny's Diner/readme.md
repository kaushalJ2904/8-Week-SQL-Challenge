# 🍜 Case Study #1: Danny's Diner 
<img src="https://user-images.githubusercontent.com/81607668/127727503-9d9e7a25-93cb-4f95-8bd0-20b87cb4b459.png" alt="Image" width="500" height="520">

## 📚 Table of Contents
- [Business Task](#business-task)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Question and Solution](#question-and-solution)

All information is sourced from: [here](https://8weeksqlchallenge.com/case-study-1/). 

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

**6. Which item was purchased first by the customer after they became a member?**

````sql
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
````
#### Answer:
| customer_id | product_name | 
| ----------- | ------------ | 
| A           | curry        |
| B           | sushi        | 

**7. Which item was purchased just before the customer became a member?**

````sql
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
````
#### Answer:
| customer_id | product_name |
| ----------- | ---------- |
| A           | sushi, curry        |
| B           | sushi        |

**8. What is the total items and amount spent for each member before they became a member?**
````sql
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

````
#### Answer:
| customer_id | total_items | total_sales |
| ----------- | ---------- |----------  |
| A           | 2 |  $25       |
| B           | 3 |  $40       |

**9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?**
```sql
SELECT s.customer_id,
	   SUM(CASE WHEN product_name = 'sushi' THEN price * 20 ELSE price * 10 END) as points
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY customer_id
```

#### Answer:
| customer_id | total_points | 
| ----------- | ---------- |
| A           | 860 |
| B           | 940 |
| C           | 360 |

**10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?**

````sql
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

````

#### Answer:
| customer_id | total_points | 
| ----------- | ---------- |
| A           | 1020 |
| B           | 320 |

###  Bonus Questions

#### Join All The Things
Create basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL. Fill Member column as 'N' if the purchase was made before becoming a member and 'Y' if the after is amde after joining the membership.

#### Required Result set:
![image](https://user-images.githubusercontent.com/77529445/167406964-25276db9-fe1c-4608-8b77-b0970b156888.png)

```sql
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
```

#### Answer: 
| customer_id | order_date | product_name | price | member |
| ----------- | ---------- | -------------| ----- | ------ |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |
	


***

#### Rank All The Things
Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

#### Required Result set:
![image](https://user-images.githubusercontent.com/77529445/167407504-41d02dd0-0bd1-4a3c-8f41-00ae07daefad.png)


```sql
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
```

#### Answer: 
| customer_id | order_date | product_name | price | member | ranking | 
| ----------- | ---------- | -------------| ----- | ------ |-------- |
| A           | 2021-01-01 | sushi        | 10    | N      | NULL
| A           | 2021-01-01 | curry        | 15    | N      | NULL
| A           | 2021-01-07 | curry        | 15    | Y      | 1
| A           | 2021-01-10 | ramen        | 12    | Y      | 2
| A           | 2021-01-11 | ramen        | 12    | Y      | 3
| A           | 2021-01-11 | ramen        | 12    | Y      | 3
| B           | 2021-01-01 | curry        | 15    | N      | NULL
| B           | 2021-01-02 | curry        | 15    | N      | NULL
| B           | 2021-01-04 | sushi        | 10    | N      | NULL
| B           | 2021-01-11 | sushi        | 10    | Y      | 1
| B           | 2021-01-16 | ramen        | 12    | Y      | 2
| B           | 2021-02-01 | ramen        | 12    | Y      | 3
| C           | 2021-01-01 | ramen        | 12    | N      | NULL
| C           | 2021-01-01 | ramen        | 12    | N      | NULL
| C           | 2021-01-07 | ramen        | 12    | N      | NULL



***
