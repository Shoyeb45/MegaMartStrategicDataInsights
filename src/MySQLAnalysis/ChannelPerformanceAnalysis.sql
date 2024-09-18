use tpcds;

-- 1. Sales Contribution by Channel: Calculate the contribution of each sales channel to the total revenue.

SELECT @webSalesVal := SUM(ws_sales_price * ws_quantity) FROM web_sales ;
SELECT @storeSalesVal := SUM(ss_sales_price * ss_quantity) FROM store_sales ;
SELECT @catalogSalesVal := SUM(cs_sales_price * cs_quantity) FROM catalog_sales ;

SELECT @total := @webSalesVal + @storeSalesVal + @catalogSalesVal;

SELECT
    "Web" AS channel, 
    ROUND(@webSalesVal, 2) AS sales,
    ROUND(@webSalesVal / @total, 5) * 100 AS contribution
UNION ALL 
SELECT
    "Store" AS channel,
    ROUND(@storeSalesVal, 2) AS sales,
    ROUND(@storeSalesVal / @total, 5) * 100 AS contribution
UNION ALL 
SELECT
    "Catalog" AS channel,
    ROUND(@catalogSalesVal, 2) AS sales,
    ROUND(@catalogSalesVal / @total, 5) * 100 AS contribution

-- 2. Customer Satisfaction by Channel: Analyze customer satisfaction scores across different sales channels (requires hypothetical satisfaction data)

-- NOT ABLE TO DO

-- 3. Conversion Rate for Online Sales: : Calculate the conversion rate for web visitors who complete a purchase.

show tables;
SELECT * FROM web_sales;

WITH totalVisitors AS (
    SELECT 
        COUNT(wp_customer_sk) AS total_visitors
    FROM 
        web_page
    WHERE 
        wp_customer_sk IS NOT NULL
),
purchasingCustomer AS (
    SELECT 
        COUNT(DISTINCT ws_bill_customer_sk) AS total_purchasing_customers
    FROM 
        web_sales
    WHERE   
        ws_quantity > 0
)
SELECT 
    tv.total_visitors,
    pc.total_purchasing_customers,
    (pc.total_purchasing_customers / tv.total_visitors) * 100 AS conversion_rate
FROM 
    totalVisitors tv,
    purchasingCustomer pc;


-- 4. In-Store vs. Online Sales Growth:  Compare the sales growth rates between in-store and online channels over the past year.
-- Past Year : 2001
WITH webSales AS (
    SELECT
        DATE_FORMAT(dd.d_date, "%Y-%M") AS month,
        COALESCE(SUM(ws.ws_quantity * ws.ws_sales_price)) AS sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd 
        ON dd.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        YEAR(dd.d_date) = 2001
    GROUP BY 
        DATE_FORMAT(dd.d_date, "%Y-%M")
),
storeSales AS (
    SELECT
        DATE_FORMAT(dd.d_date, "%Y-%M") AS month,
        COALESCE(SUM(ss.ss_quantity * ss.ss_sales_price)) AS sales
    FROM 
        store_sales ss
    JOIN 
        date_dim dd 
        ON dd.d_date_sk = ss.ss_sold_date_sk
    WHERE 
        YEAR(dd.d_date) = 2001
    GROUP BY 
        DATE_FORMAT(dd.d_date, "%Y-%M")
),
webSalesGrowth AS (
    SELECT 
        month, 
        sales,
        LAG(sales) OVER (ORDER BY month) AS prev_sales,
        ( (sales - LAG(sales) OVER (ORDER BY month)) / LAG(sales) OVER (ORDER BY month) ) * 100 AS online_growth_rate
    FROM
         webSales
),
storeSalesGrowth AS (
    SELECT 
        month, 
        sales,
        LAG(sales) OVER (ORDER BY month) AS prev_sales,
        ( (sales - LAG(sales) OVER (ORDER BY month)) / LAG(sales) OVER (ORDER BY month) ) * 100 AS store_growth_rate
    FROM
        storeSales
)
SELECT
    wsg.month,
    wsg.sales AS web_total_sales,
    wsg.online_growth_rate,
    ssg.sales AS store_total_sales,
    ssg.store_growth_rate
FROM
    webSalesGrowth wsg
LEFT JOIN
    storeSalesGrowth ssg
    ON wsg.month = ssg.month;



-- 5. Product Performance by Channel: Analyze which products perform best in each sales channel
SELECT * FROM store_sales;

SELECT * FROM (
    SELECT 
        "Web Channel" AS channel,
        ws.ws_item_sk AS item_sk,
        i.i_product_name AS product_name,
        COALESCE(SUM(ws.ws_quantity * ws.ws_sales_price)) AS sales
    FROM
        web_sales ws
    JOIN
        item i 
        ON i.i_item_sk = ws.ws_item_sk
    GROUP BY
        ws.ws_item_sk, i.i_product_name
    ORDER BY
        sales DESC
    LIMIT 1
) AS web_sales_top
UNION ALL
SELECT * FROM (
    SELECT 
        "Store Channel" AS channel,
        ss.ss_item_sk AS item_sk,
        i.i_product_name AS product_name,
        COALESCE(SUM(ss.ss_quantity * ss.ss_sales_price)) AS sales
    FROM
        store_sales ss
    JOIN
        item i 
        ON i.i_item_sk = ss.ss_item_sk
    GROUP BY
        ss.ss_item_sk, i.i_product_name
    ORDER BY
        sales DESC
    LIMIT 1
) AS store_sales_top
UNION ALL
SELECT * FROM (
    SELECT
        "Catalog Channel" AS channel, 
        cs.cs_item_sk AS item_sk,
        i.i_product_name AS product_name,
        COALESCE(SUM(cs.cs_quantity * cs.cs_sales_price)) AS sales
    FROM
        catalog_sales cs
    JOIN
        item i 
        ON i.i_item_sk = cs.cs_item_sk
    GROUP BY
        cs.cs_item_sk, i.i_product_name
    ORDER BY
        sales DESC
    LIMIT 1
) AS catalog_sales_top;



-- 6. Channel Profitability Analysis: : Calculate the profitability of each sales channel by comparing revenue to associated costs.

SELECT * FROM web_sales;
WITH web_channel AS (
    SELECT
        'Web Channel' AS channel,
        SUM(ws_quantity * ws_sales_price) AS total_revenue,
        SUM(ws_quantity * ws_wholesale_cost) AS total_costs
    FROM
        web_sales
),
store_channel AS (
    SELECT
        'Store Channel' AS channel,
        SUM(ss_quantity * ss_sales_price) AS total_revenue,
        SUM(ss_quantity * ss_wholesale_cost) AS total_costs
    FROM
        store_sales
),
catalog_channel AS (
    SELECT
        'Catalog Channel' AS channel,
        SUM(cs_quantity * cs_sales_price) AS total_revenue,
        SUM(cs_quantity * cs_wholesale_cost) AS total_costs
    FROM
        catalog_sales
)
SELECT
    channel,
    total_revenue,
    total_costs,
    (total_revenue - total_costs) AS profitability
FROM
    web_channel
UNION ALL
SELECT
    channel,
    total_revenue,
    total_costs,
    (total_revenue - total_costs) AS profitability
FROM
    store_channel
UNION ALL
SELECT
    channel,
    total_revenue,
    total_costs,
    (total_revenue - total_costs) AS profitability
FROM
    catalog_channel;
