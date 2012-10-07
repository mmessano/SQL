SET nocount ON
--
DECLARE @Subject VARCHAR (100)
SET @Subject='SQL Server - SQL Overview Table Refresh Errors'

DECLARE @Count AS INT
SELECT @Count=COUNT(*) FROM SSISErrors
PRINT @Count

IF @Count > 0
BEGIN

DECLARE @tableHTML NVARCHAR(MAX) ;
SET @tableHTML =
N'<table border="1">' +
N'<tr>' +
N'<th>Server</th>' +
N'<th>packageNameName</th>' +
N'<th>Connection</th>' +
N'<th>TaskName</th>' +
N'<th>ErrorCode</th>' +
N'<th>ErrorDescription</th>' +
N'</tr>' +
CAST ( ( SELECT td=[SSISServer],''
,td=[PackageName],''
,td=[Connection],''
,td=[TaskName],''
,td=[ErrorCode],''
,td=[ErrorDescription],''
FROM [SSISErrors]
WHERE DAY(LastUpdate) = DAY(GetDate())
ORDER BY 1,2,3,4
FOR XML PATH('tr'), TYPE
) AS NVARCHAR(MAX) ) +
N'</table>' ;

PRINT @tableHTML


EXEC msdb.dbo.sp_send_dbmail
@profile_name = 'DataManagement Mail Notification',
@recipients = 'mmessano@primealliancesolutions.com',
@subject = @Subject,
@body = @tableHTML,
@body_format = 'HTML' ;

END

select * from ssiserrors