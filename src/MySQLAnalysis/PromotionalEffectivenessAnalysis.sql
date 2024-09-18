use tpcds;
show tables;
-- 1. Promotion Uplift Analysis:  Measure the increase in sales during promotional periods compared to non-promotional periods.
SELECT * FROM promotion;


WITH promo_sales AS (
    SELECT 
        p.p_item_sk as item_sk,
        COALESCE(SUM(ws.ws_quantity * ws.ws_sales_price), 0) as web_sales,
        COALESCE(SUM(ss.ss_quantity * ss.ss_sales_price), 0) as store_sales,
        COALESCE(SUM(cs.cs_quantity * cs.cs_sales_price), 0) as catalog_sales
    FROM
        promotion p
    LEFT JOIN 
        web_sales ws 
        ON ws.ws_item_sk = p.p_item_sk
    LEFT JOIN 
        store_sales ss 
        ON ss.ss_item_sk = p.p_item_sk
    LEFT JOIN 
        catalog_sales cs 
        ON cs.cs_item_sk = p.p_item_sk
    LEFT JOIN 
        date_dim d 
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        date_dim dd1
        ON p.p_start_date_sk = dd1.d_date_sk
    LEFT JOIN 
        date_dim dd2
        ON p.p_end_date_sk = dd2.d_date_sk
    WHERE 
        d.d_date BETWEEN dd1.d_date AND dd2.d_date
    GROUP BY
        p.p_item_sk
),
non_promo_sales AS (
    SELECT 
        p.p_item_sk as item_sk,
        COALESCE(SUM(ws.ws_quantity * ws.ws_sales_price), 0) as web_sales,
        COALESCE(SUM(ss.ss_quantity * ss.ss_sales_price), 0) as store_sales,
        COALESCE(SUM(cs.cs_quantity * cs.cs_sales_price), 0) as catalog_sales
    FROM
        promotion p
    LEFT JOIN 
        web_sales ws 
        ON ws.ws_item_sk = p.p_item_sk
    LEFT JOIN 
        store_sales ss 
        ON ss.ss_item_sk = p.p_item_sk
    LEFT JOIN 
        catalog_sales cs 
        ON cs.cs_item_sk = p.p_item_sk
    LEFT JOIN 
        date_dim d 
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        ws.ws_sold_date_sk NOT BETWEEN p.p_start_date_sk AND p.p_end_date_sk
        AND ss.ss_sold_date_sk NOT BETWEEN p.p_start_date_sk AND p.p_end_date_sk
        AND cs.cs_sold_date_sk NOT BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    GROUP BY
        p.p_item_sk
)
SELECT 
    ps.item_sk as item_sk,
    (ps.web_sales + ps.store_sales + ps.catalog_sales) AS promotion_sales,
    (nps.web_sales + nps.store_sales + nps.catalog_sales) AS non_promotional_sales,
    CASE 
        WHEN (nps.web_sales + nps.store_sales + nps.catalog_sales) > 0 
            THEN ((ps.web_sales + ps.store_sales + ps.catalog_sales) 
                  - (nps.web_sales + nps.store_sales + nps.catalog_sales)) 
                  / (nps.web_sales + nps.store_sales + nps.catalog_sales) * 100
        ELSE NULL
    END AS sales_uplift_percentage
FROM 
    promo_sales ps
LEFT JOIN 
    non_promo_sales nps
    ON ps.item_sk = nps.item_sk;


-- 2. ROI of Promotional Campaigns: Calculate the return on investment (ROI) for each promotional campaign.
-- ROI = Net Revenue from Promotion−Promotion Cost / Promotion Cost ×100 
WITH
    promo_web_sales AS (
        SELECT 
            p.p_promo_id,
            p.p_cost,
            SUM(ws.ws_quantity * ws.ws_sales_price) AS total_sales_promo
        FROM web_sales ws
        JOIN promotion p
            ON ws.ws_item_sk = p.p_item_sk
            AND ws.ws_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
        GROUP BY p.p_promo_id, p.p_cost
    ),
    promo_catalog_sales AS (
        SELECT 
            p.p_promo_id,
            SUM(cs.cs_quantity * cs.cs_sales_price) AS total_sales_promo
        FROM catalog_sales cs
        JOIN promotion p
            ON cs.cs_item_sk = p.p_item_sk
            AND cs.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
        GROUP BY p.p_promo_id
    ),
    promo_store_sales AS (
        SELECT 
            p.p_promo_id,
            SUM(ss.ss_quantity * ss.ss_sales_price) AS total_sales_promo
        FROM store_sales ss
        JOIN promotion p
            ON ss.ss_item_sk = p.p_item_sk
            AND ss.ss_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
        GROUP BY p.p_promo_id
    ),
    promo_sales AS (
        SELECT 
            pws.p_promo_id,
            pws.p_cost,
            (COALESCE(pws.total_sales_promo, 0) +
             COALESCE(pcs.total_sales_promo, 0) +
             COALESCE(pss.total_sales_promo, 0)) AS total_sales_promo
        FROM promo_web_sales pws
        LEFT JOIN promo_catalog_sales pcs ON pws.p_promo_id = pcs.p_promo_id
        LEFT JOIN promo_store_sales pss ON pws.p_promo_id = pss.p_promo_id
    ),
    
    non_promo_web_sales AS (
        SELECT 
            ws.ws_item_sk,
            AVG(ws.ws_quantity * ws.ws_sales_price) AS avg_daily_sales_non_promo
        FROM web_sales ws
        LEFT JOIN promotion p
            ON ws.ws_item_sk = p.p_item_sk
            AND ws.ws_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
        WHERE p.p_item_sk IS NULL  
        GROUP BY ws.ws_item_sk
    ),
    non_promo_catalog_sales AS (
        SELECT 
            cs.cs_item_sk,
            AVG(cs.cs_quantity * cs.cs_sales_price) AS avg_daily_sales_non_promo
        FROM catalog_sales cs
        LEFT JOIN promotion p
            ON cs.cs_item_sk = p.p_item_sk
            AND cs.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
        WHERE p.p_item_sk IS NULL  
        GROUP BY cs.cs_item_sk
    ),
    non_promo_store_sales AS (
        SELECT 
            ss.ss_item_sk,
            AVG(ss.ss_quantity * ss.ss_sales_price) AS avg_daily_sales_non_promo
        FROM store_sales ss
        LEFT JOIN promotion p
            ON ss.ss_item_sk = p.p_item_sk
            AND ss.ss_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
        WHERE p.p_item_sk IS NULL  
        GROUP BY ss.ss_item_sk
    ),
    expected_non_promo_sales AS (
        SELECT
            p.p_promo_id,
            SUM(COALESCE(npws.avg_daily_sales_non_promo, 0) * (p.p_end_date_sk - p.p_start_date_sk + 1) +
                COALESCE(npcs.avg_daily_sales_non_promo, 0) * (p.p_end_date_sk - p.p_start_date_sk + 1) +
                COALESCE(npss.avg_daily_sales_non_promo, 0) * (p.p_end_date_sk - p.p_start_date_sk + 1)) AS expected_sales_non_promo
        FROM promotion p
        LEFT JOIN non_promo_web_sales npws ON p.p_item_sk = npws.ws_item_sk
        LEFT JOIN non_promo_catalog_sales npcs ON p.p_item_sk = npcs.cs_item_sk
        LEFT JOIN non_promo_store_sales npss ON p.p_item_sk = npss.ss_item_sk
        GROUP BY p.p_promo_id
    )
SELECT
    ps.p_promo_id,
    ps.total_sales_promo,
    enps.expected_sales_non_promo,
    ps.p_cost,
    (ps.total_sales_promo - enps.expected_sales_non_promo) AS net_revenue_from_promo,
    CASE 
        WHEN ps.p_cost > 0 
            THEN ((ps.total_sales_promo - enps.expected_sales_non_promo) - ps.p_cost) / ps.p_cost * 100
        ELSE NULL
    END AS roi_percentage
FROM 
    promo_sales ps
JOIN 
    expected_non_promo_sales enps
    ON ps.p_promo_id = enps.p_promo_id;


