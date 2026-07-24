
USE [Data_warehouse]
GO
/****** Object:  Aulter Table [Silver].[load_bronze]    Script Date: 24/07/2026 9:57:22 PM ******/

Create or alter procedure Silver.load_silver as 
begin

declare @start_time	 datetime, @end_time datetime, @batch_start_time	 datetime, @batch_end_time datetime;
begin try
set @batch_start_time= GETDATE();
print'============================================'
print'loading silver layer'
print'============================================'


--loading silver.crm_cust_info
print'============================================'
print'loading CRM section'
print'============================================'
    Print '>> trancateing table: Silver.crm_cust_info';
    truncate table Silver.crm_cust_info;
    Print'>> Inserting Data into: Silver.crm_cust_info';
    set @start_time=getdate();

    insert into Silver.crm_cust_info (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
    )

    select 
    cst_id,
    cst_key,
    trim(cst_firstname) as cst_firstname, 
    trim(cst_lastname) as cst_lastname,
    case 
	    when upper(cst_marital_status) ='S' then 'Single'
	    when upper(cst_marital_status) ='M' then 'Married'
	    else 'unknown'
    end cst_marital_status,  ---Data Normalization of marrage state
    case 
	    when upper(cst_gndr) ='F' then 'Female'
	    when upper(cst_gndr) ='M' then 'Male'
	    else 'unknown'
    end cst_gndr,      ---Data Normalization of gender
    cst_create_date
    from (
    select * , 
    ROW_NUMBER() over (partition by cst_id order by cst_create_date desc) as flag_last
    from Bronze.crm_cust_info 
    where cst_id is not null)t where flag_last=1

    set @end_time=getdate();
    print'>> load duration '+ cast(datediff(second,@start_time,@end_time) as nvarchar) +' seconds';
    print'----------------------------------';


--loading silver.crm_prd_info
    Print '>> trancateing table: silver.crm_prd_info';
    truncate table silver.crm_prd_info;
    Print'>> Inserting Data into: silver.crm_prd_info';
    set @start_time=getdate();

    insert into silver.crm_prd_info(
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
    )

    SELECT [prd_id]
          ,replace(SUBSTRING(prd_key,1,5),'-','_') as cat_id
          ,SUBSTRING(prd_key,7,len(prd_key)) as prd_key
          ,[prd_nm]
          ,ISNULL(prd_cost,0) as prd_cost
          ,case upper(trim(prd_line))
            when 'M' then 'Mountain'
            when 'R' then 'Road'
            when 'S' then 'other Sales'
            when 'T' then 'Touring'
            else 'N/A'
            end as [prd_line]
          ,[prd_start_dt]
          ,dateadd(day, -1, lead(prd_start_dt) over (partition by prd_key order by prd_start_dt)) as prd_end_dt_tes
      FROM [Data_warehouse].[Bronze].[crm_prd_info]

      set @end_time=getdate();
    print'>> load duration '+ cast(datediff(second,@start_time,@end_time) as nvarchar) +' seconds';
    print'----------------------------------';


--loading silver.crm_sales_details
    Print '>> trancateing table: silver.crm_sales_details';
    truncate table silver.crm_sales_details;
    Print'>> Inserting Data into: silver.crm_sales_details';
    set @start_time=getdate();


    insert into silver.crm_sales_details(
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
    )

    SELECT [sls_ord_num]
          ,[sls_prd_key]
          ,[sls_cust_id]
          ,case when sls_order_dt=0  or len(sls_order_dt)!=8 then null
            else cast(cast(sls_order_dt as nvarchar)as date)
            end as sls_order_dt
          ,case when sls_ship_dt=0  or len(sls_ship_dt)!=8 then null
            else cast(cast(sls_ship_dt as nvarchar)as date)
            end as sls_ship_dt
           ,case when sls_due_dt=0  or len(sls_due_dt)!=8 then null
            else cast(cast(sls_due_dt as nvarchar)as date)
            end as sls_due_dt
           ,case when sls_sales<=0 or sls_sales is null or sls_sales!= sls_quantity*abs(sls_price) then sls_quantity*sls_price
          else abs(sls_sales)
          end sls_sales
           ,case when sls_quantity is null or sls_quantity<=0
          then sls_sales/sls_price
          else sls_quantity
          end sls_quantity
          ,case when sls_price is null or sls_price<=0 
          then sls_sales/nullif(sls_quantity,0)
          else sls_price
          end sls_price
      FROM [Data_warehouse].[Bronze].[crm_sales_details]

    set @end_time=getdate();
    print'>> load duration '+ cast(datediff(second,@start_time,@end_time) as nvarchar) +' seconds';
    print'----------------------------------';


    print'============================================'
    print'loading ERP section'
    print'============================================'

--loading silver.erp_CUST_AZ12
    Print '>> trancateing table: silver.erp_CUST_AZ12';
    truncate table silver.erp_CUST_AZ12;
    Print'>> Inserting Data into: silver.erp_CUST_AZ12';
    set @start_time=getdate();

    insert into silver.erp_CUST_AZ12(
    cid, bdate, gem
    )
    select case when cid like 'NAS%' then SUBSTRING(cid,4,len(cid))
    else cid
    end as cid
    , case when BDATE >GETDATE() then null
    else BDATE
    end bdate
    , case when upper(trim(gem)) in ('F','FEMALE') then 'Female'
    when upper(trim(gem)) in ('M','MALE') then 'Male'
    else 'N/A'
    end as gem
    from [Bronze].[erp_CUST_AZ12]

    set @end_time=getdate();
    print'>> load duration '+ cast(datediff(second,@start_time,@end_time) as nvarchar) +' seconds';
    print'----------------------------------';

--loading silver.erp_LOC_A101
    Print '>> trancateing table: silver.erp_LOC_A101';
    truncate table silver.erp_LOC_A101;
    Print'>> Inserting Data into: silver.erp_LOC_A101';
    set @start_time=getdate();

    insert into silver.erp_LOC_A101(
    cid, cntry
    )


    SELECT REPLACE(cid,'-','') cid
          , case when trim(CNTRY) = 'DE' then 'Germany'
          when trim(cntry) in ('US','USA') then 'United States'
          when trim(cntry)='' or CNTRY is null then 'N/A'
          else CNTRY
          end cntry
      FROM [Data_warehouse].[Bronze].[erp_LOC_A101]

    set @end_time=getdate();
    print'>> load duration '+ cast(datediff(second,@start_time,@end_time) as nvarchar) +' seconds';
    print'----------------------------------';

--loading silver.erp_PX_CAT_G1V2
    Print '>> trancateing table: silver.erp_PX_CAT_G1V2';
    truncate table silver.erp_PX_CAT_G1V2;
    Print'>> Inserting Data into: silver.erp_PX_CAT_G1V2';
    set @start_time=getdate();

    insert into silver.erp_PX_CAT_G1V2(
    ID,
    CAT,
    SUBCAT,
    MAINTENANCE
    )

    SELECT TOP (1000) [ID]
          ,[CAT]
          ,[SUBCAT]
          ,[MAINTENANCE]
      FROM [Data_warehouse].[Bronze].[erp_PX_CAT_G1V2]

    set @end_time=getdate();
    print'>> load duration '+ cast(datediff(second,@start_time,@end_time) as nvarchar) +' seconds';
    print'----------------------------------';



set @batch_end_time=GETDATE();
print'>> load bronze layer competer: '+ cast(datediff(second,@batch_start_time,@batch_end_time) as nvarchar) +' seconds';
print'======================================';

end try
begin catch 
    THROW;
end catch
END
