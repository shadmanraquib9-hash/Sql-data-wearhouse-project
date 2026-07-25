/*
DDL Script: Create Gold Views

Script Purpose:

This script creates views for the Gold layer in the data warehouse. 
The Gold layer represents the final dimension and fact tables (Star Schema)

Each view performs transformations and combines data from the Silver layer 
to produce a clean, enriched, and business-ready dataset.

Usage:
  This views can be queried directly for analytics and reporting.

*/

--Create Gold.dim_customers
Create view Gold.dim_customers as
select
       ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key
       ,ci.cst_id as Customer_id
      ,ci.cst_key as Customer_number
      ,ci.cst_firstname as First_name
      ,ci.cst_lastname as Last_name
      ,la.CNTRY as Country
      ,ci.cst_marital_status as marital_status
      ,case when ci.cst_gndr !='unknown' then ci.cst_gndr
      when ci.cst_gndr ='unknown' and ca.gem !='N/A' and ca.gem is not null then ca.gem
      else 'unknown'
      end as Gender
      ,ca.BDATE as Brithdate
      ,cst_create_date as Create_Date
from Silver.crm_cust_info ci
left join Silver.erp_CUST_AZ12 ca
on ci.cst_key= ca.cid
left join Silver.erp_LOC_A101 la
on ci.cst_key= la.cid



--Create Gold.dim_products
CREATE OR ALTER VIEW Gold.dim_products AS
SELECT ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt,pn.prd_key ) AS product_key 
      ,pn.prd_id as product_id
      ,pn.prd_key as product_number
      ,pn.prd_nm as product_name
      ,pn.cat_id as category_id
      ,pc.CAT as category
      ,pc.SUBCAT as subcategory
      ,pc.MAINTENANCE
      ,pn.prd_cost as product_cost
      ,pn.prd_line as product_line
      ,pn.prd_start_dt as start_date
  FROM Silver.crm_prd_info pn
  left join silver.erp_PX_CAT_G1V2 pc
  on pn.cat_id=pc.ID
  where prd_end_dt is null --filter all the historical data


--Create Gold.fact_sales
Create view Gold.fact_sales as
SELECT  sd.sls_ord_num as order_number
      ,pr.product_number
      ,cu.Customer_id
      ,sd.sls_order_dt as order_date
      ,sd.sls_ship_dt as ship_date
      ,sd.sls_due_dt as due_date
      ,sd.sls_sales as sales_amount
      ,sd.sls_quantity as quantity
      ,sd.sls_price
  FROM Silver.crm_sales_details sd
  left join Gold.dim_products pr
  on sd.sls_prd_key=pr.product_number
  left join Gold.dim_customers cu
  on sd.sls_cust_id=cu.Customer_id

