use tpcds;
show TABLEs;


-- 1. Warehouse Turnover Rate:  Calculate the inventory turnover rate for each warehouse
SELECT * FROM inventory;
SELECT * FROM warehouse;

-- Inventory Turnover Rate = Cost of Goods Sold (COGS) / Average Inventory



WITH avg_inventory AS (
    SELECT 
        inv.inv_warehouse_sk,  
        AVG(inv.inv_quantity_on_hand) AS avg_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_warehouse_sk
),
cogs AS (
    SELECT
        inv.inv_warehouse_sk,
        MAX(inv.inv_quantity_on_hand) - MIN(inv.inv_quantity_on_hand) AS cogs  
    FROM
        inventory inv
    GROUP BY 
        inv.inv_warehouse_sk
)
SELECT
    w.w_warehouse_name,
    ai.avg_inventory,
    c.cogs,
    (c.cogs / ai.avg_inventory) AS inventory_turnover_rate
FROM
    warehouse w
JOIN 
    avg_inventory ai ON w.w_warehouse_sk = ai.inv_warehouse_sk
JOIN 
    cogs c ON w.w_warehouse_sk = c.inv_warehouse_sk
ORDER BY 
    inventory_turnover_rate DESC;


-- 2. Average Shipping Timen: Determine the average shipping time for orders across different regions
SELECT * FROM ship_mode;
SELECT * FROM customer_address;
SELECT * FROM web_sales;


WITH temp1 AS (
    SELECT
        ws.ws_bill_customer_sk as customer_sk,
        d_sold.d_date AS sold_date,
        d_ship.d_date AS ship_date,
        (d_ship.d_date - d_sold.d_date) AS shipping_days
    FROM
        web_sales ws
    JOIN
        date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk 
    JOIN
        date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    WHERE
        ws.ws_ship_date_sk > ws.ws_sold_date_sk 
),
 shipping_time AS (
    SELECT  
        case
            when ca.ca_state in ('AZ', 'NM', 'TX', 'OK') then "SOUTHWEST"
            when ca.ca_state in ( 'CA', 'CO', 'ID', 'MT', 'NV', 'OR', 'UT', 'WA', 'WY', 'AK', 'HI') then "WEST"
            when ca.ca_state in ('ND', 'SD', 'NE', 'KS', 'MN', 'IA', 'MO', 'WI', 'IL', 'IN', 'MI', 'OH') then "MIDWEST"
            when ca.ca_state in ('PA', 'NY', 'NJ', 'CT', 'RI', 'MA', 'VT', 'NH', 'ME', 'DE', 'MD') then "NORTHEAST"
            when ca.ca_state in ('VA', 'WV', 'KY', 'TN', 'NC', 'SC', 'GA', 'FL', 'AL', 'MS', 'LA', 'AR') then "SOUTHEAST"
            else "UNKNOWN"
        end as region,
        t1.sold_date AS sold_date,
        t1.ship_date AS ship_date,
        t1.shipping_days AS shipping_days
    FROM 
        temp1 t1
    JOIN 
        customer c 
        ON c.c_customer_sk = t1.customer_sk
    JOIN 
        customer_address ca 
        ON ca.ca_address_sk = c.c_current_addr_sk 
)
SELECT 
    region,
    AVG(shipping_days) AS avg_shipping_time
FROM 
    shipping_time
GROUP BY 
    region
ORDER BY 
    avg_shipping_time;


-- 3. Delivery Success Rate: Analyze the delivery success rate and identify regions with high failure rates.

-- NOT ABLE TO DO


-- 4. Warehouse Stock Levels: Monitor the stock levels of key products in each warehouse.

-- NOT ABLE TO DO


-- 5. Shipping Mode Efficiency: Compare the efficiency of different shipping modes in terms of cost and delivery time.

-- NOT ABLE TO DO


-- 6. Supply Chain Bottleneck Analysis: Identify bottlenecks in the supply chain by analyzing delays in order fulfillment.

-- NOT ABLE TO DO


-- 7. Order Fulfillment Rate: Calculate the order fulfillment rate to ensure timely delivery of products.

-- NOT ABLE TO DO


