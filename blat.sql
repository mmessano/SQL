Declare @BLATPATH varchar(256)
Declare @BODY1 varchar(128)
Declare @BODY2 varchar(128)
Declare @RECIP varchar(64)
Declare @SUBJ varchar(64)
Declare @NOTIFYSTATE varchar(1024)
Declare @rowcount varchar(8)

select ServerName, JobName from Jobs_Report where LastRunOutcome = '0'
set @rowcount = @@rowcount
IF @@rowcount > 0
Begin

	select @BLATPATH = '\\newton\dexma\bin\thirdparty\blat.exe '
	select @BODY1 = '- -body '
	select @BODY2 = '" SQL Job(s) have failed on " + @@servername'
	select @RECIP = ' -t mmessano@primealliancesolutions.com '
	select @SUBJ = '-subject "SQL Job Failures." '
	select @NOTIFYSTATE = @BLATPATH + @BODY1 + @rowcount + @BODY2 + @@servername + @RECIP + @SUBJ
	exec master..xp_cmdshell @NOTIFYSTATE

End
