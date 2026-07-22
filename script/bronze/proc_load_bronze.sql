/*
Load bronze layers:
This loads data into the 'bronze' scheam from external CSV files.
does the following actions:
Truncate bronze tables before loading data
Uses the 'bulk insert' to load all the data from the csv files to bronze files

*/


create or alter procedure bronze.load_bronze as 
begin
declare @start_time	 datetime, @end_time datetime, @batch_start_time	 datetime, @batch_end_time datetime;
begin try
set @batch_start_time= GETDATE();
print'============================================'
print'loading bronze layer'
print'============================================'



print'============================================'
print'loading CRM section'
print'============================================'
set @start_time=getdate();
TRUNCATE TABLE Bronze.crm_cust_info;
bulk insert Bronze.crm_cust_info
from 'C:\Users\shadm\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
with
(
	firstrow=2,
	fieldterminator=',',
	rowterminator= '\n',
	tablock
);
set @end_time=getdate();
print'>> load duration '+ cast(datediff(second,@start_time,@end_time) as nvarchar) +' seconds';
print'----------------------------------';

set @start_time=getdate();
TRUNCATE TABLE Bronze.crm_prd_info;
bulk insert Bronze.crm_prd_info
from 'C:\Users\shadm\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
with
(
	firstrow=2,
	fieldterminator=',',
	rowterminator= '\n',
	tablock
);
set @end_time=getdate();
print'>> load duration '+ cast(datediff(second,@start_time,@end_time) as nvarchar) +' seconds';
print'----------------------------------';

set @start_time=getdate();
TRUNCATE TABLE Bronze.crm_sales_details;
bulk insert Bronze.crm_sales_details
from 'C:\Users\shadm\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
with
(
	firstrow=2,
	fieldterminator=',',
	rowterminator= '\n',
	tablock
);
set @end_time=getdate();
print'>> load duration '+ cast(datediff(second,@start_time,@end_time) as nvarchar) +' seconds';
print'----------------------------------';


print'============================================'
print'loading ERP section'
print'============================================'


set @start_time=getdate();
TRUNCATE TABLE Bronze.erp_CUST_AZ12;
bulk insert Bronze.erp_CUST_AZ12
from 'C:\Users\shadm\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
with
(
	firstrow=2,
	fieldterminator=',',
	rowterminator= '\n',
	tablock
);
set @end_time=getdate();
print'>> load duration '+ cast(datediff(second,@start_time,@end_time) as nvarchar) +' seconds';
print'----------------------------------';

set @start_time=getdate();
TRUNCATE TABLE Bronze.erp_LOC_A101;
bulk insert Bronze.erp_LOC_A101
from 'C:\Users\shadm\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
with
(
	firstrow=2,
	fieldterminator=',',
	rowterminator= '\n',
	tablock
);
set @end_time=getdate();
print'>> load duration '+ cast(datediff(second,@start_time,@end_time) as nvarchar) +' seconds';
print'----------------------------------';

set @start_time=getdate();
TRUNCATE TABLE Bronze.erp_PX_CAT_G1V2;
bulk insert Bronze.erp_PX_CAT_G1V2
from 'C:\Users\shadm\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
with
(
	firstrow=2,
	fieldterminator=',',
	rowterminator= '\n',
	tablock
);


set @end_time=getdate();
print'>> load duration '+ cast(datediff(second,@start_time,@end_time) as nvarchar) +' seconds';
print'----------------------------------';

set @batch_end_time=GETDATE();
print'>> load bronze layer competer: '+ cast(datediff(second,@batch_start_time,@batch_end_time) as nvarchar) +' seconds';
print'======================================';


end try
begin catch 
end catch
END
GO

--select count(*) from Bronze.crm_cust_info
--select count(*) from Bronze.crm_prd_info
--select count(*) from Bronze.crm_sales_details
--select count(*) from Bronze.erp_CUST_AZ12	
--select count(*) from Bronze.erp_LOC_A101
--select count(*) from Bronze.erp_PX_CAT_G1V2
