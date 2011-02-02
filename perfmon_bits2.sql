-- grab all counters and data
-- this is likely SUPER SLOW
SELECT     
		s.server_name, Counters.ObjectName, Counters.CounterName, Counters.CounterType, Counters.DefaultScale, CountersData.CounterDateTime, 
		CountersData.CounterValue, CountersData.InstanceName, CountersData.ParentName, CountersData.ParentObjectID, CountersData.FirstValueA, 
		CountersData.FirstValueB, CountersData.SecondValueA, CountersData.SecondValueB, CountersData.TimeBaseA, CountersData.TimeBaseB, 
		CountersDisplay.RunID, CountersDisplay.DisplayString, CountersDisplay.LogStartTime, CountersDisplay.LogStopTime, 
		CountersDisplay.NumberofRecords, CountersDisplay.MinutesToUTC, CountersDisplay.TimeZoneName
FROM         
	Counters INNER JOIN
	CountersData ON Counters.CountersID = CountersData.CountersID INNER JOIN
	CountersDisplay ON CountersData.CountersDisplayID = CountersDisplay.CountersDisplayID INNER JOIN
	newton.Status.dbo.t_server s ON s.server_id = CountersData.ServerID

-------------------------------------------------------------------------------------------------------------------
select * from CountersData
-------------------------------------------------------------------------------------------------------------------
-- displays a rowcount for each day
select distinct count(*) AS Occurences, datepart(d, CounterDateTime) AS Date
from CountersData
group by datepart(d, CounterDateTime)
order by Date
-- display row count per day
-- much faster and shows yy/mm/dd instead of just Day
select count(*) AS Occurences, convert(char(10), CounterDateTime, 101) AS Date
from CountersData
group by convert(char(10), CounterDateTime, 101)
order by Date
-------------------------------------------------------------------------------------------------------------------
select server, clientname, count(clientname) as hits, avg(duration) as duration, avg(productsfound) as avgproducts, convert(char(10), datetime, 101) as datetime
from loanwizresponse
where clientname = 'FirstFuture32'
group by server, clientname, convert(char(10), datetime, 101)
order by  convert(char(10), datetime, 101)


-------------------------------------------------------------------------------------------------------------------
SELECT
	s.server_name, c.ObjectName, c.CounterName, max(cd.CounterValue) AS MaxValue
FROM
	Counters c INNER JOIN
	CountersData cd ON c.CountersID = cd.CountersID INNER JOIN
	newton.Status.dbo.t_server s ON s.server_id = cd.ServerID 
GROUP BY s.server_name, c.ObjectName, c.CounterName
ORDER BY s.server_name, c.ObjectName
-------------------------------------------------------------------------------------------------------------------

select * from counters
select TOP 100 * from CountersData
select distinct serverid from CountersData
-------------------------------------------------------------------------------------------------------------------
-- semi-functional, syntax is correct
select distinct datepart(d, cd.CounterDateTime) AS Date, count(*) AS Occurences 
from CountersData cd INNER JOIN
(
	SELECT
		s.server_name, cd.CountersID, c.ObjectName, c.CounterName, max(cd.CounterValue) AS MaxValue
	FROM
		Counters c INNER JOIN
		CountersData cd ON c.CountersID = cd.CountersID INNER JOIN
		newton.Status.dbo.t_server s ON s.server_id = cd.ServerID 
	GROUP BY s.server_name, c.ObjectName, c.CounterName, cd.CountersID
)  ij ON ij.CountersID = cd.CountersID
group by datepart(d, cd.CounterDateTime)
order by Date
-------------------------------------------------------------------------------------------------------------------
SELECT
		cd.CountersID, s.server_name, c.ObjectName, c.CounterName, max(cd.CounterValue) AS MaxValue, LEFT(CounterDateTime,10) AS Day
	FROM
		Counters c INNER JOIN
		CountersData cd ON c.CountersID = cd.CountersID INNER JOIN
		newton.Status.dbo.t_server s ON s.server_id = cd.ServerID 
	GROUP BY  s.server_name, c.ObjectName, c.CounterName, LEFT(CounterDateTime,10), cd.CountersID
	ORDER BY s.server_name, c.ObjectName, c.CounterName, LEFT(CounterDateTime,10)
-------------------------------------------------------------------------------------------------------------------
SELECT
		cd.CountersID, s.server_name, c.ObjectName, c.CounterName, min(cd.CounterValue) AS MinValue, LEFT(CounterDateTime,10) AS Day
	FROM
		Counters c INNER JOIN
		CountersData cd ON c.CountersID = cd.CountersID INNER JOIN
		newton.Status.dbo.t_server s ON s.server_id = cd.ServerID 
	GROUP BY  s.server_name, c.ObjectName, c.CounterName, LEFT(CounterDateTime,10), cd.CountersID
	ORDER BY s.server_name, c.ObjectName, c.CounterName, LEFT(CounterDateTime,10)
-------------------------------------------------------------------------------------------------------------------
-- GFP!
SELECT
		s.server_name, c.ObjectName, c.CounterName, convert(char(10), CounterDateTime, 101) AS Day
	FROM
		Counters c INNER JOIN
		CountersData cd ON c.CountersID = cd.CountersID INNER JOIN
		newton.Status.dbo.t_server s ON s.server_id = cd.ServerID
where  s.server_name = 'Apollo'
and convert(char(10), CounterDateTime, 101) LIKE '2008-02-17'
	GROUP BY  s.server_name, c.ObjectName, c.CounterName, convert(char(10), CounterDateTime, 101)
	ORDER BY s.server_name, c.ObjectName, c.CounterName, convert(char(10), CounterDateTime, 101)

select TOP 10 convert(char(10), CounterDateTime, 101) AS Day FROM CountersData


declare @N int
set @N = 1

SELECT
		s.server_name, c.ObjectName, c.CounterName, min(cd.CounterValue) AS MinValue, avg(cast(CounterValue as float)) as TrimmedMeanN, max(cd.CounterValue) AS MaxValue, LEFT(cd.CounterDateTime,10) AS Day
	FROM
		Counters c INNER JOIN
		CountersData cd ON c.CountersID = cd.CountersID INNER JOIN
		newton.Status.dbo.t_server s ON s.server_id = cd.ServerID
where  
	(select count(*) from CountersData aa
		where aa.CounterValue <= cd.CounterValue) > @N
	and
	(select count(*) from CountersData bb
		where bb.CounterValue >= cd.CounterValue) > @N
	AND
	LEFT(cd.CounterDateTime,10) > GetDate() - 5
GROUP BY  s.server_name, c.ObjectName, c.CounterName, LEFT(cd.CounterDateTime,10)
ORDER BY s.server_name, c.ObjectName, c.CounterName, LEFT(cd.CounterDateTime,10)
-------------------------------------------------------------------------------------------------------------------
-- runs forever
declare @N int
set @N = 1

select @N as N, avg(cast(CounterValue as float)) as TrimmedMeanN
from CountersData a
where
	(select count(*) from CountersData aa
		where aa.CounterValue <= a.CounterValue) > @N
	and
	(select count(*) from CountersData bb
		where bb.CounterValue >= a.CounterValue) > @N

-------------------------------------------------------------------------------------------------------------------
