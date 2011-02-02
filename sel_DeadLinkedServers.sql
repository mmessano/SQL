--select * from SQLLinkedServers

SELECT CONVERT(nvarchar (14), sls.SourceServer) AS SourceServer, CONVERT(nvarchar (16), sls.DestinationServer) AS DestinationServer, sls.LastUpdate 
FROM
	t_server s JOIN
	SQLLinkedServers sls ON s.server_name = sls.DestinationServer
WHERE s.active = '0'
order by 1,3
