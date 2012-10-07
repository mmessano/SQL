/*
ServerName	DBName				ExtraIndexName
STGSQL613	CommunityFirstCUSMC	 ix_appraisal_ln_loan_id
STGSQL613	CommunityFirstCUSMC	 IX_ln_loan_id_ald_name
STGSQL613	CommunityFirstCUSMC	 ix_loan_regulatory_ln_loan_id
PSQLSMC30	FinancialPrtCUSMC	 ix_appraisal_ln_loan_id
STGSQL614	FinancialPrtCUSMC	 ix_appraisal_ln_loan_id
PSQLSMC30	FinancialPrtCUSMC	 IX_ln_loan_id_ald_name
STGSQL614	FinancialPrtCUSMC	 IX_ln_loan_id_ald_name
PSQLSMC30	FinancialPrtCUSMC	 ix_loan_regulatory_ln_loan_id
STGSQL614	FinancialPrtCUSMC	 ix_loan_regulatory_ln_loan_id
STGSQL614	NumericaSMC			 IX_ln_loan_id_ald_name
STGSQL614	NumericaSMC			 ix_loan_regulatory_ln_loan_id
QSQL610		PAQALegacySMC		 IX_InstitutionAssociation_IaInst_IaParentInst

*/

SELECT @@SERVERNAME + DB_NAME() AS Location
		, OBJECT_NAME(A.[OBJECT_ID]) AS [OBJECT NAME]
		, I.[NAME] AS [INDEX NAME]
		, A.*
		, A.LEAF_INSERT_COUNT
		, A.LEAF_UPDATE_COUNT
		, A.LEAF_DELETE_COUNT 
		, A.LEAF_GHOST_COUNT
FROM SYS.DM_DB_INDEX_OPERATIONAL_STATS (NULL,NULL,NULL,NULL ) A 
	INNER JOIN SYS.INDEXES AS I 
		ON I.[OBJECT_ID] = A.[OBJECT_ID] 
		AND I.INDEX_ID = A.INDEX_ID 
WHERE  OBJECTPROPERTY(A.[OBJECT_ID],'IsUserTable') = 1
--AND I.[NAME] = 'ix_appraisal_ln_loan_id'
AND I.[NAME] IN ('ix_appraisal_ln_loan_id'
				, 'IX_ln_loan_id_ald_name'
				, 'ix_loan_regulatory_ln_loan_id'
				, 'IX_InstitutionAssociation_IaInst_IaParentInst'
				)


SELECT DB_NAME() AS DBName
		, OBJECT_NAME(S.[OBJECT_ID]) AS [OBJECT NAME]
		, I.[NAME] AS [INDEX NAME]
		, A.LEAF_INSERT_COUNT
		, A.LEAF_UPDATE_COUNT
		, A.LEAF_DELETE_COUNT 
		, A.LEAF_GHOST_COUNT		
		, S.USER_SEEKS
		, S.USER_SCANS
		, S.USER_LOOKUPS
		, S.USER_UPDATES
FROM SYS.INDEXES AS I 
	INNER JOIN SYS.DM_DB_INDEX_USAGE_STATS AS S 
		ON I.[OBJECT_ID] = S.[OBJECT_ID] AND I.INDEX_ID = S.INDEX_ID
	INNER JOIN SYS.DM_DB_INDEX_OPERATIONAL_STATS (NULL,NULL,NULL,NULL ) A
		ON I.[OBJECT_ID] = A.[OBJECT_ID] AND I.INDEX_ID = A.INDEX_ID 
WHERE OBJECTPROPERTY(S.[OBJECT_ID],'IsUserTable') = 1
AND I.[NAME] IN ('ix_appraisal_ln_loan_id'
				, 'IX_ln_loan_id_ald_name'
				, 'ix_loan_regulatory_ln_loan_id'
				, 'IX_InstitutionAssociation_IaInst_IaParentInst'
				) 
---------------------------------------------------------------------
EXEC sp_MSforeachdb '
USE ?
IF (''?'' LIKE ''%SMC'')
BEGIN
SELECT DB_NAME() AS DBName
		, OBJECT_NAME(S.[OBJECT_ID]) AS [OBJECT NAME]
		, I.[NAME] AS [INDEX NAME]
		, A.LEAF_INSERT_COUNT
		, A.LEAF_UPDATE_COUNT
		, A.LEAF_DELETE_COUNT 
		, A.LEAF_GHOST_COUNT		
		, S.USER_SEEKS
		, S.USER_SCANS
		, S.USER_LOOKUPS
		, S.USER_UPDATES
FROM SYS.INDEXES AS I 
	INNER JOIN SYS.DM_DB_INDEX_USAGE_STATS AS S 
		ON I.[OBJECT_ID] = S.[OBJECT_ID] AND I.INDEX_ID = S.INDEX_ID
	INNER JOIN SYS.DM_DB_INDEX_OPERATIONAL_STATS (NULL,NULL,NULL,NULL ) A
		ON I.[OBJECT_ID] = A.[OBJECT_ID] AND I.INDEX_ID = A.INDEX_ID 
WHERE OBJECTPROPERTY(S.[OBJECT_ID],''IsUserTable'') = 1
AND I.[NAME] IN (''ix_appraisal_ln_loan_id''
				, ''IX_ln_loan_id_ald_name''
				, ''ix_loan_regulatory_ln_loan_id''
				, ''IX_InstitutionAssociation_IaInst_IaParentInst''
				)
END
'
---------------------------------------------------------------------
/*
Usage statistics for indexes
*/

DECLARE @IndexResults TABLE (
	[Server Name] varchar(128)
	, DBName varchar(128)
	, [OBJECT NAME] SYSNAME
	, [INDEX NAME] SYSNAME NULL
	, LEAF_INSERT_COUNT int			-- Cumulative count of leaf-level inserts.
	, LEAF_UPDATE_COUNT int			-- Cumulative count of leaf-level updates.
	, LEAF_DELETE_COUNT int			-- Cumulative count of leaf-level deletes.
	, LEAF_GHOST_COUNT int			-- Cumulative count of leaf-level rows that are marked as deleted, but not yet removed.
	, RANGE_SCAN_COUNT int			-- Cumulative count of range and table scans started on the index or heap.
	, SINGLETON_LOOKUP_COUNT int	-- Cumulative count of single row retrievals from the index or heap.
	, USER_SEEKS int				-- Number of seeks by user queries.
	, USER_SCANS int				-- Number of scans by user queries.
	, USER_LOOKUPS int				-- Number of bookmark lookups by user queries.
	, USER_UPDATES int				-- Number of updates by user queries.
	, SYSTEM_SEEKS int				-- Number of seeks by system queries.
	, SYSTEM_SCANS int				-- Number of scans by system queries.
	, SYSTEM_LOOKUPS int			-- Number of lookups by system queries.
	, SYSTEM_UPDATES int			-- Number of updates by system queries.
	, LAST_USER_SEEK DATETIME		-- Time of last user seek.
	, LAST_USER_SCAN DATETIME		-- Time of last user scan.
	, LAST_USER_LOOKUP DATETIME		-- Time of last user lookup.
	, LAST_USER_UPDATE DATETIME		-- Time of last user update.
	)

insert into @IndexResults
EXEC sp_MSforeachdb '
USE ?
IF (''?'' LIKE ''%SMC'')
BEGIN
IF (''?'' NOT IN (''master'', ''msdb'', ''dbamaint'', ''tempdb'', ''distribution'') )
BEGIN
SELECT @@SERVERNAME as [Server Name]
		, DB_NAME() AS DBName
		, OBJECT_NAME(S.[OBJECT_ID]) AS [OBJECT NAME]
		, I.[NAME] AS [INDEX NAME]
		, A.LEAF_INSERT_COUNT
		, A.LEAF_UPDATE_COUNT
		, A.LEAF_DELETE_COUNT 
		, A.LEAF_GHOST_COUNT
		, A.RANGE_SCAN_COUNT		
		, A.SINGLETON_LOOKUP_COUNT		
		, S.USER_SEEKS
		, S.USER_SCANS
		, S.USER_LOOKUPS
		, S.USER_UPDATES 
		, S.SYSTEM_SEEKS
		, S.SYSTEM_SCANS
		, S.SYSTEM_LOOKUPS
		, S.SYSTEM_UPDATES
		, S.LAST_USER_SEEK
		, S.LAST_USER_SCAN
		, S.LAST_USER_LOOKUP
		, S.LAST_USER_UPDATE
FROM SYS.INDEXES AS I 
	INNER JOIN SYS.DM_DB_INDEX_USAGE_STATS AS S 
		ON I.[OBJECT_ID] = S.[OBJECT_ID] AND I.INDEX_ID = S.INDEX_ID
	INNER JOIN SYS.DM_DB_INDEX_OPERATIONAL_STATS (NULL,NULL,NULL,NULL ) A
		ON I.[OBJECT_ID] = A.[OBJECT_ID] AND I.INDEX_ID = A.INDEX_ID 
WHERE OBJECTPROPERTY(S.[OBJECT_ID],''IsUserTable'') = 1
--AND I.[NAME] IN (''ix_appraisal_ln_loan_id''
--				, ''IX_ln_loan_id_ald_name''
--				, ''ix_loan_regulatory_ln_loan_id''
--				, ''IX_InstitutionAssociation_IaInst_IaParentInst''
--				)
END
END
'

select * from @IndexResults
---------------------------------------------------------------------
	