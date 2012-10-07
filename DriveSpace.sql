DECLARE @svrName VARCHAR(255)
DECLARE @sql VARCHAR(400)
DECLARE @DriveInfo TABLE (
	line VARCHAR(255)
	)
	
--by default it will take the current server name, we can the set the server name as well
SET @svrName = @@SERVERNAME
SET @sql = 'powershell.exe -c "Get-WmiObject -ComputerName ' + QUOTENAME(@svrName,'''') + ' -Class Win32_Volume -Filter ''DriveType = 3'' | select name,capacity,freespace | foreach{$_.name+''|''+$_.capacity/1048576+''%''+$_.freespace/1048576+''*''}"'
PRINT @sql

--inserting disk name, total space and free space value
INSERT @DriveInfo
EXEC xp_cmdshell @sql
select * from @DriveInfo
--script to retrieve the values in MB from PS Script output
SELECT RTRIM(LTRIM(SUBSTRING(line,1,CHARINDEX('|',line) -1))) AS drivename
      ,ROUND(CAST(RTRIM(LTRIM(SUBSTRING(line,CHARINDEX('|',line)+1,
      (CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as Float),0) AS 'capacity(MB)'
      ,ROUND(CAST(RTRIM(LTRIM(SUBSTRING(line,CHARINDEX('%',line)+1,
      (CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as Float),0) AS 'freespace(MB)'
      ,ROUND(CAST(RTRIM(LTRIM(SUBSTRING(line,CHARINDEX('|',line)+1,
      (CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as Float)/1024,0) as 'capacity(GB)'
      ,ROUND(CAST(RTRIM(LTRIM(SUBSTRING(line,CHARINDEX('%',line)+1,
      (CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as Float) /1024 ,0)as 'freespace(GB)'
--FROM #output
FROM @DriveInfo
WHERE line LIKE '[A-Z][:]%'
ORDER BY drivename

--script to retrieve the values in GB from PS Script output
--SELECT RTRIM(LTRIM(SUBSTRING(line,1,CHARINDEX('|',line) -1))) as drivename
--      ,ROUND(CAST(RTRIM(LTRIM(SUBSTRING(line,CHARINDEX('|',line)+1,
--      (CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as Float)/1024,0) as 'capacity(GB)'
--      ,ROUND(CAST(RTRIM(LTRIM(SUBSTRING(line,CHARINDEX('%',line)+1,
--      (CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as Float) /1024 ,0)as 'freespace(GB)'
----FROM #output
--FROM @DriveInfo
--WHERE line LIKE '[A-Z][:]%'
--ORDER BY drivename

--script to drop the temporary table



