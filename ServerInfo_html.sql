DECLARE @table_id int
DECLARE @TableName varchar(300)
DECLARE @strHTML varchar(8000)
DECLARE @strHTML1 varchar(8000)
DECLARE @ColumnName varchar(200)
DECLARE @ColumnType varchar(200)
DECLARE @ColumnLength smallint
DECLARE @ColumnComments sql_variant
DECLARE @ColumnPrec smallint
DECLARE @ColumnScale int
DECLARE @ColumnCollation varchar(200)

DECLARE @CType sysname
DECLARE @CName sysname
DECLARE @CPKTable sysname
DECLARE @CPKColumn sysname
DECLARE @CFKTable sysname
DECLARE @CFKColumn sysname
DECLARE @CKey smallint
DECLARE @CDefault varchar(4000)
DECLARE @Populated bit

DECLARE @IDesc varchar(60)
DECLARE @IRows varchar(11)
DECLARE @IReserved varchar(11)
DECLARE @IData varchar(11)
DECLARE @IIndex varchar(11)
DECLARE @IRowData varchar(11)
DECLARE @SetOption bit
DECLARE @databasename varchar(30)
DECLARE @orderCol varchar(30)
DECLARE @numeric bit

DECLARE @Trigger varchar(50)
DECLARE @DBPath varchar(500)

DECLARE @ViewName varchar(200)
DECLARE @ViewTableDep varchar(200)
DECLARE @ViewColDep varchar(200)
DECLARE @ViewColDepType varchar(200)
DECLARE @ViewColDepLength smallint
DECLARE @ViewColDepPrec smallint
DECLARE @ViewColDepScale int
DECLARE @ViewColDepCollation varchar(200)

DECLARE @SPName varchar(200)
DECLARE @SPTableDep varchar(200)
DECLARE @SPColDep varchar(200)
DECLARE @SPColDepType varchar(200)
DECLARE @SPColDepLength smallint
DECLARE @SPColDepPrec smallint
DECLARE @SPColDepScale int
DECLARE @SPColDepCollation varchar(200)

DECLARE @ParamName sysname
DECLARE @ParamDataType varchar(50)
DECLARE @ParamType varchar(11)

DECLARE @DBLastBackup smalldatetime
DECLARE @DBLastBackupDays int

DECLARE @UserLogin varchar(30)
DECLARE @UserName varchar(30)
DECLARE @UserGroup varchar(30)

--initialize HTML string
SET @strHTML = ''

SELECT @strHTML = @strHTML + '<HTML><HEAD><TITLE>' + db_Name() + ' Database Definition</TITLE><STYLE>TD.Sub{FONT-WEIGHT:bold;BORDER-BOTTOM: 0pt solid #000000;BORDER-LEFT: 1pt solid #000000;BORDER-RIGHT: 0pt solid #000000;BORDER-TOP: 0pt solid #000000; FONT-FAMILY: Tahoma;FONT-SIZE: 8pt} BODY{FONT-FAMILY: Tahoma;FONT-SIZE: 8pt} TABLE{BORDER-BOTTOM: 1pt solid #000000;BORDER-LEFT: 0pt solid #000000;BORDER-RIGHT: 1pt solid #000000;BORDER-TOP: 0pt solid #000000; FONT-FAMILY: Tahoma;FONT-SIZE: 8pt} TD{BORDER-BOTTOM: 0pt solid #000000;BORDER-LEFT: 1pt solid #000000;BORDER-RIGHT: 0pt solid #000000;BORDER-TOP: 1pt solid #000000; FONT-FAMILY: Tahoma;FONT-SIZE: 8pt} TD.Title{FONT-WEIGHT:bold;BORDER-BOTTOM: 0pt solid #000000;BORDER-LEFT: 1pt solid #000000;BORDER-RIGHT: 0pt solid #000000;BORDER-TOP: 1pt solid #000000; FONT-FAMILY: Tahoma;FONT-SIZE: 12pt} A.Index{FONT-WEIGHT:bold;FONT-SIZE:8pt;COLOR:#000099;FONT-FAMILY:Tahoma;TEXT-DECORATION:none} A.Index:HOVER{FONT-WEIGHT:bold;FONT-SIZE:8pt;COLOR:#990000;FONT-FAMILY:Tahoma;TEXT-DECORATION:none}</STYLE></HEAD><BODY><A NAME="_top"></A><BR>'

PRINT @strHTML

SELECT @DBPath = (SELECT [filename] FROM master..sysdatabases WHERE [name] = db_Name())

SELECT @strHTML = '<BR><CENTER><FONT SIZE="5"><B>' + db_name() + ' Database Definition</B></FONT></CENTER><BR>'
PRINT @strHTML

PRINT '<CENTER><A HREF="#_ServerOptions" CLASS="Index">SERVER SETTINGS<A>  |  <A HREF="#_Options" CLASS="Index">DATABASE SETTINGS<A>  |  <A HREF="#_Users" CLASS="Index">USERS<A>  |  <A HREF="#_Tables" CLASS="Index">TABLES<A>  |  <A HREF="#_Views" CLASS="Index">VIEWS<A>  |  <A HREF="#_SP" CLASS="Index">STORED PROCEDURES<A></CENTER><BR>'

--Table Of Contents

	SET NOCOUNT ON

	SELECT @orderCol = 'Description'

	SELECT @DatabaseName = db_name()
	SELECT @numeric = 1

	IF @DatabaseName <> 'Master'
	   AND NOT EXISTS (select 1 from master..sysdatabases WHERE name = @DatabaseName AND (status & 4) = 4)
	  BEGIN
	  exec sp_dboption @databaseName ,'select into/bulkcopy', 'true'
	  SELECT @SetOption = 1
	  END

	IF EXISTS (SELECT 1 FROM master..sysobjects WHERE name = 'space1')
	  DROP TABLE master..space1
	CREATE TABLE master..Space1 (name varchar(60), rows varchar(11), reserved varchar(11), data varchar(11), index_size varchar(11), unused varchar(11))

	DECLARE @Cmd varchar(255)
	declare cSpace CURSOR FOR
	  select 'USE ' + @DatabaseName + ' INSERT into master..space1 EXEC sp_spaceUsed ''[' + u.name + '].[' + o.name + ']'''
	  FROM sysobjects o
	  join sysusers u on u.uid = o.uid
	  WHERE type = 'U'
	  AND o.Name <> 'Space1'

	OPEN cSPACE
	FETCH cSpace INTO @Cmd
	WHILE @@FETCH_STATUS =0
	  BEGIN
	--  PRINT @Cmd
	  EXECUTE (@Cmd)
	  FETCH cSpace INTO @Cmd
	  END
	DEALLOCATE cSPace

	DECLARE cursor_index CURSOR FOR
		SELECT Description,Rows,Reserved,Data,Index_size,dataPerRows
		FROM (
		  SELECT 3 DataOrder,
		         CONVERT(int,CASE @OrderCol WHEN 'Rows' THEN Rows
		                          WHEN 'Reserved' THEN SUBSTRING(Reserved, 1,LEN(Reserved)-2)
		                          WHEN 'data' THEN SUBSTRING(Data, 1,LEN(Data)-2)
		                          WHEN 'index_size' THEN SUBSTRING(Index_size, 1,LEN(index_Size)-2)
		                          WHEN 'unused' THEN SUBSTRING(unused, 1,LEN(unused)-2) END) OrderData,
		         name Description, rows,
		         CASE @NUMERIC WHEN 0 THEN reserved ELSE SUBSTRING(reserved, 1, len(reserved)-2) END reserved,
		         CASE @NUMERIC WHEN 0 THEN data ELSE SUBSTRING(data, 1, len(data)-2) END data,
		         CASE @NUMERIC WHEN 0 THEN index_size ELSE SUBSTRING(index_size, 1, len(index_size)-2) END index_size,
		         CASE WHEN Rows = 0 THEN '0' ELSE CONVERT(varchar(11),CONVERT(numeric(10,2),CONVERT(numeric,SUBSTRING(reserved, 1, len(reserved)-2)) /rows*1000)) END DataPerRows
		    FROM master..Space1 ) Stuff
		ORDER BY DataOrder, OrderData desc, description

		OPEN cursor_index

		SET @strHTML = '<DIV ALIGN="center"><TABLE BORDER="0" CELLPADDING="2" CELLSPACING="0" BORDERCOLOUR="003366" WIDTH="80%">
				<TR BGCOLOR="EEEEEE"><TD CLASS="Title" COLSPAN="6" ALIGN="center"><B>Table Of Contents</B> </TD></TR>
				<TR BGCOLOR="EEEEEE">
				  <TD ALIGN="left" WIDTH="50%"><B>Table</B> </TD>
				  <TD ALIGN="left" WIDTH="10%"><B>Row Count</B> </TD>
				  <TD ALIGN="left" WIDTH="10%"><B>Reserved</B> </TD>
				  <TD ALIGN="left" WIDTH="10%"><B>Row Data</B> </TD>
				  <TD ALIGN="left" WIDTH="10%"><B>Index Size</B> </TD>
				  <TD ALIGN="left" WIDTH="10%"><B>Table Data</B> </TD>
				</TR>'

		PRINT @strHTML

		PRINT '<TR><TD VALIGN="top"><A CLASS="Index" HREF="#_ServerOptions">Server Options</A> </TD><TD BGCOLOR="EEEEEE" COLSPAN="5">  </TD></TR>'
		PRINT '<TR><TD VALIGN="top"><A CLASS="Index" HREF="#_Options">Database Options</A> </TD><TD BGCOLOR="EEEEEE" COLSPAN="5">  </TD></TR>'
		PRINT '<TR><TD VALIGN="top"><A CLASS="Index" HREF="#_Users">Database Users</A> </TD><TD BGCOLOR="EEEEEE" COLSPAN="5">  </TD></TR>'

		FETCH NEXT FROM cursor_index INTO @IDesc,@IRows,@IReserved,@IData,@IIndex,@IRowData

		WHILE (@@FETCH_STATUS = 0)
			BEGIN

				SET @strHTML = '<TR><TD VALIGN="top"><A CLASS="Index" HREF="#' + ISNULL(@IDesc, ' ') + '">' + ISNULL(@IDesc, ' ') + '</A> </TD><TD VALIGN="top">' +
					ISNULL(@IRows, ' ') + ' </TD><TD VALIGN="top">' +
					ISNULL(@IReserved, ' ') + ' </TD><TD VALIGN="top">' +
					ISNULL(@IData, ' ') + ' </TD><TD VALIGN="top">' +
					ISNULL(@IIndex, ' ') + ' </TD><TD VALIGN="top">' +
					ISNULL(@IRowData, ' ') + ' </TD></TR>'
				PRINT @strHTML
				FETCH NEXT FROM cursor_index INTO @IDesc,@IRows,@IReserved,@IData,@IIndex,@IRowData

			END
		CLOSE cursor_index
		DEALLOCATE cursor_index

		DECLARE cursor_views_index CURSOR FOR
			SELECT [name] FROM sysobjects WHERE [xtype] = 'V' AND [category] <> 2 ORDER BY [name]

		OPEN cursor_views_index

		FETCH NEXT FROM cursor_views_index INTO @ViewName

				WHILE (@@FETCH_STATUS = 0)
					BEGIN

						SET @strHTML = '<TR><TD VALIGN="top"><A CLASS="Index" HREF="#' + ISNULL(@ViewName, ' ') + '">' + ISNULL(@ViewName, ' ') + '</A> </TD><TD BGCOLOR="EEEEEE" COLSPAN="5">  </TD></TR>'

						PRINT @strHTML

						FETCH NEXT FROM cursor_views_index INTO @ViewName
					END
		CLOSE cursor_views_index
		DEALLOCATE cursor_views_index

		DECLARE cursor_sp_index CURSOR FOR
			SELECT [name] FROM sysobjects WHERE [xtype] = 'P' AND [category] <> 2 ORDER BY [name]

		OPEN cursor_sp_index

		FETCH NEXT FROM cursor_sp_index INTO @SPName

				WHILE (@@FETCH_STATUS = 0)
					BEGIN

						SET @strHTML = '<TR><TD VALIGN="top"><A CLASS="Index" HREF="#' + ISNULL(@SPName, ' ') + '">' + ISNULL(@SPName, ' ') + '</A> </TD><TD BGCOLOR="EEEEEE" COLSPAN="5">  </TD></TR>'

						PRINT @strHTML

						FETCH NEXT FROM cursor_sp_index INTO @SPName
					END
		CLOSE cursor_sp_index
		DEALLOCATE cursor_sp_index

		SELECT @strHTML = '</TABLE></DIV><BR><BR>'
		PRINT @strHTML
		EXECUTE ('DROP TABLE master..space1')
		IF @SetOption = 1 exec sp_dboption @databasename ,'select into/bulkcopy', 'false'

PRINT '<DIV ALIGN="center"><TABLE BORDER="0" CELLPADDING="2" CELLSPACING="0" BORDERCOLOUR="003366" WIDTH="60%">'
PRINT '<TR BGCOLOR="EEEEEE"><TD CLASS="Title" COLSPAN="2" ALIGN="center"><B><A NAME="_ServerOptions">Server Settings</A></B> </TD></TR>'
PRINT '<TR BGCOLOR="EEEEEE"><TD ALIGN="left" WIDTH="30%"><B>Table</B> </TD><TD ALIGN="left" WIDTH="70%"><B>Row Count</B> </TD></TR>'
PRINT '<TR><TD><B>Server Name</B> </TD><TD>' + convert(varchar(30),@@SERVERNAME) + ' </TD></TR>'
PRINT '<TR><TD><B>Instance</B> </TD><TD>' + convert(varchar(30),@@SERVICENAME) + ' </TD></TR>'
PRINT '<TR><TD><B>Current Date Time</B> </TD><TD>' + convert(varchar(30),getdate(),113) + ' </TD></TR>'
PRINT '<TR><TD><B>User</B> </TD><TD>' + USER_NAME() + ' </TD></TR>'
PRINT '<TR><TD><B>Number of connections</B> </TD><TD>' + convert(varchar(30),@@connections) + ' </TD></TR>'
PRINT '<TR><TD><B>Language</B> </TD><TD>' + convert(varchar(30),@@language) + ' </TD></TR>'
PRINT '<TR><TD><B>Language Id</B> </TD><TD>' + convert(varchar(30),@@langid) + ' </TD></TR>'
PRINT '<TR><TD><B>Lock Timeout</B> </TD><TD>' + convert(varchar(30),@@LOCK_TIMEOUT) + ' </TD></TR>'
PRINT '<TR><TD><B>Maximum of connections</B> </TD><TD>' + convert(varchar(30),@@MAX_CONNECTIONS) + ' </TD></TR>'
PRINT '<TR><TD><B>CPU Busy</B> </TD><TD>' + convert(varchar(30),@@CPU_BUSY/1000) + ' </TD></TR>'
PRINT '<TR><TD><B>CPU Idle</B> </TD><TD>' + convert(varchar(30),@@IDLE/1000) + ' </TD></TR>'
PRINT '<TR><TD><B>IO Busy</B> </TD><TD>' + convert(varchar(30),@@IO_BUSY/1000) + ' </TD></TR>'
PRINT '<TR><TD><B>Packets received</B> </TD><TD>' + convert(varchar(30),@@PACK_RECEIVED) + ' </TD></TR>'
PRINT '<TR><TD><B>Packets sent</B> </TD><TD>' + convert(varchar(30),@@PACK_SENT) + ' </TD></TR>'
PRINT '<TR><TD><B>Packets w errors</B> </TD><TD>' + convert(varchar(30),@@PACKET_ERRORS) + ' </TD></TR>'
PRINT '<TR><TD><B>TimeTicks</B> </TD><TD>' + convert(varchar(30),@@TIMETICKS) + ' </TD></TR>'
PRINT '<TR><TD><B>IO Errors</B> </TD><TD>' + convert(varchar(30),@@TOTAL_ERRORS) + ' </TD></TR>'
PRINT '<TR><TD><B>Total Read</B> </TD><TD>' + convert(varchar(30),@@TOTAL_READ) + ' </TD></TR>'
PRINT '<TR><TD><B>Total Write</B> </TD><TD>' + convert(varchar(30),@@TOTAL_WRITE) + ' </TD></TR>'
PRINT '</TABLE></DIV><BR><A CLASS="Index" HREF="#_top">Back To Top ^</A><BR><BR>'

SET @strHTML = '<DIV ALIGN="center"><TABLE BORDER="0" CELLPADDING="2" CELLSPACING="0" BORDERCOLOUR="003366" WIDTH="60%">
				<TR BGCOLOR="EEEEEE"><TD CLASS="Title" COLSPAN="2" ALIGN="center" VALIGN="top"><A NAME="_Options"><B>Database Settings</B></A> </TD></TR>
				<TR BGCOLOR="EEEEEE">
				  <TD ALIGN="left" WIDTH="30%"><B>Option</B> </TD>
				  <TD ALIGN="left" WIDTH="70%"><B>Setting</B> </TD>
				</TR>'

PRINT @strHTML

SELECT @strHTML = '<TR><TD><B>Name</B> </TD><TD>' + [name] + ' </TD></TR>' +
'<TR><TD><B>autoclose</B> </TD><TD>' + MIN(CASE status & 1 WHEN 1 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>select into/bulkcopy</B> </TD><TD>' + MIN(CASE status & 4 WHEN 4 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>trunc. log on chkpt</B> </TD><TD>' + MIN(CASE status & 8 WHEN 8 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>torn page detection</B> </TD><TD>' + MIN(CASE status & 16 WHEN 16 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>loading</B> </TD><TD>' + MIN(CASE status & 32 WHEN 32 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>pre recovery</B> </TD><TD>' + MIN(CASE status & 64 WHEN 64 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>recovering</B> </TD><TD>' + MIN(CASE status & 128 WHEN 128 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>Falset recovered</B> </TD><TD>' + MIN(CASE status & 256 WHEN 256 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>offline</B> </TD><TD>' + MIN(CASE status & 512 WHEN 512 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>read only</B> </TD><TD>' + MIN(CASE status & 1024 WHEN 1024 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>dbo use only</B> </TD><TD>' + min(CASE status & 2048 WHEN 2048 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>single user</B> </TD><TD>' + MIN(CASE status & 4096 WHEN 4096 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>emergency mode</B> </TD><TD>' + MIN(CASE status & 32768 WHEN 32768 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>autoshrink</B> </TD><TD>' + MIN(CASE status & 4194304 WHEN 4194304 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>cleanly shutdown</B> </TD><TD>' + MIN(CASE status & 1073741824 WHEN 1073741824 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>ANSI null default</B> </TD><TD>' + MIN(CASE status2 & 16384 WHEN 16384 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>concat null yields null</B> </TD><TD>' + MIN(CASE status2 & 65536 WHEN 65536 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>recursive triggers</B> </TD><TD>' + MIN(CASE status2 & 131072 WHEN 131072 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>default to local cursor</B> </TD><TD>' + MIN(CASE status2 & 1048576 WHEN 1048576 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>quoted identifier</B> </TD><TD>' + MIN(CASE status2 & 8388608 WHEN 8388608 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>cursor close on commit</B> </TD><TD>' + MIN(CASE status2 & 33554432 WHEN 33554432 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>ANSI nulls</B> </TD><TD>' + MIN(CASE status2 & 67108864 WHEN 67108864 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>ANSI warnings</B> </TD><TD>' + MIN(CASE status2 & 268435456 WHEN 268435456 THEN 'True' ELSE 'False' END) + ' </TD></TR>' +
'<TR><TD><B>full text enabled</B> </TD><TD>' + MIN(CASE status2 & 536870912 WHEN 536870912 THEN 'True' ELSE 'False' END) + ' </TD></TR>'
FROM master..sysdatabases
WHERE [name] = db_Name()
GROUP BY [name]

PRINT @strHTML

SELECT @DBPath = (SELECT [filename] FROM master..sysdatabases WHERE [name] = db_Name())

PRINT '<TR><TD><B>Data Path</B> </TD><TD>' + @DBPath + ' </TD></TR>'

SELECT @DBLastBackup = (SELECT CONVERT( SmallDateTime , MAX(Backup_Finish_Date)) FROM MSDB.dbo.BackupSet WHERE Type = 'd' AND Database_Name = db_Name())

PRINT '<TR><TD><B>Last Backup</B> </TD><TD>' + ISNULL(CONVERT(varchar(50),@DBLastBackup),' ') + ' </TD></TR>'

SELECT @DBLastBackupDays = (SELECT DATEDIFF(d, MAX(Backup_Finish_Date), Getdate()) FROM MSDB.dbo.BackupSet WHERE Type = 'd' AND Database_Name = db_Name())

PRINT '<TR><TD><B>Days Since Last Backup</B> </TD><TD>' + ISNULL(CONVERT(varchar(10),@DBLastBackupDays),' ') + ' </TD></TR>'

SET @strHTML = '</TABLE></DIV><BR><A CLASS="Index" HREF="#_top">Back To Top ^</A><BR><BR>'

PRINT @strHTML


DECLARE cursor_users CURSOR FOR
	SELECT LEFT(rtrim(CASE u1.islogin WHEN 1 THEN u1.name END), 30), LEFT(rtrim(u1.name), 30), LEFT(rtrim(u2.name), 30)
	FROM sysusers u1, sysusers u2
	WHERE u1.gid = u2.uid AND u1.sid IS NOT NULL AND u1.name NOT IN ('guest', 'dbo', 'Administrator')

OPEN cursor_users

SET @strHTML = '<DIV ALIGN="center"><TABLE BORDER="0" CELLPADDING="2" CELLSPACING="0" BORDERCOLOUR="003366" WIDTH="60%">
		<TR BGCOLOR="EEEEEE"><TD CLASS="Title" COLSPAN="6" ALIGN="center"><A NAME="_Users"><B>Users</B></A> </TD></TR>
		<TR BGCOLOR="EEEEEE">
		  <TD ALIGN="left" WIDTH="40%"><B>Login Name</B> </TD>
		  <TD ALIGN="left" WIDTH="30%"><B>User Name</B> </TD>
		  <TD ALIGN="left" WIDTH="30%"><B>Group Name</B> </TD>
		</TR>'

PRINT @strHTML

FETCH NEXT FROM cursor_users INTO @UserLogin,@UserName,@UserGroup

WHILE (@@FETCH_STATUS = 0)
	BEGIN

		SET @strHTML = '<TR><TD VALIGN="top">' + ISNULL(@UserLogin, ' ') + ' </TD><TD VALIGN="top">' +
			ISNULL(@UserName, ' ') + ' </TD><TD VALIGN="top">' +
			ISNULL(@UserGroup, ' ') + ' </TD></TR>'
		PRINT @strHTML
		FETCH NEXT FROM cursor_users INTO @UserLogin,@UserName,@UserGroup

	END
CLOSE cursor_users
DEALLOCATE cursor_users

SELECT @strHTML = '</TABLE></DIV><BR><A CLASS="Index" HREF="#_top">Back To Top ^</A><BR><BR>'

PRINT @strHTML

SELECT @strHTML = '<CENTER><FONT SIZE="5"><A NAME="_Tables"><B>Tables</B></A></FONT></CENTER><BR><BR>'

PRINT @strHTML

DECLARE cursor_documentation CURSOR FOR
	SELECT DISTINCT id , [name]
	FROM sysobjects
	WHERE OBJECTPROPERTY(sysobjects.id, 'IsMSShipped') = 0 AND
		sysobjects.type = 'U' ORDER BY sysobjects.[name]

OPEN cursor_documentation

FETCH NEXT FROM cursor_documentation INTO @table_id, @TableName

WHILE (@@FETCH_STATUS = 0)
	BEGIN
		--building HTML tables documentation
		SELECT @strHTML = '<TABLE BORDER="0" CELLPADDING="2" CELLSPACING="0" BORDERCOLOUR="003366" WIDTH="100%">
				<TR BGCOLOR="EEEEEE"><TD CLASS="Title" COLSPAN="7" ALIGN="center" VALIGN="top"><A NAME="' + sysobjects.name + '"><B>' + sysobjects.name + '</B></A> </TD></TR>
				<TR BGCOLOR="EEEEEE">
				  <TD ALIGN="left" WIDTH="25%"><B>Column</B> </TD>
				  <TD ALIGN="center" WIDTH="20%"><B>Type</B> </TD>
				  <TD ALIGN="center" WIDTH="5%"><B>Length</B> </TD>
				  <TD ALIGN="center" WIDTH="5%"><B>Precision</B> </TD>
				  <TD ALIGN="center" WIDTH="5%"><B>Scale</B> </TD>
				  <TD ALIGN="center" WIDTH="20%"><B>Collation</B> </TD>
				  <TD ALIGN="center" WIDTH="20%"><B>Comments</B> </TD>
				</TR>'
		FROM sysobjects
		WHERE sysobjects.id = @table_id

		PRINT @strHTML

		SET @strHTML = ''
/*
		DECLARE cursor_Column CURSOR FOR
                        -- declare @table_id varchar(10)
			SELECT syscolumns.[name],
                     systypes.[name],
			   --(SELECT systypes.[name] FROM systypes WHERE xtype = syscolumns.xtype),
			  		 syscolumns.length,
					 sys.extended_properties.[value],
					 syscolumns.prec,
					 syscolumns.scale,
					 syscolumns.[collation]
	 			FROM sysobjects INNER JOIN
              	  syscolumns ON sysobjects.id = syscolumns.id INNER JOIN
              	  systypes ON syscolumns.xtype = systypes.xtype LEFT OUTER JOIN
              	  sys.extended_properties ON syscolumns.colid = sys.extended_properties.minor_id AND syscolumns.id = sys.extended_properties.major_id
				-- JOIN systypes ON systypes.xtype = syscolumns.xtype
                            WHERE sysobjects.id = @table_id ORDER BY syscolumns.colorder

		OPEN cursor_Column

		FETCH NEXT FROM cursor_Column INTO @ColumnName, @ColumnType, @ColumnLength, @ColumnComments, @ColumnPrec, @ColumnScale, @ColumnCollation

		WHILE (@@FETCH_STATUS = 0)
			BEGIN

				SET @strHTML = '<TR><TD VALIGN="top">' + @ColumnName + ' </TD><TD VALIGN="top">' +
					ISNULL(@ColumnType, ' ') + ' </TD><TD VALIGN="top">' +
					ISNULL(convert(varchar(5), @ColumnLength), ' ') + ' </TD><TD VALIGN="top">' +
					ISNULL(convert(varchar(5), @ColumnPrec), ' ') + ' </TD><TD VALIGN="top">' +
					ISNULL(convert(varchar(5), @ColumnScale), ' ') + ' </TD><TD VALIGN="top">' +
	      	   			ISNULL(@ColumnCollation, ' ') + ' </TD><TD VALIGN="top">' +
					ISNULL(convert(varchar(500), @ColumnComments), ' ') + ' </TD></TR>'

				PRINT @strHTML

				FETCH NEXT FROM cursor_Column INTO @ColumnName, @ColumnType, @ColumnLength, @ColumnComments, @ColumnPrec, @ColumnScale, @ColumnCollation
			END

		CLOSE cursor_Column
		DEALLOCATE cursor_Column

  		SELECT @strHTML = '</TABLE>'

		PRINT @strHTML
*/

			SELECT @strHTML1 = '<TABLE BORDER="0" CELLPADDING="2" CELLSPACING="0" BORDERCOLOUR="003366" WIDTH="100%">
					<TR BGCOLOR="EEEEEE"><TD CLASS="Sub" COLSPAN="8" ALIGN="left"><B>Constraints</B> </TD></TR><TR BGCOLOR="EEEEEE">
					  <TD ALIGN="left" WIDTH="10%"><B>Constraint Type</B> </TD>
					  <TD ALIGN="left" WIDTH="20%"><B>Contraint Name</B> </TD>
					  <TD ALIGN="left" WIDTH="15%"><B>Table</B> </TD>
					  <TD ALIGN="left" WIDTH="15%"><B>Column</B> </TD>
					  <TD ALIGN="left" WIDTH="15%"><B>FK Table</B> </TD>
					  <TD ALIGN="left" WIDTH="15%"><B>FK Column</B> </TD>
					  <TD ALIGN="left" WIDTH="5%"><B>Key No.</B> </TD>
					  <TD ALIGN="left" WIDTH="5%"><B>Default</B> </TD>
					</TR>'
			FROM sysobjects
			WHERE sysobjects.id = @table_id

			SET @Populated = 0

			SET @strHTML = ''

			DECLARE cursor_Constraint CURSOR FOR
				(SELECT
					CASE o1.xtype WHEN 'C' THEN 'Check' WHEN 'D' THEN 'Default' WHEN 'F' THEN 'Foreign Key' WHEN 'PK' THEN 'Primary Key' WHEN 'UQ' THEN 'Unique' ELSE 'Other' END AS 'Constraint Type',
					o1.name AS 'Constraint Name',	o.name AS 'Table Name',	c1.name AS 'Column Name', NULL AS 'FK Table Name', NULL AS 'FK Column Name',
				   k.keyno AS 'KeyNo', NULL AS 'Default/Check Value'
				FROM sysobjects o JOIN sysobjects o1 ON o1.Parent_obj = o.id
										JOIN sysconstraints c ON c.constid = o1.id
										JOIN sysindexes i	ON i.id = o.id AND i.name = o1.name
										JOIN sysindexkeys k ON k.id = i.id AND k.indid = i.indid
										JOIN syscolumns c1 ON c1.id = k.id AND c1.colid = k.colid
				WHERE o1.xtype = 'UQ' AND o.id = @table_id
				UNION
				SELECT
					CASE o1.xtype WHEN 'C' THEN 'Check' WHEN 'D' THEN 'Default' WHEN 'F' THEN 'Foreign Key' WHEN 'PK' THEN 'Primary Key' WHEN 'UQ' THEN 'Unique' ELSE 'Other' END AS 'Constraint Type',
					o1.name AS 'Constraint Name',	o.name AS 'Table Name',	c1.name AS 'Column Name', NULL AS 'FK Table Name', NULL AS 'FK Column Name',
					NULL AS 'KeyNo', c.text AS 'Default/Check Value'
				FROM sysobjects o JOIN sysobjects o1 ON o1.Parent_obj = o.id
										JOIN syscolumns c1 ON c1.id = o1.parent_obj AND c1.colid = o1.info
										JOIN syscomments c ON o1.id = c.id
				WHERE o1.xtype In ('C' , 'D') AND o.id = @table_id
				UNION
				SELECT
					CASE o1.xtype WHEN 'C' THEN 'Check' WHEN 'D' THEN 'Default' WHEN 'F' THEN 'Foreign Key' WHEN 'PK' THEN 'Primary Key' WHEN 'UQ' THEN 'Unique' ELSE 'Other' END AS 'Constraint Type',
					o1.name AS 'Constraint Name', o.name AS 'FK Table Name', c1.name AS 'FK Column Name', o2.name AS 'Table Table', c2.name AS 'Column Name',
					fk.keyno AS 'KeyNo', NULL AS 'Default/Check Value'
				FROM sysobjects o JOIN sysobjects o1 ON o1.Parent_obj = o.id
										JOIN sysforeignkeys fk ON fk.constid = o1.id
										JOIN sysobjects o2 ON o2.id = fk.rkeyid
										LEFT JOIN syscolumns c1 ON c1.id = fk.fkeyid AND c1.colid = fk.fkey
										LEFT JOIN syscolumns c2 ON c2.id = fk.rkeyid AND c2.colid = fk.rkey
				WHERE o1.xtype = 'F' AND o.id = @table_id
				UNION
				SELECT
					CASE o1.xtype WHEN 'C' THEN 'Check' WHEN 'D' THEN 'Default' WHEN 'F' THEN 'Foreign Key' WHEN 'PK' THEN 'Primary Key' WHEN 'UQ' THEN 'Unique' ELSE 'Other' END AS 'Constraint Type',
					o1.name AS 'Constraint Name', o.name AS 'Table Name', c1.name AS 'Column Name', o2.name AS 'FK Table', c2.name AS 'FK Column Name',
					fk.keyno AS 'KeyNo', NULL AS 'Default/Check Value'
				FROM sysobjects o JOIN sysobjects o1 ON o1.Parent_obj = o.id
										JOIN sysforeignkeys fk ON fk.rkeyid = o.id
										JOIN sysobjects o2 ON o2.id = fk.fkeyid
										LEFT JOIN syscolumns c1 ON c1.id = fk.rkeyid AND c1.colid = fk.rkey
										LEFT JOIN syscolumns c2 ON c2.id = fk.rkeyid AND c2.colid = fk.rkey
				where o1.xtype = 'PK' AND o.id = @table_id
				) ORDER BY [Constraint Type]

		OPEN cursor_Constraint

		FETCH NEXT FROM cursor_Constraint INTO @CType,@CName,@CPKTable,@CPKColumn,@CFKTable,@CFKColumn,@CKey,@CDefault

			WHILE (@@FETCH_STATUS = 0)
				BEGIN

					IF @Populated = 0
					BEGIN
						PRINT @strHTML1
					END
					SET @Populated = 1

					SET @strHTML = '<TR><TD VALIGN="top">' + ISNULL(@CType, ' ') + ' </TD><TD VALIGN="top">' +
						ISNULL(@CName, ' ') + ' </TD><TD VALIGN="top">' +
						ISNULL(convert(varchar(120), @CPKTable), ' ') + ' </TD><TD VALIGN="top">' +
						ISNULL(convert(varchar(120), @CPKColumn), ' ') + ' </TD><TD VALIGN="top">' +
		      	   ISNULL(convert(varchar(120), @CFKTable), ' ') + ' </TD><TD VALIGN="top">' +
						ISNULL(convert(varchar(120), @CFKColumn), ' ') + ' </TD><TD VALIGN="top">' +
						ISNULL(convert(varchar(5), @CKey), ' ') + ' </TD><TD VALIGN="top">' +
						ISNULL(convert(varchar(20), @CDefault), ' ') + ' </TD></TR>'

					PRINT @strHTML

					FETCH NEXT FROM cursor_Constraint INTO @CType,@CName,@CPKTable,@CPKColumn,@CFKTable,@CFKColumn,@CKey,@CDefault
				END

		CLOSE cursor_Constraint
		DEALLOCATE cursor_Constraint

		SELECT @strHTML = '</TABLE>'

		PRINT @strHTML


		SET @strHTML1 = '<TABLE BORDER="0" CELLPADDING="2" CELLSPACING="0" BORDERCOLOUR="003366" WIDTH="100%">
				<TR BGCOLOR="EEEEEE"><TD CLASS="Sub" ALIGN="left" WIDTH="10%"><B>Triggers</B> </TD></TR>'

		SET @Populated = 0

		SET @strHTML = ''

		DECLARE cursor_Triggers CURSOR FOR
			SELECT [name] AS TriggerName FROM sysobjects WHERE xtype = 'TR' AND parent_obj = @table_id

		OPEN cursor_Triggers

		FETCH NEXT FROM cursor_Triggers INTO @Trigger

			WHILE (@@FETCH_STATUS = 0)
				BEGIN

					IF @Populated = 0
					BEGIN
						PRINT @strHTML1
					END
					SET @Populated = 1

					SET @strHTML = '<TR><TD VALIGN="top">' + ISNULL(@Trigger, ' ') + ' </TD> </TD></TR>'

					PRINT @strHTML

					FETCH NEXT FROM cursor_Triggers INTO @Trigger
				END

		CLOSE cursor_Triggers
		DEALLOCATE cursor_Triggers

		SELECT @strHTML = '</TABLE><BR><A CLASS="Index" HREF="#_top">Back To Top ^</A><BR><BR>'

		PRINT @strHTML

		FETCH NEXT FROM cursor_documentation INTO @table_id, @TableName
	END

CLOSE cursor_documentation
DEALLOCATE cursor_documentation

SELECT @strHTML = '<CENTER><FONT SIZE="5"><A NAME="_Views"><B>Views</B></A></FONT></CENTER><BR><BR>'

PRINT @strHTML

DECLARE cursor_views CURSOR FOR
	SELECT [name] FROM sysobjects WHERE [xtype] = 'V' AND [category] <> 2 ORDER BY [name]

OPEN cursor_views

FETCH NEXT FROM cursor_views INTO @ViewName

		WHILE (@@FETCH_STATUS = 0)
			BEGIN

				--Begin Table with view name as title
				SET @strHTML = '<DIV ALIGN="center"><TABLE BORDER="0" CELLPADDING="2" CELLSPACING="0" BORDERCOLOUR="003366" WIDTH="100%">
						<TR BGCOLOR="EEEEEE"><TD CLASS="Title" COLSPAN="7" ALIGN="center" VALIGN="top"><A NAME=#' + @ViewName + '><B>' + @ViewName + '</B></A> </TD></TR>
						<TR BGCOLOR="EEEEEE">
						  <TD ALIGN="left" WIDTH="20%"><B>Table Dependencies</B> </TD>
						  <TD ALIGN="left" WIDTH="25%"><B>Column Dependencies</B> </TD>
						  <TD ALIGN="left" WIDTH="20%"><B>Column Type</B> </TD>
						  <TD ALIGN="center" WIDTH="5%"><B>Size</B> </TD>
						  <TD ALIGN="center" WIDTH="5%"><B>Precision</B> </TD>
						  <TD ALIGN="center" WIDTH="5%"><B>Scale</B> </TD>
						  <TD ALIGN="left" WIDTH="20%"><B>Collation</B> </TD>
						</TR>'

				PRINT @strHTML

				SET @strHTML = ''

				DECLARE cursor_viewdeps CURSOR FOR
					SELECT TableSysObjects.name AS [Table],
                                          col.name AS [Column],
                                              systypes.[name],
                                          --(SELECT systypes.[name] FROM systypes WHERE xtype = col.xtype),
                                               col.length,col.prec,
					 col.scale, col.[collation]
						FROM sysobjects ViewSysObjects LEFT OUTER JOIN
			              sysdepends dep ON ViewSysObjects.id = dep.id LEFT OUTER JOIN
	       		        sysobjects TableSysObjects ON dep.depid = TableSysObjects.id LEFT OUTER JOIN
	             		  syscolumns col ON dep.depnumber = col.colid AND TableSysObjects.id = col.id
                                           JOIN systypes ON systypes.xtype = col.xtype
						WHERE ViewSysObjects.xtype = 'V' And ViewSysObjects.category = 0 AND ViewSysObjects.name = @ViewName
						ORDER BY ViewSysObjects.name,TableSysObjects.name,col.name


				OPEN cursor_viewdeps

				FETCH NEXT FROM cursor_viewdeps INTO @ViewTableDep,@ViewColDep,@ViewColDepType,@ViewColDepLength,@ViewColDepPrec,@ViewColDepScale,@ViewColDepCollation

						WHILE (@@FETCH_STATUS = 0)
							BEGIN

								-- Write the view dependencies

								SET @strHTML = '<TR><TD VALIGN="top">' + ISNULL(convert(varchar(200), @ViewTableDep), ' ') + ' </TD><TD VALIGN="top">' +
																					  ISNULL(convert(varchar(200), @ViewColDep), ' ') + ' </TD><TD VALIGN="top">' +
  																					  ISNULL(@ViewColDepType, ' ') + ' </TD><TD VALIGN="top">' +
																					  ISNULL(convert(varchar(5), @ViewColDepLength), ' ') + ' </TD><TD VALIGN="top">' +
																					  ISNULL(convert(varchar(5), @ViewColDepPrec), ' ') + ' </TD><TD VALIGN="top">' +
																					  ISNULL(convert(varchar(5), @ViewColDepScale), ' ') + ' </TD><TD VALIGN="top">' +
																	      	     ISNULL(@ViewColDepCollation, ' ') + ' </TD></TR>'

								PRINT @strHTML

							FETCH NEXT FROM cursor_viewdeps INTO @ViewTableDep,@ViewColDep,@ViewColDepType,@ViewColDepLength,@ViewColDepPrec,@ViewColDepScale,@ViewColDepCollation
						END
				CLOSE cursor_viewdeps
				DEALLOCATE cursor_viewdeps

		  		SELECT @strHTML = '</TABLE></DIV><BR><A CLASS="Index" HREF="#_top">Back To Top ^</A><BR><BR>'

				PRINT @strHTML

				FETCH NEXT FROM cursor_views INTO @ViewName
			END
CLOSE cursor_views
DEALLOCATE cursor_views

				SELECT @strHTML = '<CENTER><FONT SIZE="5"><A NAME="_SP"><B>Stored Procedures</B></A></FONT></CENTER><BR><BR>'

				PRINT @strHTML

				DECLARE cursor_sp CURSOR FOR
					SELECT [name] FROM sysobjects WHERE [xtype] = 'P' AND [category] <> 2 ORDER BY [name]

				OPEN cursor_sp

				FETCH NEXT FROM cursor_sp INTO @SPName

						WHILE (@@FETCH_STATUS = 0)
							BEGIN

								--Begin Table with view name as title
								SET @strHTML = '<DIV ALIGN="center"><TABLE BORDER="0" CELLPADDING="2" CELLSPACING="0" BORDERCOLOUR="003366" WIDTH="100%">
										<TR BGCOLOR="#EEEEEE"><TD CLASS="Title" COLSPAN="7" ALIGN="left" VALIGN="top"><CENTER><A NAME=#' + @SPName + '><B>' + @SPName + '</B></A></CENTER>'

								PRINT @strHTML

								SET @Populated = 0
								SET @strHTML1 = '<FONT SIZE="1"><BR></FONT><DIV ALIGN="center"><TABLE BORDER="0" CELLPADDING="2" CELLSPACING="0" BORDERCOLOUR="003366" WIDTH="50%"><TR><TD COLSPAN="3" ALIGN="center"><B>Parameters</B> </TD></TR>'
								DECLARE cursor_Params CURSOR FOR
									SELECT rtrim(c.name) PARAMETER ,
											 rtrim(convert(varchar (50),d.name) +
												case when d.system_type_id = 129 /*DBTYPE_STR*/ or d.system_type_id = 128 /*DBTYPE_BYTES*/
												          then '(' + convert(varchar (10),coalesce(d.max_length,c.length)) + ')'
												     when d.system_type_id = 130 /*DBTYPE_WSTR*/
													  then '(' +  convert(varchar(10), coalesce(d.max_length,c.length/2)) + ')'
												     else''
												end ) DATA_TYPE,
												case when c.isoutparam =1
												     then 'Output'
												     else 'Input  '
												end as "Type"
									FROM sysobjects o
										INNER JOIN sysobjects od ON od.id = o.id
										LEFT OUTER JOIN syscolumns c ON o.id = c.id AND o.type = 'P'
										LEFT OUTER JOIN sys.types d ON c.xtype = d.system_type_id
									WHERE c.length = case when d.max_length > 0 then d.max_length else c.length end AND o.name = @SPName

								OPEN cursor_Params

								FETCH NEXT FROM cursor_Params INTO @ParamName,@ParamDataType,@ParamType

								WHILE (@@FETCH_STATUS = 0)
									BEGIN
										IF @Populated = 0
										BEGIN
											PRINT @strHTML1
										END
										SET @Populated = 1

										SET @strHTML = '<TR BGCOLOR="#FFFFFF"><TD VALIGN="top" WIDTH="20%">' + ISNULL(convert(varchar(200), @ParamType), ' ') + ' </TD><TD VALIGN="top" WIDTH="40%">' + ISNULL(convert(varchar(200), @ParamName), ' ') + ' </TD><TD VALIGN="top" WIDTH="40%">' + ISNULL(convert(varchar(200), @ParamDataType), ' ') + ' </TD></TR>'

										--SET @strHTML = '<BR><FONT SIZE="2" STYLE="FONT-WEIGHT:normal">' + @ParamType + ' - ' + @ParamName + '  ' + @ParamDataType + '</FONT>'

										PRINT @strHTML
										FETCH NEXT FROM cursor_Params INTO @ParamName,@ParamDataType,@ParamType

									END
								CLOSE cursor_Params
								DEALLOCATE cursor_Params

								IF @Populated = 1
								BEGIN
									PRINT '</TABLE></DIV>'
								END

								SET @strHTML = ' </TD></TR>
										<TR BGCOLOR="EEEEEE">
										  <TD ALIGN="left" WIDTH="20%"><B>Table Dependencies</B> </TD>
										  <TD ALIGN="left" WIDTH="25%"><B>Column Dependencies</B> </TD>
										  <TD ALIGN="left" WIDTH="20%"><B>Column Type</B> </TD>
										  <TD ALIGN="center" WIDTH="5%"><B>Size</B> </TD>
										  <TD ALIGN="center" WIDTH="5%"><B>Precision</B> </TD>
										  <TD ALIGN="center" WIDTH="5%"><B>Scale</B> </TD>
										  <TD ALIGN="left" WIDTH="20%"><B>Collation</B> </TD>
										</TR>'

								PRINT @strHTML

								SET @strHTML = ''

								DECLARE cursor_spdeps CURSOR FOR
									SELECT TableSysObjects.name AS [Table],
                                                                           col.name AS [Column],
  --                                                                            ' ',
                                                                                systypes.[name],
--select * from syscolumns

--                                                                              (SELECT systypes.[name] FROM systypes,syscolumns col WHERE systypes.xtype = col.xtype),


                                                                                  col.length,col.prec,
									 col.scale, col.[collation]
										FROM sysobjects ViewSysObjects LEFT OUTER JOIN
							              sysdepends dep ON ViewSysObjects.id = dep.id LEFT OUTER JOIN
					       		        sysobjects TableSysObjects ON dep.depid = TableSysObjects.id LEFT OUTER JOIN

					             		  syscolumns col ON dep.depnumber = col.colid AND TableSysObjects.id = col.id
                                                                        JOIN systypes ON systypes.xtype = col.xtype
										WHERE ViewSysObjects.xtype = 'P' And ViewSysObjects.category = 0 AND ViewSysObjects.name = @SPName
										ORDER BY ViewSysObjects.name,TableSysObjects.name,col.name


								OPEN cursor_spdeps

								FETCH NEXT FROM cursor_spdeps INTO @SPTableDep,@SPColDep,@SPColDepType,@SPColDepLength,@SPColDepPrec,@SPColDepScale,@SPColDepCollation

										WHILE (@@FETCH_STATUS = 0)
											BEGIN

												-- Write the view dependencies
												IF @SPColDep = ''
												BEGIN
													SET @SPColDep = ' '
												END

												SET @strHTML = '<TR><TD VALIGN="top">' + ISNULL(convert(varchar(200), @SPTableDep), ' ') + ' </TD><TD VALIGN="top">' +
																									  ISNULL(convert(varchar(200), @SPColDep), ' ') + ' </TD><TD VALIGN="top">' +
				  																					  ISNULL(@SPColDepType, ' ') + ' </TD><TD VALIGN="top">' +
																									  ISNULL(convert(varchar(5), @SPColDepLength), ' ') + ' </TD><TD VALIGN="top">' +
																									  ISNULL(convert(varchar(5), @SPColDepPrec), ' ') + ' </TD><TD VALIGN="top">' +
																									  ISNULL(convert(varchar(5), @SPColDepScale), ' ') + ' </TD><TD VALIGN="top">' +
																					      	     ISNULL(@SPColDepCollation, ' ') + ' </TD></TR>'

												PRINT @strHTML

											FETCH NEXT FROM cursor_spdeps INTO @SPTableDep,@SPColDep,@SPColDepType,@SPColDepLength,@SPColDepPrec,@SPColDepScale,@SPColDepCollation
										END
								CLOSE cursor_spdeps
								DEALLOCATE cursor_spdeps

						  		SELECT @strHTML = '</TABLE></DIV><BR><A CLASS="Index" HREF="#_top">Back To Top ^</A><BR><BR>'

								PRINT @strHTML

								FETCH NEXT FROM cursor_sp INTO @SPName
							END
				CLOSE cursor_sp
				DEALLOCATE cursor_sp

SELECT @strHTML = '</BODY></HTML>'
PRINT @strHTML