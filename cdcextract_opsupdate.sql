--5) Update Ops.dbo.client_data_sources
-- run on PSQLRPT20 to generate the update commands
DECLARE @cmd varchar(512)
DECLARE @ClientID varchar(8)
DECLARE @SourceServer varchar(16)
DECLARE @SourceDB varchar(32)
DECLARE @CDCReportServer varchar(32)
DECLARE @CDCReportDB varchar(32)

--SELECT * FROM ClientConnection
DECLARE clients CURSOR FOR
	SELECT ClientID, SourceServer, SourceDB, CDCReportServer, CDCReportDB 
		FROM ClientConnection
		WHERE SourceDB NOT IN ('AddisonAve32', 'AmericaFirst32', 'Audit', 'Boeing4', 'Chevron', 'ConsumersCU', 'ENT', 'McDillAFB', 'Merchants', 'PADemoDu', 'PADemoLP', 'PaReporting', 'PATrain', 'Patelco32', 'RLC', 'SDCCU32','dupont','ConsumersCU','CUCompanies','ORNL','SAFCU','AEA','ArizonaStateCU','SecurityServices','AltaOne','Columbia32','firsttech','HiWayCU','HomeownersMtg','IBMSoutheast','NASA','OrangeCounty32','Redwood','Rivermark','SFFCU','Vandenberg32','Verity','ABECU32','AmericanAirlines','Baxter','BayFederal','CUMA','CUWest','Delta','DenverPublicSchools','Kinecta','Meriwest32','MidwestFinancial','MidwestLoan32','PeoplesTrust','Starone')
		ORDER BY 3

OPEN clients
	FETCH NEXT FROM clients INTO @ClientID, @SourceServer, @SourceDB, @CDCReportServer, @CDCReportDB
	WHILE @@FETCH_STATUS = 0
BEGIN

SELECT @cmd =
'UPDATE [ops].[dbo].[client_data_sources]
SET 
  [reporting_server_name] = ''' + @CDCReportServer + '''
  ,[reporting_server_database_name] = ''' + @CDCReportDB + '''
  ,[linked_server_name] = ''np_' + @SourceServer + '''
  ,[report_service_URL] = ''http://' + @CDCReportServer + '/ReportServer''
  ,[linked_database_name] = ''' + @SourceDB + '''
WHERE [client_id] = ''' + @ClientID + '''
GO
------------------------------------------------------------------'

PRINT @cmd

FETCH NEXT FROM clients INTO @ClientID, @SourceServer, @SourceDB, @CDCReportServer, @CDCReportDB
END

CLOSE clients
DEALLOCATE clients

