use tpcds;
show tables;

-- 1. Customer Segmentation by Demographics: Segment customers based on age, income, and region.
select * from customer;
select * from income_band;
select * from customer_address;
select * from household_demographics;

select 
    concat(c.c_salutation, " ", c.c_first_name, " ", c.c_last_name), 
    2001 - c.c_birth_year as age,
    case
        when ca.ca_state in ('AZ', 'NM', 'TX', 'OK') then "SOUTHWEST"
        when ca.ca_state in ( 'CA', 'CO', 'ID', 'MT', 'NV', 'OR', 'UT', 'WA', 'WY', 'AK', 'HI') then "WEST"
        when ca.ca_state in ('ND', 'SD', 'NE', 'KS', 'MN', 'IA', 'MO', 'WI', 'IL', 'IN', 'MI', 'OH') then "MIDWEST"
        when ca.ca_state in ('PA', 'NY', 'NJ', 'CT', 'RI', 'MA', 'VT', 'NH', 'ME', 'DE', 'MD') then "NORTHEAST"
        when ca.ca_state in ('VA', 'WV', 'KY', 'TN', 'NC', 'SC', 'GA', 'FL', 'AL', 'MS', 'LA', 'AR') then "SOUTHEAST"
        else "UNKNOWN"
        end as region,
        ib.ib_lower_bound as lowerBoundIncome,
        ib.ib_upper_bound as upperBoundIncome
from 
    customer c
left join
    customer_address ca
    on ca.ca_address_sk = c.c_current_addr_sk
left join
    household_demographics hd
    on hd.hd_demo_sk = c.c_current_hdemo_sk
left join
    income_band ib
    on ib.ib_income_band_sk = hd.hd_income_band_sk;



-- 2. Customer Lifetime Value (CLTV): Calculate the customer lifetime value based on past purchase behavior
-- CLTV = Average Purchase Value × Average Purchase Frequency × Customer Lifespan
SELECT * FROM customer;


WITH temp_info AS (
    SELECT
        c.c_customer_sk as customer_sk,
        AVG(COALESCE(ws.ws_quantity * ws.ws_sales_price + ss.ss_quantity * ss.ss_sales_price + cs.cs_quantity * cs.cs_sales_price, 0)) AS avg_purchas_val,
        count(*) as total_purchases
        dd.d_date AS first_purchase, 
        dd2.d_date AS last_purchase
    FROM 
        customer c 
    JOIN
        web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk 
    JOIN
        store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk 
    JOIN
        catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk 
    JOIN 
        date_dim dd
        ON dd.d_date_sk = c.c_first_sales_date_sk 
    JOIN date_dim dd2 
        ON dd2.d_date_sk = c.c_last_review_date
    GROUP BY 
        c.c_customer_sk
), 
temp_info2 AS  (
    SELECT
        customer_sk AS customer_id,
        avg_purchase_value
        (TIMESTAMPDIFF(MONTH, first_purchase, last_purchase) + 1) AS customer_lifespan,
        total_purchases / (TIMESTAMPDIFF(MONTH, first_purchase, last_purchase) + 1) AS avg_purchase_frequency,
    FROM 
        temp_info
)
SELECT 
    customer_id,
    avg_purchase_value,
    avg_purchase_frequency,
    customer_lifespan,
    (avg_purchase_value * avg_purchase_frequency * customer_lifespan) AS CLTV
FROM 
    temp_info2
ORDER BY 
    CLTV DESC



-- 3. RepeatPurchaseRate: Determine the repeat purchase rate for each customer segment
SELECT * FROM customer_address;
SELECT * FROM customer;

SELECT * FROM web_sales;




WITH web AS (
    SELECT 
        case
            when ca.ca_state in ('AZ', 'NM', 'TX', 'OK') then "SOUTHWEST"
            when ca.ca_state in ( 'CA', 'CO', 'ID', 'MT', 'NV', 'OR', 'UT', 'WA', 'WY', 'AK', 'HI') then "WEST"
            when ca.ca_state in ('ND', 'SD', 'NE', 'KS', 'MN', 'IA', 'MO', 'WI', 'IL', 'IN', 'MI', 'OH') then "MIDWEST"
            when ca.ca_state in ('PA', 'NY', 'NJ', 'CT', 'RI', 'MA', 'VT', 'NH', 'ME', 'DE', 'MD') then "NORTHEAST"
            when ca.ca_state in ('VA', 'WV', 'KY', 'TN', 'NC', 'SC', 'GA', 'FL', 'AL', 'MS', 'LA', 'AR') then "SOUTHEAST"
            else "UNKNOWN"
        end as region, 
        count(*) AS total_no_of_purchase,
        count(DISTINCT(ws.ws_bill_customer_sk)) as no_of_repeated_purchase 
    FROM 
        web_sales ws 
    JOIN   
        customer c  
        ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_address ca 
        ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        region
), 
store AS (
    SELECT 
        case
            when ca.ca_state in ('AZ', 'NM', 'TX', 'OK') then "SOUTHWEST"
            when ca.ca_state in ( 'CA', 'CO', 'ID', 'MT', 'NV', 'OR', 'UT', 'WA', 'WY', 'AK', 'HI') then "WEST"
            when ca.ca_state in ('ND', 'SD', 'NE', 'KS', 'MN', 'IA', 'MO', 'WI', 'IL', 'IN', 'MI', 'OH') then "MIDWEST"
            when ca.ca_state in ('PA', 'NY', 'NJ', 'CT', 'RI', 'MA', 'VT', 'NH', 'ME', 'DE', 'MD') then "NORTHEAST"
            when ca.ca_state in ('VA', 'WV', 'KY', 'TN', 'NC', 'SC', 'GA', 'FL', 'AL', 'MS', 'LA', 'AR') then "SOUTHEAST"
            else "UNKNOWN"
        end as region, 
        count(*) AS total_no_of_purchase,
        count(DISTINCT(ss.ss_customer_sk)) AS no_of_repeated_purchase
    FROM 
        store_sales ss   
    JOIN 
        customer c
        ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_address ca 
        ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        region 
), 
catalog AS (
    SELECT 
        case
            when ca.ca_state in ('AZ', 'NM', 'TX', 'OK') then "SOUTHWEST"
            when ca.ca_state in ( 'CA', 'CO', 'ID', 'MT', 'NV', 'OR', 'UT', 'WA', 'WY', 'AK', 'HI') then "WEST"
            when ca.ca_state in ('ND', 'SD', 'NE', 'KS', 'MN', 'IA', 'MO', 'WI', 'IL', 'IN', 'MI', 'OH') then "MIDWEST"
            when ca.ca_state in ('PA', 'NY', 'NJ', 'CT', 'RI', 'MA', 'VT', 'NH', 'ME', 'DE', 'MD') then "NORTHEAST"
            when ca.ca_state in ('VA', 'WV', 'KY', 'TN', 'NC', 'SC', 'GA', 'FL', 'AL', 'MS', 'LA', 'AR') then "SOUTHEAST"
            else "UNKNOWN"
        end as region, 
        count(*) AS total_no_of_purchase,
        count(DISTINCT(cs.cs_bill_customer_sk)) AS no_of_repeated_purchase
    FROM 
        catalog_sales cs    
    JOIN 
        customer c
        ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN 
        customer_address ca 
        ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        region 
),
result AS (
    SELECT 
        web.region as region, 
        web.no_of_repeated_purchase + catalog.no_of_repeated_purchase + store.no_of_repeated_purchase as no_of_repeated_purchase,
        web.total_no_of_purchase + catalog.total_no_of_purchase + store.total_no_of_purchase as total_no_of_purchase
    FROM 
        web 
    JOIN 
        catalog
        ON catalog.region = web.region
    JOIN 
        store
        ON store.region = web.region
)
SELECT
    region, 
    no_of_repeated_purchase,
    total_no_of_purchase,
    (no_of_repeated_purchase / total_no_of_purchase) * 100 AS repeat_purchase_rate
FROM 
    result;



-- 4. Average Purchase Frequency:  Calculate the average purchase frequency per customer.
SELECT @total_customer := MAX(c_customer_sk) FROM customer;
SELECT @total_customer;


WITH temp AS (
    SELECT 
        ws_bill_customer_sk
    FROM 
        web_sales
    WHERE 
    ws_bill_customer_sk is not null
    UNION ALL
    SELECT 
        ss_customer_sk
    FROM 
        store_sales
    WHERE
    ss_customer_sk is not null
    UNION ALL
    SELECT
        cs_bill_customer_sk
    FROM 
        catalog_sales
    WHERE
    cs_bill_cus  tomer_sk is not null
)
SELECT
    ws_bill_customer_sk as customer_id,
    COALESCE(count(*) / @total_customer * 100, 0) AS avg_purchase_freq
FROM 
    temp
GROUP BY
    ws_bill_customer_sk;


-- 5. Customer Churn Analysis: Identify customers who have not made a purchase in the last year.
-- Last year : 2004
WITH web_cust AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_id
    FROM 
        web_sales ws 
    JOIN 
        date_dim dd 
        ON dd.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        year(dd.d_date) = 2001
),
store_cust AS (
    SELECT
        ss.ss_customer_sk AS customer_id
    FROM 
        store_sales ss 
    JOIN 
        date_dim dd 
        ON dd.d_date_sk = ss.ss_sold_date_sk
    WHERE 
        year(dd.d_date) = 2001
),
catalog_cust AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_id
    FROM 
        catalog_sales cs
    JOIN 
        date_dim dd 
        ON dd.d_date_sk = cs.cs_sold_date_sk
    WHERE 
        year(dd.d_date) = 2001
)
SELECT 
    c_customer_sk
FROM 
    customer
WHERE
    c_customer_sk NOT IN (SELECT customer_id FROM web_cust)
    AND c_customer_sk NOT IN (SELECT customer_id FROM store_cust)
    AND c_customer_sk NOT IN (SELECT customer_id FROM catalog_cust);

-- 6. Top 10 Most Valuable Customers: List the top 10 customers by total spend.


WITH sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(COALESCE(ws_quantity * ws_sales_price, 0)) AS sales
    FROM
        web_sales
    WHERE
        ws_bill_customer_sk IS NOT NULL
    GROUP BY
        ws_bill_customer_sk
    UNION ALL 
    SELECT
        cs_bill_customer_sk,
        SUM(COALESCE(cs_quantity * cs_sales_price, 0)) AS sales 
    FROM 
        catalog_sales
    WHERE
        cs_bill_customer_sk IS NOT NULL
    GROUP BY
        cs_bill_customer_sk
    UNION ALL 
    SELECT
        ss_customer_sk,
        SUM(COALESCE(ss_sales_price * ss_quantity, 0)) AS sales 
    FROM 
        store_sales
    WHERE
        ss_customer_sk IS NOT NULL
    GROUP BY
        ss_customer_sk
)
SELECT
    si.ws_bill_customer_sk,
    COALESCE(CONCAT(c.c_salutation, " ", c.c_first_name, " ", c.c_last_name), "Unknown"),
    si.sales 
FROM 
    customer c
JOIN 
    sales_info si 
    ON si.ws_bill_customer_sk = c.c_customer_sk
ORDER BY 
    si.sales DESC
LIMIT 10;


-- 7. Customer Acquisition by Channel : Analyze how customers are acquired through different sales channels.
 
SELECT * FROM web_sales;


WITH firstPurchase AS (
    SELECT 
        ws_bill_customer_sk,
        ws_sold_date_sk,
        "web" as acquisition_channel
    FROM
        web_sales
    UNION ALL 
    SELECT
        ss_customer_sk,
        ss_sold_date_sk,
        "store" as acquisition_channel
    FROM 
        store_sales
    UNION ALL 
    SELECT
        cs_bill_customer_sk,
        cs_sold_date_sk,
        "catalog" as acquisition_channel
    FROM 
        catalog_sales
),
with_date AS (
    SELECT
        fp.ws_bill_customer_sk as customer_sk,
        fp.acquisition_channel as acquisition_channel,
        dd.d_date as d_date
    FROM
        firstPurchase fp 
    JOIN 
        date_dim dd 
        ON dd.d_date_sk = fp.ws_sold_date_sk
),
earliestPurchase AS (
    SELECT 
        customer_sk,
        MIN(d_date) AS first_purchase_date
    FROM
        with_date 
    GROUP BY
        customer_sk
),
customerAcquisition AS (
    SELECT 
        wd.customer_sk,
        wd.acquisition_channel
    FROM
        with_date wd 
    JOIN
        earliestPurchase ep 
        ON ep.customer_sk = wd.customer_sk  
)
SELECT 
    ca.acquisition_channel,
    COUNT(DISTINCT ca.customer_sk) AS customers_acquired
FROM 
    customerAcquisition ca 
GROUP BY
    ca.acquisition_channel
ORDER BY
    customers_acquired DESC;


-- 8. Customer Satisfaction Analysis: : Correlate customer satisfaction scores with purchase behavior (requires hypothetical satisfaction data).

-- NOT ABLE TO DO