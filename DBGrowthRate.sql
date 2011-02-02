-- SQL 200 only, table names have changed in 2005
/*
CREATE Table dbo.DBGrowthRate 
	(DBGrowthID int identity(1,1), 
	DBName varchar(100), DBID int,
	NumPages int, OrigSize decimal(10,2), 
	CurSize decimal(10,2), 
	GrowthAmt varchar(100), 
	MetricDate datetime)
*/
Select sd.name as DBName, mf.name as FileName, mf.dbid, size
into #TempDBSize
from master..sysdatabases sd
join [master]..sysaltfiles mf
on sd.dbid = mf.dbid
Order by mf.dbid, sd.name

Insert into dbo.DBGrowthRate (DBName, DBID, NumPages, OrigSize, CurSize, GrowthAmt, MetricDate)
(Select tds.DBName, tds.dbid, Sum(tds.Size) as NumPages, 
Convert(decimal(10,2),(((Sum(Convert(decimal(10,2),tds.Size)) * 8000)/1024)/1024)) as OrigSize,
Convert(decimal(10,2),(((Sum(Convert(decimal(10,2),tds.Size)) * 8000)/1024)/1024)) as CurSize,
'0.00 MB' as GrowthAmt, GetDate() as MetricDate
from #TempDBSize tds
where tds.dbid not in (Select Distinct DBID from DBGrowthRate 
									where DBName = tds.dbid)
Group by tds.dbid, tds.DBName)

Drop table #TempDBSize

Select *
from DBGrowthRate
--Above creates initial table and checks initial data