use tpcds;
show tables;	

-- 1. Total Sales by Product Category - Calculate the total sales revenue for each product category across all
-- channels.

select * from store_sales limit 5;
select * from web_sales limit 5;
select * from item limit 5;
select distinct i_category from item;

-- Main Query 
select i_category as Category, sum(sales) as sales
from (select i.i_category, st.sales 
	from (select ws.ws_item_sk, sum(ws.ws_quantity * ws.ws_sales_price + ss.ss_quantity * ss.ss_sales_price) as sales
			from store_sales ss
			join web_sales ws on ws.ws_item_sk = ss.ss_item_sk 
			group by ws.ws_item_sk) 
        as st
	join item i on i.i_item_sk = st.ws_item_sk) 
as t
group by i_category;


-- 2. Sales Trend Over Time : Analyze monthly sales trends for the past two years.
show tables;
select distinct(d_year) from date_dim ;


select date,  sum(sales) as sales
from
	(select concat(monthname(dd.d_date), ", ", year(dd.d_date)) as date, sales_t.sales as sales
	from
		(select ws.ws_sold_date_sk as date, sum(ws.ws_quantity * ws.ws_sales_price + ss.ss_quantity * ss.ss_sales_price) as sales
		from store_sales ss 
		join web_sales ws on ws.ws_sold_date_sk = ss.ss_sold_date_sk 
		group by ws.ws_sold_date_sk) as sales_t
	join date_dim dd on dd.d_date_sk = sales_t.date
    where year(dd.d_date) = 2100 or year(dd.d_date) = 2099) t
group by date;


