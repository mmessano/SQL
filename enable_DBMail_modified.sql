USE MASTER
GO
----------------------------------------------------------------------
DECLARE @SMTPServer		VARCHAR(100)
DECLARE @TestEmail		VARCHAR(100)
DECLARE @ReplyToEmail	VARCHAR(100)
DECLARE @AccountName	VARCHAR(100)
DECLARE @ProfileName	VARCHAR(100)
DECLARE @CommitChanges	CHAR(1)
DECLARE @SendTestEmail	CHAR(1)
DECLARE @Debug			CHAR(1)
----------------------------------------------------------------------
--					PLEASE FILL OUT THIS
----------------------------------------------------------------------
SET @SMTPServer			= 'outbound.smtp.dexma.com'
SET @TestEmail			= 'DataManagement@mortgagecadence.com'
SET @ReplyToEmail		= 'DataManagement@mortgagecadence.com'
SET @AccountName		= 'DataManagement'
SET @ProfileName		= 'DataManagement Mail Notification'
----------------------------------------------------------------------
SET @CommitChanges		= 'Y'
SET @SendTestEmail		= 'Y'
SET @Debug				= 'Y'
----------------------------------------------------------------------
--					Setting Up Database Mail
----------------------------------------------------------------------
DECLARE @Domain				VARCHAR(100)
DECLARE @Hostname			VARCHAR(100)
DECLARE @IPAddress			VARCHAR(24)
DECLARE @EmailAddress		VARCHAR(100)
DECLARE @DisplayName		VARCHAR(100)
DECLARE @AccountDescription VARCHAR(100)
DECLARE @ProfileDescription VARCHAR(100)
DECLARE @TestMsgSubject		VARCHAR(100)
DECLARE @TestMsgBody		VARCHAR(256)
----------------------------------------------------------------------
-- retrieve the domain, hostname and the IP address of the SQL connection
EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE', 'SYSTEM\CurrentControlSet\services\Tcpip\Parameters', N'Domain',@Domain OUTPUT
EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE', 'SYSTEM\CurrentControlSet\services\Tcpip\Parameters', N'Hostname',@Hostname OUTPUT

SELECT @IPAddress = ( SELECT ISNULL(dec.local_net_address,'Egads! Not an IPAddress!')
						FROM sys.dm_exec_connections AS dec 
						WHERE dec.session_id = @@SPID )

SELECT @Domain = LOWER(@Domain)
SELECT @Hostname = LOWER(@Hostname)

-- construct the email address from the reported @@SERVERNAME to preserve the instance
-- '\' isn't valid as part of an email address, replace it
-- the display name equals the From field in email clients
SET @EmailAddress = LOWER(REPLACE(@@SERVERNAME, '\', '_')) + '@' + @Domain
--SET @DisplayName = LOWER(@@SERVERNAME) + '.' + @Domain
SET @DisplayName = @Hostname + '.' + @Domain
SET @AccountDescription = @AccountName + ' email account for ' + @DisplayName + '.'
SET @ProfileDescription = @ProfileName + ' email profile for ' + @DisplayName + '.'

-- construct the email subject and body
SET @TestMsgSubject = 'DBMail Test From - ' + @DisplayName
SET @TestMsgBody = 'Test from ' + @DisplayName + CHAR(10) + CHAR(10)
SET @TestMsgBody = @TestMsgBody + 'My @Hostname is: ' + CHAR(9)  + @HostName + CHAR(10)
SET @TestMsgBody = @TestMsgBody + 'My FQDN is: ' + CHAR(9)  + CHAR(9) + @HostName + '.' + @Domain + CHAR(10)
SET @TestMsgBody = @TestMsgBody + 'My IPAddress is: ' + CHAR(9) + @IPAddress + CHAR(10)
SET @TestMsgBody = @TestMsgBody + 'My @@SERVERNAME is: ' + CHAR(9) + @@SERVERNAME + CHAR(10)

----------------------------------------------------------------------
--					Begin main loop
----------------------------------------------------------------------
IF ( @CommitChanges = 'Y' )
BEGIN
	EXEC sp_configure 'show advanced options', 1;
	EXEC sp_configure 'Database Mail XPs', 1;
	EXEC sp_configure 'Agent XPs',1;
	RECONFIGURE WITH OVERRIDE
	
	IF EXISTS(SELECT * from msdb.dbo.sysmail_account where name = @AccountName)
	BEGIN
		PRINT 'The ''' + @AccountName + ''' account is already configured, updating values.'
		exec msdb.dbo.sysmail_update_account_sp
				@Account_name		= @AccountName
				, @description		= @AccountDescription
				, @email_address	= @EmailAddress
				, @replyto_address	= @ReplyToEmail
				, @display_name		= @DisplayName
				, @mailserver_name	= @SMTPServer
				
		 -- there can be no profile without an account, assume one exists but check first
		 IF EXISTS(SELECT * from msdb.dbo.sysmail_profile where name = @ProfileName)
		 BEGIN
			 PRINT 'The ''' + @ProfileName + ''' profile is already configured, updating values.'
			 exec msdb.dbo.sysmail_update_profile_sp
					@profile_name	= @ProfileName
					, @description	= @ProfileDescription
		END
		ELSE
		BEGIN
			--Create global mail profile.
			PRINT 'Creating ''' + @ProfileName + ''' profile for sending email.'
			exec msdb.dbo.sysmail_add_profile_sp
					@profile_name		= @ProfileName
					, @description		= @ProfileDescription

			--Add the account to the profile.
			exec msdb.dbo.sysmail_add_profileaccount_sp
					@profile_name		= @ProfileName
					, @Account_name		= @AccountName
					, @sequence_number	= 1

			--grant access to the profile to all users in the msdb database
			use msdb
			exec msdb.dbo.sysmail_add_principalprofile_sp
					 @profile_name		= @ProfileName
					, @principal_name	= 'public'
					, @is_default		= 1
		END
	END
	ELSE
	BEGIN
		--Create database mail account.
		PRINT 'Creating ''' + @AccountName + ''' account for sending email.'
		exec msdb.dbo.sysmail_add_account_sp
				@Account_name		= @AccountName
				, @description		= @AccountDescription
				, @email_address	= @EmailAddress
				, @replyto_address	= @ReplyToEmail
				, @display_name		= @DisplayName
				, @mailserver_name	= @SMTPServer

		--Create global mail profile.
		PRINT 'Creating ''' + @ProfileName + ''' profile for sending email.'
		exec msdb.dbo.sysmail_add_profile_sp
				@profile_name		= @ProfileName
				, @description		= @ProfileDescription

		--Add the account to the profile.
		exec msdb.dbo.sysmail_add_profileaccount_sp
				@profile_name		= @ProfileName
				, @Account_name		= @AccountName
				, @sequence_number	= 1

		--grant access to the profile to all users in the msdb database
		use msdb
		exec msdb.dbo.sysmail_add_principalprofile_sp
				 @profile_name		= @ProfileName
				, @principal_name	= 'public'
				, @is_default		= 1
	END
	----------------------------------------------------------------------
	--					Set Up SQL Agent Mail
	----------------------------------------------------------------------
	PRINT '##################################################################'
	PRINT 'Enabling SQL Agent notification - THIS REQUIRES RESTART SQL AGENT'
	PRINT '##################################################################'
	-- Enabling SQL Agent notification
	USE [msdb]
	EXEC msdb.dbo.sp_set_sqlagent_properties @alert_replace_runtime_tokens=1
	EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1
	EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'UseDatabaseMail', N'REG_DWORD', 1
	EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'DatabaseMailProfile', N'REG_SZ', N'SQLMail Profile'
	/*
	-- Sample output

	Configuration option 'show advanced options' changed from 0 to 1. Run the RECONFIGURE statement to install.
	Configuration option 'Database Mail XPs' changed from 0 to 1. Run the RECONFIGURE statement to install.
	Configuration option 'Agent XPs' changed from 1 to 1. Run the RECONFIGURE statement to install.
	Mail queued.
	##################################################################
	Enabling SQL Agent notification - THIS REQUIRES RESTART SQL AGENT
	##################################################################

	(0 row(s) affected)

	(0 row(s) affected)

	*/
END

IF ( @Debug = 'Y' ) 
BEGIN
	--PRINT CHAR(10)
	--PRINT 'No changes made to DBMail.'
	--PRINT 'Current variables printed below.' + CHAR(10)

	--PRINT 'SMTPServer: ' + CHAR(9) + CHAR(9) + CHAR(9) + @SMTPServer
	--PRINT 'AdminEmail: ' + CHAR(9) + CHAR(9) + CHAR(9) + @TestEmail
	--PRINT 'ReplyToEmail: ' + CHAR(9) + CHAR(9) + CHAR(9) + @ReplyToEmail
	--PRINT 'AccountName: ' + CHAR(9) + CHAR(9) + CHAR(9) + @AccountName
	--PRINT 'ProfileName: ' + CHAR(9) + CHAR(9) + CHAR(9) + @ProfileName
	--PRINT 'Domain: ' + CHAR(9) + CHAR(9) + CHAR(9) + CHAR(9) + @Domain
	--PRINT 'Hostname: ' + CHAR(9) + CHAR(9) + CHAR(9) + CHAR(9) + @Hostname
	--PRINT 'ServerName: ' + CHAR(9) + CHAR(9) + CHAR(9) + @ServerName
	--PRINT 'EmailAddress: ' + CHAR(9) + CHAR(9) + CHAR(9) + @EmailAddress
	--PRINT 'DisplayName: ' + CHAR(9) + CHAR(9) + CHAR(9) + @DisplayName
	--PRINT 'AccountDescription: ' + CHAR(9) + @AccountDescription
	--PRINT 'ProfileDescription: ' + CHAR(9) + @ProfileDescription
	--PRINT 'TestMsgSubject: ' + CHAR(9) + CHAR(9) + @TestMsgSubject
	--PRINT 'TestMsgBody: ' + CHAR(10) + '"'+ @TestMsgBody + '"'
	--PRINT CHAR(10)
	
	SELECT @AccountName AS 'AccountName'
			, @AccountDescription AS 'AccountDescription'
			, @EmailAddress AS 'EmailAddress'
			, @DisplayName AS 'DisplayName'
			, @ReplyToEmail AS 'ReplyToEmail'
			, @IPAddress AS 'IPAddress'
			, @SMTPServer AS 'SMTPServer'
			, @Hostname AS 'Hostname'
			, @Domain AS 'Domain' 
	EXEC msdb.dbo.sysmail_help_account_sp
	
	SELECT @ProfileName AS 'ProfileName'
			, @ProfileDescription AS 'ProfileDescription'
	EXEC msdb.dbo.sysmail_help_profile_sp
	
	SELECT @TestEmail AS 'TestEmail'
			, @TestMsgSubject AS 'TestMsgSubject' 
			, @TestMsgBody AS 'TestMsgBody'
END

-- send a test message.
if (@SendTestEmail = 'Y')
BEGIN
	PRINT CHAR(10) + 'Sending test email.'
	exec msdb..sp_send_dbmail
		@profile_name	= @ProfileName
		, @recipients	= @TestEmail
		, @subject		= @TestMsgSubject
		, @body			= @TestMsgBody
END


