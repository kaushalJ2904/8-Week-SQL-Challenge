
--Case Study #2 - Pizza Runner

/*

******** A. Pizza Metrics ******** 
	1 - How many pizzas were ordered?
	2 - How many unique customer orders were made?
	3 - How many successful orders were delivered by each runner?
	4 - How many of each type of pizza was delivered?
	5 - How many Vegetarian and Meatlovers were ordered by each customer?
	6 - What was the maximum number of pizzas delivered in a single order?
	7 - For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
	8 - How many pizzas were delivered that had both exclusions and extras?
	9 - What was the total volume of pizzas ordered for each hour of the day?
	10 - What was the volume of orders for each day of the week?

******** B. Runner and Customer Experience ********
	1 - How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
	2 - What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
	3 - Is there any relationship between the number of pizzas and how long the order takes to prepare?
	4 - What was the average distance travelled for each customer?
	5 - What was the difference between the longest and shortest delivery times for all orders?
	6 - What was the average speed for each runner for each delivery and do you notice any trend for these values?
	7 - What is the successful delivery percentage for each runner?

******** C. Ingredient Optimisation ******** 
	1 - What are the standard ingredients for each pizza?
	2 - What was the most commonly added extra?
	3 - What was the most common exclusion?
	4 - Generate an order item for each record in the customers_orders table in the format of one of the following:
		Meat Lovers
		Meat Lovers - Exclude Beef
		Meat Lovers - Extra Bacon
		Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
	5 - Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
		For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
	6 - What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

******** D. Pricing and Ratings ******** 
	1 - If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
	2 - What if there was an additional $1 charge for any pizza extras?
		Add cheese is $1 extra
	3 - The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
	4 - Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
		customer_id
		order_id
		runner_id
		rating
		order_time
		pickup_time
		Time between order and pickup
		Delivery duration
		Average speed
		Total number of pizzas
	5 - If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

******** E. Bonus Questions ******** 
1 - If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

*/


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--A. Pizza Metrics

--Question_1 - How many pizzas were ordered?

SELECT 
	COUNT(*) as total_pizzas
FROM pizza_runner.customer_orders


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question_2 - How many unique customer orders were made?

SELECT 
	COUNT(DISTINCT(order_id)) as unique_customer_order
FROM pizza_runner.customer_orders


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question_3 - How many successful orders were delivered by each runner?

SELECT * FROM pizza_runner.customer_orders

SELECT 
	runner_id, 
	COUNT(1) as successful_orders  
FROM pizza_runner.runner_orders
WHERE cancellation is NULL
GROUP BY runner_id


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question_4 - How many of each type of pizza was delivered?

SELECT 
	co.pizza_id,
	pn.pizza_name,
	COUNT(co.pizza_id) as each_type_of_pizza
FROM pizza_runner.customer_orders co
LEFT JOIN pizza_runner.pizza_names pn
ON co.pizza_id = pn.pizza_id
LEFT JOIN pizza_runner.runner_orders ro
ON co.order_id = ro.order_id
WHERE cancellation is null
GROUP BY co.pizza_id, pn.pizza_name


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question_5 - How many Vegetarian and Meatlovers were ordered by each customer?

SELECT 
		c.customer_id, 
		p.pizza_name, 
		COUNT(1) as count_of_pizza
FROM pizza_runner.customer_orders c
LEFT JOIN pizza_runner.pizza_names p
ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id, p.pizza_name
ORDER BY c.customer_id


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question_6 - What was the maximum number of pizzas delivered in a single order?


SELECT 
	TOP 1 c.customer_id,c.order_id, COUNT(1) as max_pizza
FROM pizza_runner.customer_orders c
LEFT JOIN pizza_runner.runner_orders r
ON c.order_id = r.order_id
WHERE cancellation is null
GROUP BY c.customer_id,c.order_id
ORDER BY COUNT(1) DESC



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question_7 - For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT  c.customer_id,
		SUM(CASE WHEN c.exclusions is not null OR c.extras is not null THEN 1 ELSE 0 END) as pizza_with_change,
		SUM(CASE WHEN c.exclusions is null AND c.extras is null THEN 1 ELSE 0 END) as pizza_with_no_change
FROM pizza_runner.customer_orders c
LEFT JOIN pizza_runner.runner_orders r
ON c.order_id = r.order_id
WHERE r.cancellation is NULL
GROUP BY c.customer_id


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question_8 - How many pizzas were delivered that had both exclusions and extras?

SELECT 
		c.customer_id,
	    SUM(CASE WHEN c.exclusions is not null and c.extras is not null THEN 1 ELSE 0 END) both_changes_in_pizza
FROM pizza_runner.customer_orders c
LEFT JOIN pizza_runner.runner_orders r
ON c.order_id = r.order_id
WHERE r.cancellation is NULL
GROUP BY c.customer_id


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question_9 - What was the total volume of pizzas ordered for each hour of the day?

SELECT 
		DATEPART(HOUR, order_time) as hr,
		COUNT(1) no_of_pizzas_ordered
FROM pizza_runner.customer_orders
GROUP BY DATEPART(HOUR, order_time)


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Question_10 - What was the volume of orders for each day of the week?


SELECT
	DATEPART(WEEKDAY, order_time) as week_day,
    DATENAME(WEEKDAY, order_time) AS week_day_name,
    COUNT(1) AS no_of_pizzas_ordered
FROM 
    pizza_runner.customer_orders
GROUP BY 
	DATEPART(WEEKDAY, order_time),
    DATENAME(WEEKDAY, order_time);

   









