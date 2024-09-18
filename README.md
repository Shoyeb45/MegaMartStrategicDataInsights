# <p align=center>Mega Mart Data Analysis Project</p>

## About Data and Project 

- This analysis project is about a dataset called <b>'tpcds'</b>. 

### About tpcds database:
> The 10 TB (scale factor 10,000) version represents <b>65 million customers</b> and over 400,000 items stored, with sales data spanning 3 channels — stores, catalogs, and the web — covering a period of 5 years. The largest table, STORE_SALES, contains nearly <b>29 billion rows</b>, and the fact tables contain over <b>56 billion rows</b> in total.


- We have various KPI's related to the 'Mega Mart', and we need to analyse each and every KPI using SQL in MySQL and build a report in Power BI.
- I analysed the data using SQL in MySQL in VSCODE extension called 'Database Client'.
- Then for dashboard, I imported data in power BI using MySQL connector and by providing credentials.
- Majorly I have used `Joins`, `CTE`, `Order By`, `Group By`, `where` and `Union` for MySQL analysis.
- In power BI, I have created charts by using `DAX Expressions` and using `Power Query` for furthur transformations.

### Connecting Database
- We can connect to this database by entering following credentials in respective server:
1. <b>hostname</b>: db.relational-data.org
2. <b>port</b>: 3306
3. <b>username</b>: guest
4. <b>password</b>: relational

<p align=center>
    <img src="./public/image/connectDB.png" width=550px><br>
    <i>Connecting server in VS CODE</i>
</p>

## 1. Executive Summary

This report presents a comprehensive analysis of sales and promotional data across multiple channels (web, catalog, and store) based on the this database. The important points are as follows:

### 1. Sales Performance Across Channels:
- Store Sales has  highest sales , followed by web sales, with catalog sales trailing behind.

- Despite a higher volume of store sales, web sales have been growing steadily year over year, indicating a shift in customer behavior toward online.

### 2. Promotion Effectiveness:
- Promotional campaigns resulted in an average sales uplift of 15-20% across channels, with the most significant impact observed in web sales.

- However, certain promotions showed negligible returns, particularly in the catalog segment, suggesting a need for channel-specific promotion strategies.

### 3. Customer Behaviour:
- A small percentage of customers (approximately 10%) contribute to over 50% of the total revenue, indicating a strong dependence on high-value customers.
- Repeat customers were found to be significantly more responsive to promotional campaigns than first-time buyers, particularly in the web channel.

### 4. Product Performance:
- Top-performing products contributed to a disproportionate share of sales, with the top 20% of products generating nearly 80% of revenue, in line with the Pareto Principle.

- Discounted items under promotion experienced significant sales spikes, though some items showed little or no improvement, suggesting ineffective targeting or poor product-market fit.