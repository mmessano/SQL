SELECT SourceServer, 
		DestinationServer, 
		DestinationServerProduct, 
		DataSource, 
		DestinationServerCatalog, 
		DestinationServerUser
FROM SQLLinkedServers
WHERE SourceServer != DestinationServer
AND (DestinationServerUser = 'sa' OR DestinationServerUser = '' OR DestinationServerUser IS NULL)
AND DataSource NOT LIKE 'np:%'
order by 1,3

------------------------------------------------

SELECT * FROM SQLDBUsers
WHERE ServerLogin like '%Orphaned%'
AND DataBaseUserID NOT IN ('cdc','guest')
ORDER BY 1,3,4,6