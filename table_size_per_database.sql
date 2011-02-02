CREATE TABLE #foo
(
name VARCHAR(255),
rows INT ,
reserved varchar(255),
data varchar(255),
index_size varchar(255),
unused varchar(255)
)

CREATE TABLE #foo2
(
dbname varchar(32),
name VARCHAR(255),
rows INT ,
reserved varchar(255),
data varchar(255),
index_size varchar(255),
unused varchar(255)
)


-- comment the GO lines for SQL 2005
Declare @dbname varchar(42)
Declare @cmd varchar(8000)

declare dbname cursor for 
select name from sys.sysdatabases where name not in ('master','msdb','model','tempdb')
	AND name LIKE '%Data%'
	order by name

open dbname 
	fetch next from dbname into @dbname 
	while @@fetch_status=0 
begin 

select @cmd =	'USE [' + @dbname + ']' + char(13) +
				'exec sp_spaceused loan_price_adjustment' + char(13)-- +

--print(@cmd)
INSERT into #foo
exec(@cmd)

INSERT INTO #foo2
SELECT @dbname, * FROM #foo

truncate table #foo

fetch next from dbname into @dbname 
end
 
CLOSE dbname 
DEALLOCATE dbname

SELECT *
FROM #foo2
ORDER BY 1 ASC
DROP TABLE #foo
DROP TABLE #foo2