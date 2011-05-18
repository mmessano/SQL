-- remove duplicates from SQLErrorLogs table
alter table SQLErrorLogs
  add seq_num int identity
go
delete from a
--select *-- from a
from SQLErrorLogs a join
     (select ServerName
			, Date
			, spid
			, Message
			, max(seq_num) AS max_seq_num 
		from SQLErrorLogs
		group by ServerName, Date, spid, Message
		having count(*) > 1) b
      on a.ServerName = b.ServerName and
         a.Date = b.Date and
         a.spid = b.spid and
         a.Message = b.Message and
         a.seq_num < b.max_seq_num
go 
alter table SQLErrorLogs
 drop column seq_num

-----------------------------------------


MERGE statusimp.dbo.SQLErrorLogs AS T
USING QSQL610.dbamainT.dbo.SQLErrorLog AS S
ON (
	T.ServerName = S.ServerName 
	AND T.Message = S.Message 
	AND T.spid = S.spid 
	AND S.Date = T.Date 
	--AND S.LastUpdate = T.LastUpdate
	)
WHEN NOT MATCHED BY TARGET
	THEN INSERT 
	(ServerName, Date, spid, Message, LastUpdate)
	VALUES
	(S.ServerName, S.Date, S.spid, S.Message, S.LastUpdate)
-- multiple matches due to the spid column containing the word 'server'
--WHEN MATCHED
--	THEN UPDATE SET T.LastUpdate = S.LastUpdate
OUTPUT $action, inserted.*, deleted.*;

--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------

-- remove duplicates from SQLAgentErrorLogs table
alter table SQLAgentErrorLogs
  add seq_num int identity
go
delete from a
--select *-- from a
from SQLAgentErrorLogs a join
     (select ServerName, Date, ErrorLevel, Message, max(seq_num) AS max_seq_num 
     	     from SQLAgentErrorLogs
             group by ServerName, Date, ErrorLevel, Message
             having count(*) > 1) b
      on a.ServerName = b.ServerName and
         a.Date = b.Date and
         a.ErrorLevel = b.ErrorLevel and
         a.Message = b.Message and
         a.seq_num < b.max_seq_num
go 
alter table SQLAgentErrorLogs
 drop column seq_num
 
 
select * from tempdb.dbo.SQLAgentErrorLogsDestination
 
select * from Status.dbo.SQLAgentErrorLogs 

select * from dbamaint.dbo.sqlagenterrorlog


select * from ssiserrors
order by LastUpdate desc

truncate table SQLAgentErrorLogs