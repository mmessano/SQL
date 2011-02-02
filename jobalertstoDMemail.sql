USE dbamaint

exec dbm_JobsReport

Declare @Job varchar(128)
Declare @cmd varchar(1024)

DECLARE job_csr CURSOR FOR select distinct JobName from dbamaint.dbo.jobs_report
		order by JobName

OPEN job_csr
FETCH NEXT FROM job_csr INTO @Job

	WHILE (@@fetch_status <> -1)

	BEGIN

	print '------------------------------------'
	print '-- ' + @Job

	select @cmd =	'EXEC msdb.dbo.sp_update_job @job_name=N''' + @Job + ''', '  +
					' @notify_level_email=''2'', ' +
					--' @notify_level_eventlog=''2'', ' +
					' @notify_level_netsend=''2'', ' +
					' @notify_level_page=''2'', ' +
					' @notify_email_operator_name=N''DataManagement'''
	print @cmd
	--exec(@cmd)

	FETCH NEXT FROM job_csr INTO @Job

	END

CLOSE job_csr
DEALLOCATE job_csr