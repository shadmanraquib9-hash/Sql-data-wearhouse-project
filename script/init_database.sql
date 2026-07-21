
/*

Create Database and Schemas

Script Purpose:

This script creates a new database named 'DataWarehouse' after checking if it already exists. 
If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas 
within the database: 'bronze', 'silver', and 'gold'.

WARNING:

Running this script will drop the entire 'DataWarehouse' database if it exists. 
All data in the database will be permanently deleted. 
Proceed with caution and ensure you have proper backups before running this script.
*/

Use master;

if exists (select 1 from sys.database where name = 'Data_warehouse')
begin
	alter database data_warehouse set single_user with rollback immediate;
	drop database data_warehouse;
end;
go

create database Data_warehouse
go
use Data_warehouse;
go

Create schema Bronze;
go
Create schema Silver;
go
Create schema Gold;
go