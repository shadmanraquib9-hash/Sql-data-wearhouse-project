/*
Create bronze table
This script creates tables in 'bronze' schema, dropping existing table if already exist
Run script if: redifine the ddl structure of 'bronze' table
*/





drop table if exists silver.crm_cust_info;
Create table silver.crm_cust_info(
cst_id int null,
cst_key varchar(50),
cst_firstname varchar(50),
cst_lastname varchar(50),
cst_marital_status varchar(50),
cst_gndr varchar(50),
cst_create_date varchar(50),
dwh_create_date datetime2 default getdate()
);

drop table if exists silver.crm_prd_info;
Create table silver.crm_prd_info(
prd_id int not null,
cat_id varchar(50),
prd_key varchar(50),
prd_nm varchar(50),
prd_cost int,
prd_line char(50),
prd_start_dt date,
prd_end_dt date,
dwh_create_date datetime2 default getdate()
);

drop table if exists silver.crm_sales_details;
Create table silver.crm_sales_details(
sls_ord_num varchar(50) not null,
sls_prd_key varchar(50),
sls_cust_id int,
sls_order_dt date,
sls_ship_dt date,
sls_due_dt date,
sls_sales int,
sls_quantity int,
sls_price int,
dwh_create_date datetime2 default getdate()
);

drop table if exists silver.erp_CUST_AZ12;
Create table silver.erp_CUST_AZ12(
CID varchar(50),
BDATE DATE,
GEM varchar(10),
dwh_create_date datetime2 default getdate()
);

drop table if exists silver.erp_LOC_A101;
Create table silver.erp_LOC_A101(
CID varchar(50),
CNTRY varchar(50),
dwh_create_date datetime2 default getdate()
);

drop table if exists silver.erp_PX_CAT_G1V2;
Create table silver.erp_PX_CAT_G1V2(
ID varchar(50),
CAT	varchar(50),
SUBCAT varchar(50),
MAINTENANCE varchar(3),
dwh_create_date datetime2 default getdate()
);
