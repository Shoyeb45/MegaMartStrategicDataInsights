use tpcds;

show tables;

-- 1. Total Sales by Product Category - Calculate the total sales revenue for each product category across all
-- channels.

select * from store_sales limit 5;

select * from web_sales limit 5;

select * from catalog_sales limit 5;

select * from item limit 5;

select distinct i_category from item;

-- Main Query
select i_category as Category, sum(sales) as sales
from (
        select i.i_category, st.sales
        from (
                select ws.ws_item_sk, sum(
                        ws.ws_quantity * ws.ws_sales_price + ss.ss_quantity * ss.ss_sales_price + cs.cs_quantity * cs.cs_sales_price
                    ) as sales
                from
                    store_sales ss
                    join web_sales ws on ws.ws_item_sk = ss.ss_item_sk
                    join catalog_sales cs on ws.ws_item_Sk = cs.cs_item_sk
                group by
                    ws.ws_item_sk
            ) as st
            join item i on i.i_item_sk = st.ws_item_sk
    ) as t
group by
    i_category;




-- 2. Sales Trend Over Time : Analyze monthly sales trends for the past two years.
show tables;

select distinct (d_year) from date_dim;

-- Main Query
select date, sum(sales) as sales
from (
        select concat(
                monthname(dd.d_date), ", ", year(dd.d_date)
            ) as date, sales_t.sales as sales
        from (
                select ws.ws_sold_date_sk as date, sum(
                        ws.ws_quantity * ws.ws_sales_price + ss.ss_quantity * ss.ss_sales_price + cs.cs_quantity * cs.cs_sales_price
                    ) as sales
                from
                    store_sales ss
                    join web_sales ws on ws.ws_sold_date_sk = ss.ss_sold_date_sk
                    join catalog_sales cs on ws.ws_sold_date_sk = cs.cs_sold_date_sk
                group by
                    ws.ws_sold_date_sk
            ) as sales_t
            join date_dim dd on dd.d_date_sk = sales_t.date
        where
            year(dd.d_date) = 2004
            or year(dd.d_date) = 2003
    ) t
group by
    date;



-- 3. Top 10 Best-Selling Products: Identify the top 10 best-selling products by total revenue
select * from item limit 5;


-- Main Query
select
    i.i_item_sk as product_id,
    i.i_product_name as product_name,
    i.i_manufact as manufacturer,
    t.sales
from (
        select ws.ws_item_sk as item_sk, sum(
                ws.ws_quantity * ws.ws_sales_price + ss.ss_quantity * ss.ss_sales_price + cs.cs_quantity * cs.cs_sales_price
            ) as sales
        from
            web_sales ws
            join catalog_sales cs on ws.ws_item_sk = cs.cs_item_sk
            join store_sales ss on ws.ws_item_sk = ss.ss_item_sk
        group by
            ws.ws_item_sk
        order by sales desc
        limit 10
    ) t
    join item i on i.i_item_sk = t.item_sk;




-- 4. Sales by Region: Calculate the total sales revenue by region for each sales channel.

select * from web_sales limit 4;

select * from store_sales limit 4;

select * from catalog_sales limit 4;

select * from customer_address order by ca_address_sk desc limit 5;


-- Main Query
select nt.region as region, sum(sales)
from (
        select
            case
                when ca.ca_state in ('AZ', 'NM', 'TX', 'OK') then "SOUTHWEST"
                when ca.ca_state in (
                    'CA', 'CO', 'ID', 'MT', 'NV', 'OR', 'UT', 'WA', 'WY', 'AK', 'HI'
                ) then "WEST"
                when ca.ca_state in (
                    'ND', 'SD', 'NE', 'KS', 'MN', 'IA', 'MO', 'WI', 'IL', 'IN', 'MI', 'OH'
                ) then "MIDWEST"
                when ca.ca_state in (
                    'PA', 'NY', 'NJ', 'CT', 'RI', 'MA', 'VT', 'NH', 'ME', 'DE', 'MD'
                ) then "NORTHEAST"
                when ca.ca_state in (
                    'VA', 'WV', 'KY', 'TN', 'NC', 'SC', 'GA', 'FL', 'AL', 'MS', 'LA', 'AR'
                ) then "SOUTHEAST"
                else "UNKNOWN"
            end as region, t.sales as sales
        from (
                select ws.ws_bill_customer_sk as customer_add_id, sum(
                        ws.ws_quantity * ws.ws_sales_price + ss.ss_quantity * ss.ss_sales_price + cs.cs_quantity * cs.cs_sales_price
                    ) as sales
                from
                    web_sales ws
                    join store_sales ss on ws.ws_bill_customer_sk = ss.ss_customer_sk
                    join catalog_sales cs on ws.ws_bill_customer_sk = cs.cs_bill_customer_sk
                group by
                    ws.ws_bill_customer_sk
            ) t
            join customer_address ca on ca.ca_address_sk = t.customer_add_id
    ) nt
group by
    nt.region;



-- 5.  Year-over-Year Sales Growth: Compare the year-over-year sales growth for the current and previous year.

select * from date_dim limit 3;

-- Main query
WITH
    sales_data AS (
        SELECT YEAR(dd.d_date) AS year, SUM(
                ws.ws_quantity * ws.ws_sales_price + ss.ss_quantity * ss.ss_sales_price + cs.cs_quantity * cs.cs_sales_price
            ) AS sales
        FROM
            web_sales ws
            JOIN store_sales ss ON ws.ws_sold_date_sk = ss.ss_sold_date_sk
            JOIN catalog_sales cs ON ws.ws_sold_date_sk = cs.cs_sold_date_sk
            JOIN date_dim dd ON dd.d_date_sk = ws.ws_sold_date_sk
        GROUP BY
            YEAR(dd.d_date)
    )
SELECT
    curr.year AS curr_year,
    curr.sales AS curr_sales,
    prev.year AS prev_year,
    prev.sales AS prev_sales,
    (
        (curr.sales - prev.sales) / prev.sales
    ) * 100 AS yoy_change
FROM
    sales_data curr
    LEFT JOIN sales_data prev ON curr.year = prev.year + 1
ORDER BY curr.year;




-- 6. Sales Contribution by Channel: Determine the contribution of each sales channel (store, catalog, online) to the
-- overall sales.
select * from web_sales limit 4;

select @webSales := round(
        sum(ws_quantity * ws_sales_price), 2
    )
from web_sales;

select @storeSales := round(
        sum(ss_quantity * ss_sales_price), 2
    )
from store_sales;

select @catalogSales := round(
        sum(cs_quantity * cs_sales_price), 2
    )
from catalog_sales;

select "Website" as channel, round(@webSales, 2) as Sales
union all
select "Store", round(@storeSales, 2)
union all
select "Catalog", round(@catalogSales, 2)
union all
select "Total", round(
        @webSales + @storeSales + @catalogSales, 2
    );




-- 7. Sales Performance of New Products: Analyze the sales performance of products introduced in the last 6 months
select * from item order by i_rec_start_date asc;

select * from web_sales;

select
    item.i_item_sk,
    item.i_rec_start_date,
    sum(
        coalesce(
            ws.ws_quantity * ws.ws_sales_price,
            0
        )
    ) as web_sales,
    sum(
        coalesce(
            ss.ss_quantity * ss.ss_sales_price,
            0
        )
    ) as store_sales,
    sum(
        coalesce(
            cs.cs_quantity * cs.cs_sales_price,
            0
        )
    ) as catalog_sales,
    sum(
        coalesce(
            ws.ws_quantity * ws.ws_sales_price + ss.ss_quantity * ss.ss_sales_price + cs.cs_quantity * cs.cs_sales_price,
            0
        )
    ) as total_sales
from
    item
    left join web_sales ws on ws.ws_item_sk = item.i_item_sk
    left join store_sales ss on ss.ss_item_sk = item.i_item_sk
    left join catalog_sales cs on cs.cs_item_sk = item.i_item_sk
where
    i_rec_start_date >= "2001-10-27"
group by
    item.i_item_sk;




-- 8. Average Order Value: : Calculate the average order value for each sales channel
select * from catalog_sales limit 5;

select
    "WebSales" as channel,
    sum(ws_quantity * ws_sales_price) / count(distinct (ws_order_number)) as averageOrderValue
from web_sales
union all
select
    "StoreSales" as channel,
    sum(ss_quantity * ss_sales_price) / count(distinct (ss_ticket_number)) as averageOrderValue
from store_sales
union all
select
    "CatalogSales" as channel,
    sum(cs_quantity * cs_sales_price) / count(distinct (cs_order_number)) as averageOrderValue
from catalog_sales;



-- 9. Seasonal Sales Analysis: : Identify seasonal sales patterns by comparing sales during different quarters of the year

select year(dd.d_date) as year, quarter(dd.d_date) as Quarter, sum(
        ws.ws_quantity * ws.ws_sales_price + ss.ss_quantity * ss.ss_sales_price + cs.cs_quantity * cs.cs_sales_price
    ) as total_sales
from
    date_dim dd
    join web_sales ws on dd.d_date_sk = ws.ws_sold_date_sk
    join store_sales ss on ss.ss_sold_date_sk = dd.d_date_Sk
    join catalog_sales cs on cs.cs_sold_date_sk = dd.d_date_Sk
group by
    dd.d_date_sk;




-- 10. Product Category Sales Distribution: Determine the sales distribution across different product categories

select
    i_category as category,
    sum(
        coalesce(
            ws.ws_quantity * ws.ws_sales_price + ss.ss_quantity * ss.ss_sales_price + cs.cs_quantity * cs.cs_sales_price,
            0
        )
    ) as totalSales
from
    item i
    left join web_sales as ws on ws.ws_item_sk = i.i_item_sk
    left join store_sales as ss on ss.ss_item_sk = i.i_item_sk
    left join catalog_sales as cs on cs.cs_item_sk = i.i_item_sk
group by
    i.i_category;