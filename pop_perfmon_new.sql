/*
Begin

Begin Transaction

IF NOT EXISTS (Select CDetails.ObjectName, CDetails.CounterName, CDetails.CounterType, CDetails.DefaultScale, C.ObjectName, C.CounterName, C.CounterType, C.DefaultScale 
			FROM	dbo.CounterDetails CDetails LEFT OUTER JOIN
					dbo.Counters C ON CDetails.ObjectName = C.ObjectName AND CDetails.CounterName = C.CounterName)
insert into Counters 
Select CDetails.ObjectName, CDetails.CounterName, CDetails.CounterType, CDetails.DefaultScale
FROM	dbo.CounterDetails CDetails LEFT OUTER JOIN
		dbo.Counters C ON CDetails.ObjectName = C.ObjectName AND CDetails.CounterName = C.CounterName	

if @@error <> 0 
rollback transaction
else

insert into CountersDisplay Select RunID,DisplayString,LogStartTime, LogStopTime, NumberofRecords, MinutesToUTC, TimeZoneName FROM DisplayToID
if @@error <> 0
rollback transaction
else

Declare @ServerID int
Select @ServerID = (select server_id from newton.status.dbo.t_server where server_name = 
					(Select (SUBSTRING(DisplayString, 0, LEN(DisplayString) - 8)) from DisplayToID))

Declare @CDID int
	Select @CDID = (select max(CountersDisplayID) from CountersDisplay)

insert into CountersData
Select C.CountersID, @CDID, @ServerID, CONVERT(char(23),CData.CounterDateTime) AS CounterDateTime, CData.CounterValue, CDetails.InstanceName, CDetails.ParentName, CDetails.ParentObjectID, CData.FirstValueA, CData.FirstValueB, CData.SecondValueA, CData.SecondValueB, CDetails.TimeBaseA, CDetails.TimeBaseB
FROM	dbo.CounterData CData INNER JOIN
		dbo.CounterDetails CDetails ON CData.CounterID = CDetails.CounterID INNER JOIN
		dbo.Counters C ON C.ObjectName = CDetails.ObjectName and C.CounterName = CDetails.CounterName 
if @@error <> 0
rollback transaction
else

Commit Transaction

end


----------------------------------------------
SELECT     dbo.CounterData.*, dbo.CounterDetails.*, dbo.DisplayToID.*
FROM         dbo.CounterData INNER JOIN
             dbo.CounterDetails ON dbo.CounterData.CounterID = dbo.CounterDetails.CounterID INNER JOIN
             dbo.DisplayToID ON dbo.CounterData.GUID = dbo.DisplayToID.GUID
----------------------------------------------
Select * from Counters
Select * from CountersData
Select * from CountersDisplay order by countersdisplayid desc
----------------------------------------------
Select * from CounterDetails
Select * from CounterData
Select * from DisplayToID
----------------------------------------------
-- new tables purge
-- IGNORE table Counters --
truncate table CountersData
truncate table CountersDisplay
----------------------------------------------
-- old tables purge(need to reimport)
truncate table CounterData
truncate table CounterDetails
truncate table displayToID
----------------------------------------------
Select * from CountersData where datepart(d,CounterDateTime) = 14
Select top 10 CounterDateTime from CountersData
----------------------------------------------
-- displays a rowcount for each day
select distinct count(*) AS Occurences, datepart(d, CounterDateTime) AS Date
from CountersData
group by datepart(d, CounterDateTime)
order by Date
---------------
-- displays a rowcount for each day
-- uses month/day/year for uniqueness
select distinct count(*) AS Occurences, convert(char(10), CounterDateTime, 101) AS Date
from CountersData
group by convert(char(10), CounterDateTime, 101)
order by Date


-- grab all counters and data
-- this is likely SUPER SLOW
SELECT     s.server_name, Counters.ObjectName, Counters.CounterName, Counters.CounterType, Counters.DefaultScale, CountersData.CounterDateTime, 
                      CountersData.CounterValue, CountersData.InstanceName, CountersData.ParentName, CountersData.ParentObjectID, CountersData.FirstValueA, 
                      CountersData.FirstValueB, CountersData.SecondValueA, CountersData.SecondValueB, CountersData.TimeBaseA, CountersData.TimeBaseB, 
                      CountersDisplay.RunID, CountersDisplay.DisplayString, CountersDisplay.LogStartTime, CountersDisplay.LogStopTime, 
                      CountersDisplay.NumberofRecords, CountersDisplay.MinutesToUTC, CountersDisplay.TimeZoneName
FROM         Counters INNER JOIN
	CountersData ON Counters.CountersID = CountersData.CountersID INNER JOIN
	CountersDisplay ON CountersData.CountersDisplayID = CountersDisplay.CountersDisplayID INNER JOIN
	newton.Status.dbo.t_server s ON s.server_id = CountersData.ServerID
----------------------------------------------
SELECT
	s.server_name, c.ObjectName, c.CounterName, cd.CounterDateTime, max(cd.CounterValue)
FROM
	Counters c INNER JOIN
	CountersData cd ON c.CountersID = cd.CountersID INNER JOIN
	newton.Status.dbo.t_server s ON s.server_id = cd.ServerID
GROUP BY s.server_name, c.ObjectName, c.CounterName, cd.CounterDateTime
-------------------------------------------------------------------------------------------------------------------
-- returns max value per server, per counter, per day					
SELECT
		cd.CountersID, s.server_name, c.ObjectName, c.CounterName, max(cd.CounterValue) AS MaxValue, min(cd.CounterValue) AS MinValue, LEFT(CounterDateTime,10) AS Day
	FROM
		Counters c INNER JOIN
		CountersData cd ON c.CountersID = cd.CountersID INNER JOIN
		newton.Status.dbo.t_server s ON s.server_id = cd.ServerID 
	GROUP BY  s.server_name, c.ObjectName, c.CounterName, LEFT(CounterDateTime,10), cd.CountersID
	ORDER BY s.server_name, c.ObjectName, c.CounterName, LEFT(CounterDateTime,10)

-- drop CountersID from select
SELECT
		s.server_name, c.ObjectName, c.CounterName, min(cd.CounterValue) AS MinValue, max(cd.CounterValue) AS MaxValue, convert(char(10), CounterDateTime, 101) AS Day
	FROM
		Counters c INNER JOIN
		CountersData cd ON c.CountersID = cd.CountersID INNER JOIN
		newton.Status.dbo.t_server s ON s.server_id = cd.ServerID
where  convert(char(10), CounterDateTime, 101) > GetDate() - 3
	GROUP BY  s.server_name, c.ObjectName, c.CounterName, convert(char(10), CounterDateTime, 101)
	ORDER BY s.server_name, c.ObjectName, c.CounterName, convert(char(10), CounterDateTime, 101)
-------------------------------------------------------------------------------------------------------------------
-- return averages
SELECT
	s.server_name, c.ObjectName, c.CounterName, min(cd.CounterValue) AS MinValue, avg(cd.CounterValue) AS MeanAvgValue, max(cd.CounterValue) AS MaxValue, convert(char(10), CounterDateTime, 101) AS Day
FROM
	Counters c INNER JOIN
	CountersData cd ON c.CountersID = cd.CountersID INNER JOIN
	newton.Status.dbo.t_server s ON s.server_id = cd.ServerID
where  convert(char(10), CounterDateTime, 101) > GetDate() - 2
	GROUP BY  s.server_name, c.ObjectName, c.CounterName, convert(char(10), CounterDateTime, 101)
	ORDER BY s.server_name, c.ObjectName, c.CounterName, convert(char(10), CounterDateTime, 101)
-------------------------------------------------------------------------------------------------------------------

select server_id, f.server_name, f.ObjectName, f.CounterName, CountersID, MinValue, MeanAvgValue, MaxValue, Day
FROM (

SELECT
	s.server_id, s.server_name, c.CountersID, c.ObjectName, c.CounterName, min(cd.CounterValue) AS MinValue, (sum(cd.CounterValue)-min(cd.CounterValue)-max(cd.CounterValue)) / cast(count(*)-2 as float) AS MeanAvgValue, max(cd.CounterValue) AS MaxValue, convert(char(10), CounterDateTime, 101) AS Day
FROM
	Counters c INNER JOIN
	CountersData cd ON c.CountersID = cd.CountersID INNER JOIN
	newton.Status.dbo.t_server s ON s.server_id = cd.ServerID
where  convert(char(10), CounterDateTime, 101) > GetDate() - 3
	GROUP BY  s.server_name, c.ObjectName, s.server_id, c.CountersID, c.ObjectName, c.CounterName, convert(char(10), CounterDateTime, 101)
	--ORDER BY s.server_id, c.ObjectName, c.CounterName, convert(char(10), CounterDateTime, 101)
) AS f
order by f.server_name, f.ObjectName, f.CounterName

-- same as above without names for comparison
-- used to populate Daily table
-- truncate table CountersDataDaily
insert into CountersDataDaily
select server_id, CountersID, MinValue, MeanAvgValue, MaxValue, Day, GetDate() AS LastUpdate
FROM (
SELECT
	s.server_id, c.CountersID, min(cd.CounterValue) AS MinValue, avg(cd.CounterValue) AS MeanAvgValue, max(cd.CounterValue) AS MaxValue, convert(char(10), CounterDateTime, 101) AS Day
FROM
	Counters c INNER JOIN
	CountersData cd ON c.CountersID = cd.CountersID INNER JOIN
	newton.Status.dbo.t_server s ON s.server_id = cd.ServerID
--where  convert(char(10), CounterDateTime, 101) > GetDate() - 3
	GROUP BY  s.server_id, c.CountersID, convert(char(10), CounterDateTime, 101)
) AS f


-- try for Trimmed Mean dropping highest and lowest value
/*
select (sum(cd.CounterValue)-min(cd.CounterValue)-max(cd.CounterValue)) / cast(count(*)-2 as float) 
  as meantrimmedby1 
from @testscores
*/
insert into CountersDataDaily
select server_id, CountersID, MinValue, MeanAvgValue, MaxValue, Day, GetDate() AS LastUpdate
FROM (
SELECT
	s.server_id, c.CountersID, min(cd.CounterValue) AS MinValue, (sum(cd.CounterValue)-min(cd.CounterValue)-max(cd.CounterValue)) / cast(count(*)-2 as float) AS MeanAvgValue, max(cd.CounterValue) AS MaxValue, convert(char(10), CounterDateTime, 101) AS Day
FROM
	Counters c INNER JOIN
	CountersData cd ON c.CountersID = cd.CountersID INNER JOIN
	newton.Status.dbo.t_server s ON s.server_id = cd.ServerID
where  convert(char(10), CounterDateTime, 101) > GetDate() - 3
	GROUP BY  s.server_id, c.CountersID, convert(char(10), CounterDateTime, 101)
) AS f

-------------------------------------------------------------------------------------------------------------------
delete from displayToID where (Select (SUBSTRING(DisplayString, 0, LEN(DisplayString) - 8)) from DisplayToID)) not LIKE 'Apollo%'
----------------------------------------------
select CONVERT(datetime, 'CounterDateTime') from CountersData
print GetDate()
SELECT CONVERT(datetime,CONVERT(char(23),[CounterDateTime]),121) FROM CountersData
----------------------------------------------
-- check for non-date
SELECT *
FROM CountersData
WHERE ISDATE([CounterDateTime]) = 0
----------------------------------------------
-- db maintenance
sp_spaceused CountersData
sp_spaceused
checkpoint
DBCC shrinkdatabase('PerfmonData')
DBCC shrinkfile('PerfmonData')
DBCC shrinkfile('MJM_Perf_Import_log',10),TruncateOnly)
DBCC SQLPERF(LOGSPACE);


EXEC sp_helpindex CountersData 
exec sp_spaceused CountersData

SELECT name ,size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS AvailableSpaceInMB
FROM sysfiles;

----------------------------------------------
DECLARE @SQL VARCHAR(255)
SET @SQL = 'DBCC UPDATEUSAGE (' + DB_NAME() + ')'

EXEC(@SQL)

CREATE TABLE #foo
(
name VARCHAR(255),
rows INT ,
reserved varchar(255),
data varchar(255),
index_size varchar(255),
unused varchar(255)
)


INSERT into #foo
EXEC sp_MSForEachtable 'sp_spaceused ''?'''

SELECT *
FROM #foo
ORDER BY name
DROP TABLE #foo
*/