/*
directories
	e:\dexma\ssis
	e:\mssql\
		DATA
		LDF
		TRN
	e:\mssql.1\mssql\
		data
		ldf
		TRN
	g:\mssql\
		DATA
	h:\mssql
		LDF
	g:\mssql.1\mssql\
		DATA
	h:\mssql.1\mssql
		LDF

Directory roots
	:\mssql\
	:\mssql.1\mssql\

Directories
	Data
	LDF
	BAK	
Drives
	E
	F
	G
	H	
*/

EXEC dbo.dbm_ListFiles
	@PCWrite = '', --  varchar(2000)
	@DBTable = '', --  varchar(100)
	@PCIntra = '', --  varchar(100)
	@PCExtra = '', --  varchar(100)
	@DBUltra = 0 --  bit
	
sp_helptext dbm_ListFiles	

