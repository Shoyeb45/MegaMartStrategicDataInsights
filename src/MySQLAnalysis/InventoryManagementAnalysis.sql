use tpcds;
show tables;


-- 1. Inventory Turnover Ratio:  Calculate the inventory turnover ratio for each product category.
-- Inventory Turnover Ration = Costs Of Goods sold / average inventory
-- average inventory = (beginning inventory + ending inventory) / 2
select * from inventory;
select * from item;
select * from web_sales;

select 
	i.i_category_id, 
    sum(coalesce(ws.ws_quantity * ws.ws_sales_price, 0) + coalesce(cs.cs_quantity * cs.cs_sales_price, 0) + coalesce(ss.ss_quantity * ss.ss_sales_price, 0)) as sales,
    avg(coalesce(inv.inv_quantity_on_hand, 0)) as avg_inventory,
	(sum(coalesce(ws.ws_quantity * ws.ws_sales_price, 0) + coalesce(cs.cs_quantity * cs.cs_sales_price, 0) + coalesce(ss.ss_quantity * ss.ss_sales_price, 0)) / avg(coalesce(inv.inv_quantity_on_hand, 0))) as inventory_turover_ratio
from 
	item i
left join 
	web_sales ws on ws.ws_item_sk = i.i_item_sk
left join 
	store_sales ss on ss.ss_item_sk = i.i_item_sk
left join 
	catalog_sales cs on cs.cs_item_sk = i.i_item_sk
left join 
	inventory inv on inv.inv_item_sk = i.i_item_sk
group by 
	i.i_category_id
limit 5;



-- 2. Stockout Rate by Product: : Identify the products with the highest stockout rates in the past month.
-- Last date is : 2002-12-26, so So we have to check for month December. (so from 2002-12-01 to 2002-12-31)
select * from item;
select * from inventory;
select * from date_dim;

with stockout as (
	select 
		inv.inv_item_sk as itemId, 
		count(*) as stokoutDays
	from 
		inventory inv
	left join 
		date_dim dd 
		on dd.d_date_sk = inv.inv_date_sk
	where
		dd.d_date between '2002-12-01' and '2002-12-31' and
		inv.inv_quantity_on_hand = 0
	group by 
		inv.inv_item_sk
), 
totalDays as (
	select 
		inv.inv_item_sk itemId, count(distinct inv.inv_date_sk) as totalDays
	from 
		inventory inv
	left join 
		date_dim dd 
		on dd.d_date_sk = inv.inv_date_sk
	where
		dd.d_date between '2002-12-01' and '2002-12-31'
	group by 
		inv.inv_item_sk
)
select 
	ii.i_item_sk,
	coalesce(sk.stokoutDays, 0) as stockoutDays,
	coalesce(td.totalDays, 0) as totalDays,
	(COALESCE(sk.stokoutDays, 0) / COALESCE(td.totalDays, 1)) * 100 AS stockoutRate
from 
	item ii 
left join
	stockout sk 
	on sk.itemId = ii.i_item_sk
left join 
	totalDays td 
	on td.itemId = ii.i_item_sk;



-- 3. . Days of Inventory on Hand: Calculate the average days of inventory on hand for each product category.

select
	i.i_category as category, avg(coalesce(inv.inv_quantity_on_hand, 0)) as averageDayOfInventoryOnHand
from
	inventory inv 
left join 
	item i 
	on i.i_item_sk = inv.inv_item_sk
group by  
	i.i_category;


-- 4. Top 10 Overstocked Products: Determine the replenishment frequency for high-demand products

-- NOT ABLE TO SOLVE 


-- 5. Inventory Aging Analysis: Analyze the aging of inventory to identify slow-moving products.

-- NOT ABLE TO SOLVE 


-- 6.  Warehouse Inventory Levels: Monitor the current inventory levels across all warehouses.

-- NOT ABLE TO SOLVE 