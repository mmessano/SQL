declare @publisher sysname, 
	@publisher_db sysname, 
	@publication sysname, 
	@publication_type int, 
	@article sysname, 
	@subscriber sysname, 
	@subscriber_db sysname, 
	@alert_id int
	
declare hc cursor local for 
	select publisher, publisher_db, publication, publication_type, article, subscriber, 
	subscriber_db, alert_id from 
	msdb..sysreplicationalerts where 
	--alert_error_code = 20574 and status = 0
	alert_error_code = 14150 and status = 0
	--alert_error_code = 20575 and status = 0
for read only

open hc

fetch hc into  @publisher, @publisher_db, @publication, @publication_type, @article, @subscriber, @subscriber_db, @alert_id
while (@@fetch_status <> -1)

begin
/* Do custom work  */
print @publisher 
print @publisher_db 
print @publication 
print @publication_type 
print @article 
print @subscriber 
print @subscriber_db 
print @alert_id
/* Update status to 1, which means the alert has been serviced. This prevents subsequent runs of this job from doing this again */
update msdb..sysreplicationalerts set status = 1 where alert_id = @alert_id
 fetch hc into  @publisher, @publisher_db, @publication, @publication_type, @article, @subscriber, @subscriber_db, @alert_id
end
close hc
deallocate hc