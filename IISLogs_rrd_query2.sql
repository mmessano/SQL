SELECT s.server_name, c.ObjectName, c.CounterName, cd.CounterValue, CounterDateTime AS Day
FROM
		Counters c INNER JOIN
		CountersData cd ON c.CountersID = cd.CountersID INNER JOIN
		newton.Status.dbo.t_server s ON s.server_id = cd.ServerID
and c.ObjectName = 'SQLServer:General Statistics'
and c.CounterName = 'User Connections'
and convert(char(10), CounterDateTime, 101) = convert(char(10), GetDate()- 5 ,101)
and datepart(hour, CounterDateTime) = '14'
and server_name like 'capella'
--order by server_name, day
order by  day, server_name


