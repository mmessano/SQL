USE dbamaint
GO

exec dbm_permissionsall

-- dbamaint
select * from dbusers 
where lastupdate is not null  
and ServerLogin like '%** Orphaned **%'
AND DatabaseUserID NOT IN ('guest','INFORMATION_SCHEMA','sys','cdc','BUILTIN\Administrators')  
order by 1,2,3

-- Status
select * from sqldbusers 
where lastupdate is not null  
and ServerLogin like '%** Orphaned **%'
AND DatabaseUserID NOT IN ('guest','INFORMATION_SCHEMA','sys','cdc','BUILTIN\Administrators')  
order by 1,2,3