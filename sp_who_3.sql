USE master
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON

EXEC sp_configure 'allow updates', 1
EXEC sp_MS_upd_sysobj_category 1
RECONFIGURE WITH OVERRIDE
GO

IF EXISTS (SELECT id
	FROM dbo.sysobjects
	WHERE uid = USER_ID('system_function_schema')
		AND name = 'fn_view_input_buffer')
DROP FUNCTION system_function_schema.fn_view_input_buffer
GO
-------------------------------------------------------------------------------------------------------
-- OBJECT NAME		: fn_view_input_buffer
-- AUTHOR		: Mike A. Barzilli
-- AUTHOR EMAIL		: mike@barzilli.com
-- DATE			: 09/04/2002
--
-- INPUTS		: @server_object_id, @spid, @sql_handle
--
-- OUTPUTS		: @input_buffer
--
-- DEPENDENCIES		: master.dbo.sp_oagetproperty xp, fngetsql Open Rowset
--
-- DESCRIPTION		:
-- This function returns the input buffer for the @spid passed in. It requires the
-- @server_object_id to be a valid object_id of a local SQL server connection. The
-- calling procedure has to open and close the @server_object_id. This function uses
-- the SQLSERVER SQLDMO object passed in to retrieve the input buffer. This is a
-- work-around. However, the connection is local, quick, and in memory only. If the
-- spid has a valid sql_handle, this procedure will instead use the new fngetsql.
-- System spids (below 51) or with ecid greater than zero should not be passed in
-- because these don't have input buffers.
--
-- This is a work-around because the input buffer cannot be returned directly without
-- using tempdb, cursors, or other expensive measures. If input buffer was accessible
-- in a table or a function, this would not be needed. Using sp_oacreate is not
-- recommended because it runs in-process, wastes resources, and may crash the server
-- if it errors out. The risks are minimized because only built-in objects are used.
-- This function is normally called from other stored procedures.
--
-- MODIFICATION HISTORY	:
-------------------------------------------------------------------------------------------------------
-- 09/04/2002 - Mike A. Barzilli
-- Created function.
--
-- 09/04/2002 - Mike A. Barzilli
-- Modified function to change the output to varchar(7,500). This was done because of errors when
-- sorting the sp_who_3 results when all the columns had the maximum allowable data filled in.
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------

CREATE FUNCTION system_function_schema.fn_view_input_buffer
	(@server_object_id INT,
	@spid SMALLINT,
	@sql_handle BINARY(20))
	RETURNS VARCHAR(7500) AS

BEGIN
DECLARE
	@input_buffer VARCHAR(7500)

-------------------------------------------------------------------------------------------------------
-- If the @sql_handle is available, use it because it is faster and gets more than 255 characters.
-------------------------------------------------------------------------------------------------------
IF @sql_handle <> 0x00
	BEGIN
		SELECT @input_buffer = CAST(text AS VARCHAR(7500))
			FROM OPENROWSET(fngetsql, @sql_handle)
			WHERE encrypted = 0
	END

IF @input_buffer IS NULL
	BEGIN
		EXEC master.dbo.sp_OAGetProperty
			@server_object_id,
			'ProcessInputBuffer',
			@input_buffer OUT,
			@spid
	END

RETURN ISNULL(NULLIF(@input_buffer, ''), '.')
END
GO

IF OBJECT_ID(N'dbo.sv_sysprocesses') IS NOT NULL
DROP VIEW dbo.sv_sysprocesses
GO
-------------------------------------------------------------------------------------------------------
-- OBJECT NAME		: sv_sysprocesses
-- AUTHOR		: Mike A. Barzilli
-- AUTHOR EMAIL		: mike@barzilli.com
-- DATE			: 09/04/2002
--
-- INPUTS		: none
--
-- OUTPUTS		: view
--
-- DEPENDENCIES		: master.dbo.sysprocesses table
--
-- DESCRIPTION		:
-- This view is used to return sysprocesses information. It will trim the length
-- of the columns and substitute "." for NULL values in some of the columns.
--
-- MODIFICATION HISTORY	:
-------------------------------------------------------------------------------------------------------
-- 09/04/2002 - Mike A. Barzilli
-- Created view.
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------

CREATE VIEW dbo.sv_sysprocesses AS

SELECT
	spid + CAST(N'.' + RIGHT(N'0' + CAST(ecid AS NVARCHAR(2)), 2) AS DECIMAL(7,2)) AS SPID,

	CASE
		WHEN loginame = '' THEN N'.'
		ELSE RTRIM(LEFT(loginame, 25))
	END AS Login,

	CASE
		WHEN hostname = '' THEN N'.'
		ELSE RTRIM(LEFT(hostname, 12))
	END AS Host,

	CASE
		WHEN dbid = 0 THEN N'.'
		ELSE RTRIM(LEFT(DB_NAME(dbid), 25))
	END AS DB,

	CASE
		WHEN program_name = '' THEN N'.'
		ELSE RTRIM(LEFT(program_name, 25))
	END AS Program,

	CASE
		WHEN LOWER(status) = 'sleeping' THEN N'sleeping'
		ELSE RTRIM(LEFT(UPPER(status), 12))
	END AS Status,

	CASE
		WHEN cmd = '' THEN N'.'
		ELSE RTRIM(cmd)
	END AS Command,

	CASE
		WHEN blocked = 0 THEN N'.'
		ELSE CAST(blocked AS NVARCHAR(5))
	END AS Blk,

	CASE
		WHEN waittype = 0x00 THEN N'.'
		ELSE SUBSTRING(lastwaittype, 0, LEN(lastwaittype)) +
			N' (' + CAST(waittime AS NVARCHAR(10)) + N')'
	END AS Wait,

	CASE
		WHEN open_tran = 0 THEN N'.'
		ELSE CAST(open_tran AS NVARCHAR(5))
	END AS Trans,

	cpu AS CPU,

	physical_io AS Dsk,

	CONVERT(NVARCHAR(8), last_batch, 1) + N' ' +
	CONVERT(NVARCHAR(8), last_batch, 114) AS Last_Batch,

	spid AS SP2,

	sql_handle AS sql_handle

FROM master.dbo.sysprocesses WITH (NOLOCK)
GO

GRANT SELECT ON dbo.sv_sysprocesses TO public
GO

IF OBJECT_ID(N'dbo.sv_block') IS NOT NULL
DROP VIEW dbo.sv_block
GO
-------------------------------------------------------------------------------------------------------
-- OBJECT NAME		: sv_block
-- AUTHOR		: Mike A. Barzilli
-- AUTHOR EMAIL		: mike@barzilli.com
-- DATE			: 09/04/2002
--
-- INPUTS		: none
--
-- OUTPUTS		: view
--
-- DEPENDENCIES		: master.dbo.sysprocesses table
--
-- DESCRIPTION		:
-- This view is used to return sysprocesses that are currently being blocked. It will return the
-- distinct list of SPIDs from sysprocesses table that are currently blocking other processes.
--
-- MODIFICATION HISTORY	:
-------------------------------------------------------------------------------------------------------
-- 09/04/2002 - Mike A. Barzilli
-- Created view.
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------

CREATE VIEW dbo.sv_block AS

SELECT DISTINCT
	blocked

FROM master.dbo.sysprocesses WITH (NOLOCK)

WHERE blocked <> 0
GO

GRANT SELECT ON dbo.sv_block TO public
GO

IF OBJECT_ID(N'dbo.sp_who_3') IS NOT NULL
DROP PROC dbo.sp_who_3
GO
-------------------------------------------------------------------------------------------------------
-- OBJECT NAME		: sp_who_3
-- AUTHOR		: Mike A. Barzilli
-- AUTHOR EMAIL		: mike@barzilli.com
-- DATE			: 09/04/2002
--
-- INPUTS		: @run_mode, @spid, @login, @host, @db, @program,
--			: @status, @command, @blk, @wait, @trans, @cpu, @dsk,
--			: @last_batch, @o
--
-- OUTPUTS		: rows from sv_sysprocesses
--
-- DEPENDENCIES		: master.dbo.sv_sysprocesses view, master.dbo.sv_block view,
--			: master.dbo.fn_view_input_buffer function
--
-- DESCRIPTION		:
-- This procedure will return a list of processes that are running on the SQL Server. This
-- procedure was written to avoid using sp_who, sp_who2, sp_lock, sp_lockinfo, and dbcc
-- inputbuffer. It has various input parameters to control filtering and ordering of the
-- results. It also provides 6 different run modes. Use @run_mode of "help" for more details.
--
-- When one of the "input" run modes is used, it creates an SQLDMO object that is passed
-- to a function. It opens a trusted connection (using the SQL Service Account) to the
-- local server. Once complete, it closes the SQLDMO object. sp_who_3 only works with SQL
-- 2000 SP3 or higher. This procedure is normally called from Query Analyzer by DBAs.
--
-- MODIFICATION HISTORY	:
-------------------------------------------------------------------------------------------------------
-- 09/04/2002 - Mike A. Barzilli
-- Created procedure.
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------

CREATE PROC dbo.sp_who_3
	@run_mode NVARCHAR(12) = NULL,
	@spid NVARCHAR(50) = NULL,
	@login NVARCHAR(50) = NULL,
	@host NVARCHAR(50) = NULL,
	@db NVARCHAR(50) = NULL,
	@program NVARCHAR(50) = NULL,
	@status NVARCHAR(50) = NULL,
	@command NVARCHAR(50) = NULL,
	@blk NVARCHAR(50) = NULL,
	@wait NVARCHAR(50) = NULL,
	@trans NVARCHAR(50) = NULL,
	@cpu NVARCHAR(50) = NULL,
	@dsk NVARCHAR(50) = NULL,
	@last_batch NVARCHAR(100) = NULL,
	@o NVARCHAR(100) = NULL AS

-------------------------------------------------------------------------------------------------------
-- Setup all initial input parameters, perform parameter validation, and setup default values.
-------------------------------------------------------------------------------------------------------
SET NOCOUNT ON
SET IMPLICIT_TRANSACTIONS OFF
DECLARE
	@select_statement NVARCHAR(2000),
	@server_object_id INT,
	@error_code INT

-------------------------------------------------------------------------------------------------------
-- Initialize input parameters that are text strings.
-------------------------------------------------------------------------------------------------------
SELECT
	@login = REPLACE(@login, '''', N''''''),
	@host = REPLACE(@host, '''', N''''''),
	@db = REPLACE(@db, '''', N''''''),
	@program = REPLACE(@program, '''', N''''''),
	@status = REPLACE(@status, '''', N''''''),
	@command = REPLACE(@command, '''', N''''''),
	@wait = REPLACE(@wait, '''', N'''''')

-------------------------------------------------------------------------------------------------------
-- Initialize input parameters that are numeric fields which allow less than/greater than searches.
-------------------------------------------------------------------------------------------------------
SELECT
	@spid = CASE
			WHEN @spid IS NULL
				THEN NULL
			WHEN PATINDEX('%[-/*;''"]%', @spid) >= 1
				THEN N'error'
			WHEN ISNUMERIC(@spid) = 1
				THEN N'= ' + @spid
			WHEN LTRIM(RTRIM(SUBSTRING(@spid, 0, PATINDEX('%[0123456789]%', @spid))))
					IN ('=', '<>', '!=', '>', '<', '>=', '!<', '<=', '!>')
					AND ISNUMERIC(SUBSTRING(@spid, PATINDEX('%[0123456789]%', @spid), 50)) = 1
				THEN @spid
			ELSE N'error'
		END,
	@blk = CASE
			WHEN @blk IS NULL
				THEN NULL
			WHEN PATINDEX('%[-/*;''"]%', @blk) >= 1
				THEN N'error'
			WHEN ISNUMERIC(@blk) = 1
				THEN N'= ' + @blk
			WHEN LTRIM(RTRIM(SUBSTRING(@blk, 0, PATINDEX('%[0123456789]%', @blk))))
					IN ('=', '<>', '!=', '>', '<', '>=', '!<', '<=', '!>')
					AND ISNUMERIC(SUBSTRING(@blk, PATINDEX('%[0123456789]%', @blk), 50)) = 1
				THEN @blk
			ELSE N'error'
		END,
	@trans = CASE
			WHEN @trans IS NULL
				THEN NULL
			WHEN PATINDEX('%[-/*;''"]%', @trans) >= 1
				THEN N'error'
			WHEN ISNUMERIC(@trans) = 1
				THEN N'= ' + @trans
			WHEN LTRIM(RTRIM(SUBSTRING(@trans, 0, PATINDEX('%[0123456789]%', @trans))))
					IN ('=', '<>', '!=', '>', '<', '>=', '!<', '<=', '!>')
					AND ISNUMERIC(SUBSTRING(@trans, PATINDEX('%[0123456789]%', @trans), 50)) = 1
				THEN @trans
			ELSE N'error'
		END,
	@cpu = CASE
			WHEN @cpu IS NULL
				THEN NULL
			WHEN PATINDEX('%[-/*;''"]%', @cpu) >= 1
				THEN N'error'
			WHEN ISNUMERIC(@cpu) = 1
				THEN N'= ' + @cpu
			WHEN LTRIM(RTRIM(SUBSTRING(@cpu, 0, PATINDEX('%[0123456789]%', @cpu))))
					IN ('=', '<>', '!=', '>', '<', '>=', '!<', '<=', '!>')
					AND ISNUMERIC(SUBSTRING(@cpu, PATINDEX('%[0123456789]%', @cpu), 50)) = 1
				THEN @cpu
			ELSE N'error'
		END,
	@dsk = CASE
			WHEN @dsk IS NULL
				THEN NULL
			WHEN PATINDEX('%[-/*;''"]%', @dsk) >= 1
				THEN N'error'
			WHEN ISNUMERIC(@dsk) = 1
				THEN N'= ' + @dsk
			WHEN LTRIM(RTRIM(SUBSTRING(@dsk, 0, PATINDEX('%[0123456789]%', @dsk))))
					IN ('=', '<>', '!=', '>', '<', '>=', '!<', '<=', '!>')
					AND ISNUMERIC(SUBSTRING(@dsk, PATINDEX('%[0123456789]%', @dsk), 50)) = 1
				THEN @dsk
			ELSE N'error'
		END

-------------------------------------------------------------------------------------------------------
-- Initialize input parameters that require custom handling.
-------------------------------------------------------------------------------------------------------
SELECT
	@run_mode = CASE
			WHEN LOWER(@run_mode) = 'input active'
				THEN 'active input'
			WHEN LOWER(@run_mode) = 'input block'
				THEN 'block input'
			ELSE LOWER(ISNULL(@run_mode, N'normal'))
		END,
	@last_batch = CASE
			WHEN @last_batch IS NULL
				THEN NULL
			WHEN PATINDEX('%[-*;''"]%', @last_batch) >= 1
					OR DATALENGTH(@last_batch) > 100
				THEN N'error'
			WHEN ISDATE(@last_batch) = 1
				THEN N'= CAST(''' + @last_batch + ''' AS DATETIME)'
			WHEN LTRIM(RTRIM(SUBSTRING(@last_batch, 0, PATINDEX('%[0123456789]%', @last_batch))))
					IN ('=', '<>', '!=', '>', '<', '>=', '!<', '<=', '!>')
					AND ISDATE(SUBSTRING(@last_batch, PATINDEX('%[0123456789]%', @last_batch), 50)) = 1
				THEN SUBSTRING(@last_batch, 0, PATINDEX('%[0123456789]%', @last_batch)) +
					'CAST(''' + SUBSTRING(@last_batch, PATINDEX('%[0123456789]%', @last_batch), 50) + ''' AS DATETIME)'
			ELSE N'error'
		END,
	@o = CASE
 			WHEN @o IS NULL
 				THEN N' ORDER BY SPID ASC'
			WHEN PATINDEX('%[-/*;''"]%', @o) >= 1
					OR LOWER(@o) LIKE '%order%'
					OR DATALENGTH(@o) > 100
				THEN N'error'
			ELSE N' ORDER BY ' + @o + N', ''a'' ASC'
		END,
	@error_code = 0

-------------------------------------------------------------------------------------------------------
-- Validate the @o parameter (order by clause) and prevent any malicious code injection.
-------------------------------------------------------------------------------------------------------
IF @o <> 'error'
	BEGIN
		SET @select_statement = N'SET NOEXEC ON  SELECT SPID, Login, Host, DB, Program, Status, Command, Blk, Wait, Trans, CPU, Dsk, Last_Batch, ' +
			CASE
				WHEN @run_mode IN ('input', 'active input', 'block input')
					THEN '0 AS Input_Buffer, SP2 '
				ELSE 'SP2 '
			END +
			'FROM master.dbo.sv_sysprocesses' + @o + N'  SET NOEXEC OFF'

		EXEC @error_code = sp_executesql @select_statement

		SELECT @o = N'error', @error_code = 1
			WHERE @error_code <> 0
	END

-------------------------------------------------------------------------------------------------------
-- Check for any errors and raise them now.
-------------------------------------------------------------------------------------------------------
IF @run_mode IN ('input', 'active input', 'block input')
		AND IS_SRVROLEMEMBER('processadmin') = 0
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(15003, -1, -1, 'sysadmin or processadmin')
	END

IF @run_mode NOT IN ('normal', 'active', 'input', 'block', 'active input', 'block input', 'help', '?')
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(14266, -1, -1, '@run_mode', '"normal", "active", "input", "block", "active input", "block input", and "help"')
	END

IF @@TRANCOUNT > 0
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(15002, -1, -1, 'sp_who_3')
	END

IF @spid = 'error'
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(14266, -1, -1, '@spid', 'Comparison Operators and Numbers following the procedure''s rules')
	END

IF @blk = 'error'
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(14266, -1, -1, '@blk', 'Comparison Operators and Numbers following the procedure''s rules')
	END

IF @trans = 'error'
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(14266, -1, -1, '@trans', 'Comparison Operators and Numbers following the procedure''s rules')
	END

IF @cpu = 'error'
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(14266, -1, -1, '@cpu', 'Comparison Operators and Numbers following the procedure''s rules')
	END

IF @dsk = 'error'
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(14266, -1, -1, '@dsk', 'Comparison Operators and Numbers following the procedure''s rules')
	END

IF @last_batch = 'error'
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(14266, -1, -1, '@last_batch', 'Comparison Operators and a valid date following the procedure''s rules (up to 50 characters)')
	END

IF @o = 'error'
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(14266, -1, -1, '@o', 'Columns to be used in the order by clause (up to 50 characters)')
	END

-------------------------------------------------------------------------------------------------------
-- Create the portion of the SELECT clause with the list of columns and the FROM clause.
-------------------------------------------------------------------------------------------------------
SET @select_statement = N'SELECT SPID, Login, Host, DB, Program, Status, Command, Blk, Wait, Trans, CPU, Dsk, Last_Batch, ' +
	CASE
		WHEN @run_mode IN ('input', 'active input', 'block input')
			THEN N'CASE
					WHEN SPID < 51 OR SPID <> SP2
						THEN ''.''
					ELSE fn_view_input_buffer(@server_object_id, SP2, sql_handle)
				END AS Input_Buffer, '
		ELSE N''
	END +
	N'SP2 FROM master.dbo.sv_sysprocesses WITH (NOLOCK) '

-------------------------------------------------------------------------------------------------------
-- Create the portion of the WHERE clause and apply all filter parameters passed in or by run mode.
-------------------------------------------------------------------------------------------------------
SET @select_statement = @select_statement +
	CASE
		WHEN @run_mode IN ('normal', 'input')
			THEN N'WHERE' +
				CASE
					WHEN @spid IS NULL
						THEN N''
					WHEN @spid LIKE '%.%'
						THEN N' SPID ' + @spid + N' AND '
					ELSE N' SP2 ' + @spid + N' AND '
				END +
				ISNULL(N' Login LIKE ''' + @login + N''' AND ', '') +
				ISNULL(N' Host LIKE ''' + @host + N''' AND ', '') +
				ISNULL(N' DB LIKE ''' + @db + N''' AND ', '') +
				ISNULL(N' Program LIKE ''' + @program + N''' AND ', '') +
				ISNULL(N' Status LIKE ''' + @status + N''' AND ', '') +
				ISNULL(N' Command LIKE ''' + @command + N''' AND ', '') +
				ISNULL(N' REPLACE(Blk, ''.'', N''0'') ' + @blk + N' AND ', '') +
				ISNULL(N' Wait LIKE ''' + @wait + N''' AND ', '') +
				ISNULL(N' REPLACE(Trans, ''.'', N''0'') ' + @trans + N' AND ', '') +
				ISNULL(N' CPU ' + @cpu + N' AND ', '') +
				ISNULL(N' Dsk ' + @dsk + N' AND ', '') +
				ISNULL(N' Last_Batch ' + @last_batch + N' AND ', '')

		WHEN @run_mode IN ('active', 'active input')
			THEN N'WHERE Status NOT IN (''sleeping'', ''BACKGROUND'')
				OR (Command <> ''AWAITING COMMAND''
					AND SP2 > 50)
				OR Blk <> ''.''
				OR Wait <> ''.''
				OR Trans <> ''.'''

		ELSE N'LEFT OUTER JOIN sv_block WITH (NOLOCK)
				ON sv_sysprocesses.SP2 = sv_block.blocked
			WHERE sv_block.blocked IS NOT NULL
				OR Blk <> ''.'''
	END

-------------------------------------------------------------------------------------------------------
-- Create the portion of the ORDER BY clause and remove and leftovers from the WHERE clause.
-------------------------------------------------------------------------------------------------------
SET @select_statement =
	CASE
		WHEN @run_mode IN ('normal', 'input')
			THEN LEFT(@select_statement, (DATALENGTH(@select_statement)/2) - 5) + @o
		ELSE @select_statement + @o
	END

-------------------------------------------------------------------------------------------------------
-- If using one of the "input" run modes then do these steps:
-- 1.) Create and open the SQLDMO connection. Then run the dynamic SELECT statement created earlier.
-- 2.) Close and destroy the SQLDMO connection created in step 1.
-------------------------------------------------------------------------------------------------------
IF @run_mode IN (N'input', N'active input', N'block input')
	BEGIN
		EXEC master.dbo.sp_OACreate 'sqldmo.sqlserver', @server_object_id OUT
		EXEC master.dbo.sp_OASetProperty @server_object_id, 'loginsecure', 'true'
		EXEC master.dbo.sp_OASetProperty @server_object_id, 'applicationname', 'sp_who_3 Input Buffers'
		EXEC master.dbo.sp_OAMethod @server_object_id, 'connect', null, @@SERVERNAME
		EXEC master.dbo.sp_executesql @select_statement, N'@server_object_id INT', @server_object_id
		EXEC master.dbo.sp_OAMethod @server_object_id, 'disconnect'
		EXEC master.dbo.sp_OADestroy @server_object_id
	END

-------------------------------------------------------------------------------------------------------
-- If Not using one of the "input" run modes then only run the dynamic SELECT statement created earlier.
-------------------------------------------------------------------------------------------------------
IF @run_mode IN (N'normal', N'active', N'block')
	BEGIN
		EXEC master.dbo.sp_executesql @select_statement
	END

-------------------------------------------------------------------------------------------------------
-- Display the help section if the run mode specified is "help" or any errors were encountered.
-------------------------------------------------------------------------------------------------------
IF @run_mode IN (N'help', N'?')
	BEGIN
		PRINT ('
AUTHOR			: Mike A. Barzilli
AUTHOR EMAIL		: mike@barzilli.com

sp_who_3:
	Provides information about current SQL Server processes. The results can be filtered and sorted
	in many ways. It has 6 run modes which filter the information to specific needs.

	This procedure was written to avoid using sp_who, sp_who2, sp_lock, sp_lockinfo, and dbcc
	inputbuffer. Those procedures are not flexible and hang if tempdb is itself locked. sp_who_3
	returns the results without any performance or lock compromising steps such as temp tables,
	cursors, table parameters, or any locks. sp_who_3 only works with SQL Server 2000 Service Pack
	3 or higher. sp_who_3 is best viewed in grid mode.

Syntax:
	EXEC sp_who_3 [ [ @run_mode = ] ''run mode'' ]
		[ , [ @spid = ] ''SPID'' ]
		[ , [ @login = ] ''login name'' ]
		[ , [ @host = ] ''host name'' ]
		[ , [ @db = ] ''database name'' ]
		[ , [ @program = ] ''program name'' ]
		[ , [ @status = ] ''status'' ]
		[ , [ @command = ] ''command'' ]
		[ , [ @blk = ] ''blocking SPID'' ]
		[ , [ @wait = ] ''wait type and wait time (msecs)'' ]
		[ , [ @trans = ] ''open transactions'' ]
		[ , [ @cpu = ] ''CPU time usage'' ]
		[ , [ @dsk = ] ''disk usage'' ]
		[ , [ @last_batch = ] ''last batch date and time'' ]
		[ , [ @o = ] ''order by clause'' ]

Arguments:
	[ @run_mode = ] ''run_mode''
		Is the mode to use. @run_mode is NVARCHAR(12), with a default of "normal". Valid values
		are: "normal", "active", "input", "block", "active input", "block input", and "help".
		When using "active", "block", "active input", or "block input", any filters specified
		are ignored. Sort order can always be specified.

		A run mode of "normal" returns all current connections and those results are filtered
		by all 13 filter parameters if any filter conditions are specified.

		Run mode "active" returns only active connections or ones with open transactions. All
		filter parameters are ignored.

		Run mode "input" is similar to "normal" but it also returns the input buffer. Only
		sysadmin or processadmin members can use this mode. This mode creates an SQLDMO object
		that is passed to a function. It opens a trusted connection (using the SQL Service
		Account) to the local server. Once complete, it closes the SQLDMO object. Using
		sp_oacreate is not recommended because it runs in-processes, wastes resources, and may
		crash the server if errors occur. These risks are minimized because only built-in Tools
		objects are used. The results are filtered by all 13 filter parameters if specified.

		Run mode "block" returns only connections that are either being blocked or are blocking
		other processes. All filter parameters are ignored.

		Run mode "active input" combines "active" and "input" modes. It returns active
		connections with input buffers. Only sysadmin or processadmin members can use this
		mode. The same "input" function is used. All filter parameters are ignored.

		Run mode "block input" combines "block" and "input" modes. It returns blocked
		connections with input buffers. Only sysadmin or processadmin members can use this
		mode. The same "input" function is used. All filter parameters are ignored.

		Run mode "help" only returns information about how to use sp_who_3.

	[ @spid = ] ''SPID''
		Is the SPID used to filter the results. @spid is DECIMAL(7,2), with a default of NULL.
		The input parameter @spid is NVARCHAR(50) to allow Comparison Operators ("=", "<>",
		"!=", ">", "<", ">=", "!<", "<=", "!>") to be specified. This is one of 13 possible
		filters. For all numerical filters, if a Comparison Operator is not specified and only
		a numerical value is passed in, sp_who_3 defaults to an equal comparison. When using
		the @spid filter on SPIDs that have multiple ECIDs {.00, .01, ...n}, use a whole
		number SPID (I.E. 1, 2, etc...) to return the SPIDs and all their sub-threads. If a
		decimal is used instead (I.E. 1.00, 2.01, etc...), only SPIDs matching both the SPID
		and ECID portions are returned. All filters are ignored when run_mode is "active",
		"block", "active input", or "block input".

	[ @login = ] ''login name''
		Is the login name used to filter the results. @login is NVARCHAR(25), with a default of
		NULL. The input parameter @login is NVARCHAR(50) to allow Wildcard Operators ("%", "_",
		"[]", "[n-n]", "[^]") to be specified. @login and all non-numeric filters will get
		Search Predicate (such as "=" or the keyword "LIKE") added to them internally. Do not
		include Search Predicates in these parameters.

	[ @host = ] ''host name''
		Is the host name used to filter the results. @host is NVARCHAR(12), with a default of
		NULL. The input parameter @host is NVARCHAR(50) to allow Wildcard Operators ("%", "_",
		etc...) to be specified.

	[ @db = ] ''database name''
		Is the database name used to filter the results. @db is NVARCHAR(25), with a default of
		NULL. The input parameter @db is NVARCHAR(50) to allow Wildcard Operators ("%", "_",
		etc...) to be specified.

	[ @program = ] ''program name''
		Is the program name used to filter the results. @program is NVARCHAR(25), with a
		default of NULL. The input parameter @program is NVARCHAR(50) to allow Wildcard
		Operators ("%", "_", etc...) to be specified.

	[ @status = ] ''status''
		Is the status used to filter the results. @status is NVARCHAR(12), with a default of
		NULL. The input parameter @status is NVARCHAR(50) to allow Wildcard Operators ("%",
		"_", etc...) to be specified.

	[ @command = ] ''command''
		Is the command used to filter the results. @command is NVARCHAR(16), with a default of
		NULL. The input parameter @command is NVARCHAR(50) to allow Wildcard Operators ("%",
		"_", etc...) to be specified.

	[ @blk = ] ''blocking SPID''
		Is the "blocking SPID" used to filter the results. @blk is SMALLINT, with a default of
		NULL. The input parameter @blk is NVARCHAR(50) to allow Comparison Operators ("<", ">",
		etc...) to be specified. The [Blk] column substitutes "." instead of zero for display.
		However, in the @blk filter parameter, use a input a "0" to find SPIDs with no blocks.

	[ @wait = ] ''wait type and wait time (msecs)''
		Is the wait type and wait time (msecs) used to filter the results. @wait is
		NVARCHAR(45), with a default of NULL. The input parameter @wait is NVARCHAR(50) to
		allow Wildcard Operators ("%", "_", etc...) to be specified.

	[ @trans = ] ''open transactions''
		Is the number of open transactions used to filter the results. @trans is SMALLINT, with
		a default of NULL. The input parameter @trans is NVARCHAR(50) to allow Comparison
		Operators ("<", ">", etc...) to be specified. The [Trans] column substitutes "."
		instead of zero for display. However, in the @trans filter parameter, use a input a "0"
		to find	SPIDs with no transactions.

	[ @cpu = ] ''CPU time usage''
		Is the CPU time usage (msecs) a SPID has used that is used to filter the results. @cpu
		is INT, with a default of NULL. The input parameter @cpu is NVARCHAR(50) to allow
		Comparison Operators ("<", ">", etc...) to be specified.')

		PRINT ('
	[ @dsk = ] ''disk usage''
		Is the number of disk reads and writes a SPID has used that is used to filter the
		results. @dsk is INT, with a default of NULL. The input parameter @dsk is NVARCHAR(50)
		to allow Comparison Operators ("<", ">", etc...) to be specified.

	[ @last_batch = ] ''last batch date and time''
		Is the last batch time used to filter the results. @last_batch is DATETIME, with a
		default of NULL. The input parameter @last_batch is NVARCHAR(50) to allow Comparison
		Operators ("<", ">", etc...) to be specified. Do not include quotes inside the
		parameter (I.E. @last_batch = ''> ''01/01/01''''). Here is a valid example of the
		last_batch parameter (@last_batch = ''<= 01/01/01'').

	[ @o = ] ''order by clause''
		Is the order by clause used to sort the results. @o is NVARCHAR(50), with a default of
		NULL. The input parameter @o cannot exceed NVARCHAR(50). @o is used to specify an
		order by clause the same way as for a normal select statement.

Return Code Values:
	0 (success) or 1 (failure).

Result Set:
	sp_who_3 returns a result set with the following information:

	Column		Data type	Description
	----------------
	[SPID]		DECIMAL(7,2)	The process ID (SPID) and execution context ID (ECID). ECID =
					{.00, .01, ...n}, where .00 is the parent thread, and {.01,
					.02, ...n} represent any sub-threads.
	--
	[Login]		NVARCHAR(25)	The login name associated with the particular process.
	--
	[Host]		NVARCHAR(12)	The host computer name associated with the process.
	--
	[DB]		NVARCHAR(25)	The database currently in use by the process.
	--
	[Program]	NVARCHAR(25)	The name of the program connecting to the SQL Server.
	--
	[Status]	NVARCHAR(12)	The process status (I.E. "sleeping", "RUNNABLE", etc...). See
					remarks for a complete list and descriptions.
	--
	[Command]	NVARCHAR(16)	The command currently executing for the process (I.E.
					"AWAITING COMMAND", "SELECT", etc...).
	--
	[Blk]		SMALLINT	The process ID for the blocking process, if one exists.
	--
	[Wait]		NVARCHAR(45)	The current wait type (I.E. "LCK_M_S", "LCK_U", etc...)
					followed by the current wait time (msecs) in parenthesis. See
					remarks for a complete list and descriptions.
	--
	[Trans]		SMALLINT	The number of open transactions for the process.
	--
	[CPU]		INT		The cumulative CPU time (msecs) for the process.
	--
	[Dsk]		BIGINT		The cumulative number of disk reads and writes for the SPID.
	--
	[Last_Batch]	DATETIME	The last date and time the process executed a command.
	--
	[Input_Buffer]	VARCHAR(7500)	The last SQL command the process executed. This only contains
					the first 255 characters unless the SPID was actively executing
					when sp_who_3 was run. This column only exists with run modes
					of "input", "active input", and "block input".
	--
	[SP2]		SMALLINT	The process ID repeated without the ECID for easy reading.
	----------------

	The sp_who_3 results default to sorted by SPID then ECID ascending. In the case of parallel
	processing, sub-thread SPIDs are created. The main thread is indicated as SPID = x.00 where
	ECID is the two digits after the decimal. Other sub-threads have the same SPID with ECID > 00.
	The [Blk] and [Trans] columns substitute "." instead of zero for display in the result set.
	However, in the @blk and @trans filter parameters, use a input a "0" to filter results.

Remarks:
	SQL Server 2000 reserves SPID values of 1 to 50 for internal use, SPID values 51 and higher are
	for user sessions. The input buffer of SPIDs less than 51 is not available. When using run
	modes that return the input buffers, the results may take slightly longer to return.

	In SQL Server 2000, all orphaned DTC transactions are assigned the SPID value of "-2". Orphaned
	DTC transactions are distributed transactions that are not associated with any SPID. Thus, when
	an orphaned transaction is blocking another process, this orphaned distributed transaction can
	be identified by its distinctive "-2" SPID value. For more information, see "Troubleshooting MS
	DTC Transactions" in SQL Server Books Online (BOL).

	When using modes of "block" or "block input", the result set contains all processes that are
	blocked or are causing the blocking. A blocking process (which may have exclusive locks) is
	one that is holding resources other SPIDs need to continue.

	The "Status" column gives a quick look at the status of a particular SPID. Typically,
	"sleeping" means the SPID has completed execution and is waiting for the application to submit
	another batch. The following list gives brief explanations for "Status" values:

	Status Values	Description
	----------------
	BACKGROUND	The SPID is performing a background task. This indicates a system thread.
	--
	DEFWAKEUP	Indicates that a SPID is waiting on a resource that is in the process of being
			freed. The "Wait" column should indicate the resource in question.
	--
	DORMANT 	Same as "sleeping", except a "DORMANT" SPID was reset after completing an RPC
			event from remote system (possibly a linked server). This cleans up resources
			and is normal; the SPID is available to execute. The system may	be caching the
			connection. Replication SPIDs show "DORMANT" when waiting.
	--
	ROLLBACK	The SPID is currently rolling back a transaction.
	--
	RUNNABLE 	The SPID is currently executing.
	--
	sleeping	The SPID is not currently executing. This usually indicates that the SPID is
			awaiting a command from the application.
	--
	SPINLOOP	The SPID is trying to acquire a spinlock used for SMP (multi-processor)
			concurrency control. It is using memory protected against multiple access. If a
			SPINLOOP process does not give up control, then it is likely SQL Server will
			become unresponsive and it is unlikely a KILL command will work on a process in
			this state. You may need to restart the server.
	--
	UNKNOWN TOKEN 	Indicates that the SPID is currently not executing a batch.
	----------------')

		PRINT ('
	The "Wait" column describes the resource type in question that the SPID is waiting for and how
	long it has waited. The following list gives brief explanations for "Wait" values:

	Wait Values	Description
	----------------
	ASYNC_		During backup and restore threads are written in parallel. Indicates possible
	DISKPOOL_LOCK	disk bottleneck. See PhysicalDisk counters for confirmation.
	--
	ASYNC_I/O_	Waiting for asynchronous I/O requests to complete. Indicates possible disk
	COMPLETION	bottleneck, adding I/O bandwidth or balancing I/O across drives may help.
	--
	CMEMTHREAD	Waiting for thread-safe memory objects. Waiting on access to memory object.
	--
	CURSOR		Waiting for thread synchronization with asynchronous cursors.
	--
	CXPACKET	Waiting on packet synchronize up for exchange operator (parallel query).
	--
	DBTABLE		A new checkpoint request is waiting for a previous checkpoint to complete.
	--
	DTC		Waiting for Distributed Transaction Coordinator (DTC).
	--
	EC		Non-parallel synchronization between sub-thread or Execution Context.
	--
	EXCHANGE	Waiting on a parallel process to complete, shutdown, or startup.
	--
	EXECSYNC	Query memory and spooling to disk.
	--
	I/O_COMPLETION	Waiting for I/O requests to complete.
	--
	LATCH_x		Short-term light-weight synchronization objects. Latches are not held for the
			duration of a transaction. Latches are generally unrelated to I/O.
	--
	LATCH_DT	Destroy latch. See LATCH_x.
	--
	LATCH_EX	Exclusive latch. See LATCH_x.
	--
	LATCH_KP	Keep latch. See LATCH_x.
	--
	LATCH_NL	Null latch. See LATCH_x.
	--
	LATCH_SH	Shared latch. See LATCH_x.
	--
	LATCH_UP	Update latch. See LATCH_x.
	--
	LCK_M_BU	Bulk Update lock.
	--
	LCK_M_II_NL	Intent-Insert NULL (Key-Range) lock.
	--
	LCK_M_II_X	Intent-Insert Exclusive (Key-Range) lock.
	--
	LCK_M_IS	Intent-Shared lock.
	--
	LCK_M_IS_S	Intent-Shared Shared (Key-Range) lock.
	--
	LCK_M_IS_U	Intent-Shared Update (Key-Range) lock.
	--
	LCK_M_IU	Intent-Update lock.
	--
	LCK_M_IX	Intent-Exclusive lock.
	--
	LCK_M_RIn_NL	Range-Intent Null lock.
	--
	LCK_M_RIn_S	Range-Intent Shared lock.
	--
	LCK_M_RIn_U	Range-Intent Update lock.
	--
	LCK_M_RIn_X	Range-Intent Exclusive lock.
	--
	LCK_M_RS_S	Range-Shared Shared (Key-Range) lock.
	--
	LCK_M_RS_U	Range-Shared Update (Key-Range) lock.
	--
	LCK_M_RX_S	Range-Exclusive Shared (Key-Range) lock.
	--
	LCK_M_RX_U	Range-Exclusive Update (Key-Range) lock.
	--
	LCK_M_RX_X	Range-Exclusive Exclusive (Key-Range) lock.
	--
	LCK_M_S		Shared lock.
	--
	LCK_M_SCH_M	Schema Modification lock used for ALTER TABLE commands.
	--
	LCK_M_SCH_S	Schema Shared Stability lock.
	--
	LCK_M_SIU	Shared Intent to Update lock.
	--
	LCK_M_SIX	Shared Intent Exclusive lock.
	--
	LCK_M_U		Update lock used for the initial lock when doing updates.
	--
	LCK_M_UIX	Update Intent Exclusive lock.
	--
	LCK_M_X		Exclusive lock used for INSERT, UPDATE, and DELETE commands.
	--
	LOGMGR		Waiting for write requests for the transaction log to complete.
	--
	MISCELLANEOUS	Catch all wait types.
	--
	NETWORKIO	Waiting on network I/O. Waiting to read or write to a network client.
 	--
	OLEDB		Waiting on an OLE DB provider.
	--
	PAGEIOLATCH_x	Short-term synchronization objects used to synchronize access to buffer pages.
			PAGEIOLATCH_x is used for disk to memory transfers.
	--
	PAGEIOLATCH_DT	I/O page destroy latch.
	--
	PAGEIOLATCH_EX	I/O page latch exclusive. Waiting for the write of an I/O page.
	--
	PAGEIOLATCH_KP	I/O page latch keep.
	--
	PAGEIOLATCH_NL	I/O page latch null.
	--
	PAGEIOLATCH_SH	I/O page latch shared. Waiting for the read of an I/O page.
	--
	PAGEIOLATCH_UP	I/O page latch update.
	--
	PAGELATCH_x	Short-term light-weight synchronization objects. Page latching operations
			occur during row transfers to memory.
	--
	PAGELATCH_DT	Page latch destroy.
	--
	PAGELATCH_EX	Page latch exclusive.
	--
	PAGELATCH_KP	Page latch keep page.
	--
	PAGELATCH_NL	Page latch null.
	--
	PAGELATCH_SH	Page latch shared. Heavy concurrent inserts to the same index range can cause
			this type of contention. The solution in these cases is to distribute the
			inserts using a more appropriate index strategy.
	--
	PAGELATCH_UP	Page latch update. Contention for allocation of related pages. The contention
			indicates more data files are needed.
	--
	PAGESUPP	Release Spinlock in parallel query thread. Possible disk bottleneck.
	--
	PIPELINE_	Allows one user to perform multiple operations such as update index stats for
	INDEX_STAT	that user as well as other users waiting for the same operation.
	--
	PIPELINE_LOG	Allows one user to perform multiple operations such as writes to log for that
			user as well as other users waiting for the same operation.
	--
	PIPELINE_VLM	Allows one user to perform multiple operations.
	--
	PSS_CHILD	Waiting on a child thread in an asynchronous cursor operations.
	--
	RESOURCE_QUEUE	Internal use only.
 	--
	RESOURCE_	Waiting to a acquire a resource semaphore; must wait for memory grant. Used for
	SEMAPHORE	synchronization. Common for large queries such as hash joins.
	--
	SHUTDOWN	Wait for SPID to finish completion before shutdown completes.
	--
	SLEEP		Internal use only.
	--
	TEMPOBJ		Dropping a global temp object that is being used by others.
	--
	TRAN_MARK_DT	Transaction latch - destroy.
	--
	TRAN_MARK_EX	Transaction latch - exclusive.
	--
	TRAN_MARK_KP	Transaction latch - keep page.
	--
	TRAN_MARK_NL	Transaction latch - null.
	--
	TRAN_MARK_SH	Transaction latch - shared.
	--
	TRAN_MARK_UP	Transaction latch - update.
	--
	UMS_THREAD	Batch waiting for a worker thread to free up to run the batch.
	--
	WAITFOR		Wait initiated by a Transact-SQL WAITFOR statement.
	--
	WRITELOG	Waiting for write requests to the transaction log to complete.
	--
	XACTLOCKINFO	Waiting on bulk operation when releasing/escalating/transferring locks.
	--
	XCB		Acquiring access to a transaction control block (XCB). XCBs are usually private
			to a session, but can be shared between sessions when using bound sessions or
			multiple sessions in enlisting in the same DTC transaction.
	----------------')

		PRINT ('
Permissions:
	Execute permissions default to the public role. However, only members of the sysadmin or
	processadmin roles can execute "input", "active input", or "block input" run modes.

Examples:
	A. List all current processes.
		This example uses sp_who_3 without parameters to show all current processes.

		EXEC sp_who_3

		Here, all processes ordered by SPID then ECID ascending are returned.

	B. List current processes involved in blocking.
		This example uses "block" run mode to show blocked and blocking processes.

		EXEC sp_who_3
			@run_mode = ''block''

		Here, all blocked and blocking SPIDs are returned to help diagnose locking issues.

	C. List current active processes and order the results.
		This example uses "active" run mode and orders by "Login" and "SPID" descending.

		EXEC sp_who_3
			''active'',
			@o = ''2 DESC, 1 DESC''

		Here, active SPIDs sorted by Login Name and SPID descending are returned.

	D. List current processes with specific filters and order the results.
		This example uses filters on "SPID", "Program", and "Trans" while ordering by "DB".

		EXEC sp_who_3
			@spid = ''= 50'',
			@program = ''%sql%'',
			@trans = ''>= 1'',
			@o = ''DB ASC''

		Here, processes with a SPID of 50 (including all sub-thread ECIDs of SPID 50), which
		also contain "sql" anywhere in the Program Name, which have Transaction Counts greater
		than or equal to 1, and sorted by Database Name are returned.

	E. List current processes including input buffers with filters and order the results.
		This example uses "input" run mode to show process information while filtering on
		"SPID", "DB" and "Last_Batch". It also orders the results by "Status" ascending.

		EXEC sp_who_3
			@run_mode = ''input'',
			@spid = ''> 50'',
			@login = NULL,
			@host = NULL,
			@db = ''pubs'',
			@program = NULL,
			@status = NULL,
			@blk = NULL,
			@wait = NULL,
			@trans = NULL,
			@cpu = NULL,
			@dsk = NULL,
			@last_batch = ''>= 12/01/03 11:59:48'',
			@o = ''Status ASC''

		Here, the results contain processes meeting all filters ordered by the @o order by
		clause. Notice the use of comparison operators in the SPID and last_batch filters.')
	END

end_tran:
RETURN @error_code
GO

GRANT EXECUTE ON sp_who_3 TO public
GO

EXEC sp_configure 'allow updates', 0
EXEC sp_MS_upd_sysobj_category 2
RECONFIGURE WITH OVERRIDE
GO

EXEC sp_who_3 '?'
GO

-------------------------------------------------------------------------------------------------------
-- Use the following script to uninstall sp_who_3; just uncomment this section and run it to uninstall.
-------------------------------------------------------------------------------------------------------
-- USE master
-- SET QUOTED_IDENTIFIER ON
-- SET ANSI_NULLS ON
-- 
-- EXEC sp_configure 'allow updates', 1
-- EXEC sp_MS_upd_sysobj_category 1
-- RECONFIGURE WITH OVERRIDE
-- GO
-- 
-- IF OBJECT_ID(N'dbo.sp_who_3') IS NOT NULL
-- DROP PROC dbo.sp_who_3
-- GO
-- 
-- IF OBJECT_ID(N'dbo.sv_block') IS NOT NULL
-- DROP VIEW dbo.sv_block
-- GO
-- 
-- IF OBJECT_ID(N'dbo.sv_sysprocesses') IS NOT NULL
-- DROP VIEW dbo.sv_sysprocesses
-- GO
-- 
-- IF EXISTS (SELECT *
-- 		FROM dbo.sysobjects
-- 		WHERE uid = USER_ID(N'system_function_schema')
-- 			AND name = N'fn_view_input_buffer')
-- DROP FUNCTION system_function_schema.fn_view_input_buffer
-- GO
-- 
-- EXEC sp_configure 'allow updates', 0
-- EXEC sp_MS_upd_sysobj_category 2
-- RECONFIGURE WITH OVERRIDE
-- GO
-------------------------------------------------------------------------------------------------------
-- This is the end of the uninstall section of the sp_who_3 script.
-------------------------------------------------------------------------------------------------------
GO

