DECLARE @DBFiles TABLE (
	ServerName varchar(24)
	, DatabaseName varchar(32)
	, LogicalName varchar(32)
	, FileName varchar(128)
	, LastUpdate datetime
);

INSERT INTO @DBFiles
EXEC sp_MSForEachDB 
	'SELECT CONVERT(nvarchar(32), SERVERPROPERTY(''Servername'')) AS Server,
		''?'' as DatabaseName,
		[?]..sysfiles.name AS LogicalName, 
		[?]..sysfiles.filename AS FileName,
		GETDATE()
			From [?]..sysfiles'


SELECT * FROM @DBFiles