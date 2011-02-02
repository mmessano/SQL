-- Stage

USE dbamaint;
GO
dbm_CompareTables @table1 = 'statusstage.dbo.t_server', 
				  @table2 = 'xsqlutil18.status.dbo.t_server',
				  @T1ColumnList = 'server_id, server_name, environment_id, description, active'

USE StatusStage;
GO


BEGIN TRAN;
SET IDENTITY_INSERT StatusStage.dbo.t_server ON
GO

MERGE StatusStage.dbo.t_server AS T  -- target
USING statusprod.status.dbo.t_server AS S  -- source
ON (t.server_id = s.server_id)
WHEN NOT MATCHED BY TARGET
	THEN INSERT (server_id, server_name, environment_id, description, active, LastUpdate) VALUES
				(s.server_id, s.server_name, s.environment_id, s.description, s.active, s.LastUpdate)
WHEN MATCHED
	THEN UPDATE SET T.server_name = S.server_name,
					T.environment_id = S.environment_id,
					T.description = S.description,
					T.active = S.active,
					T.LastUpdate = S.LastUpdate
WHEN NOT MATCHED BY SOURCE
	THEN DELETE
OUTPUT $action, inserted.*, deleted.*;
--ROLLBACK TRAN;
COMMIT TRAN;
GO

---------------------------------------------------------------------------------
-- IMP

USE dbamaint;
GO
dbm_CompareTables @table1 = 'statusimp.dbo.t_server', 
				  @table2 = 'xsqlutil18.status.dbo.t_server',
				  @T1ColumnList = 'server_id, server_name, environment_id, description, active'

select * from xsqlutil18.status.dbo.t_server

USE StatusIMP;
GO


BEGIN TRAN;
SET IDENTITY_INSERT StatusImp.dbo.t_server ON
GO

MERGE StatusImp.dbo.t_server AS T  -- target
USING statusprod.status.dbo.t_server AS S  -- source
ON (t.server_id = s.server_id)
WHEN NOT MATCHED BY TARGET
	THEN INSERT (server_id, server_name, environment_id, description, active, LastUpdate) VALUES
				(s.server_id, s.server_name, s.environment_id, s.description, s.active, s.LastUpdate)
WHEN MATCHED
	THEN UPDATE SET T.server_name = S.server_name,
					T.environment_id = S.environment_id,
					T.description = S.description,
					T.active = S.active,
					T.LastUpdate = S.LastUpdate
WHEN NOT MATCHED BY SOURCE
	THEN DELETE
OUTPUT $action, inserted.*, deleted.*;
--ROLLBACK TRAN;
COMMIT TRAN;
GO

SET IDENTITY_INSERT StatusImp.dbo.t_server OFF
GO
					