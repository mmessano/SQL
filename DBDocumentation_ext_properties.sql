--Once again, the code is easily extended (based on the snippets already given in this series of articles plus your own additions)
--should you wish to add further objects from amongst those which can be documented.
-----------------------------------------------------------------------
-- User-defined variables
-- Set these to 1 or 0 to indicate whether you wish to output the elements
-----------------------------------------------------------------------
DECLARE @OutputTables BIT 
DECLARE @OutputViews BIT 
DECLARE @OutputProcedures BIT 
DECLARE @OutputFunctions BIT 
DECLARE @OutputTableColumns BIT 
DECLARE @OutputViewColumns BIT
DECLARE @OutputIndexes BIT 
DECLARE @OutputConstraints BIT 
SET @OutputTables = 1
SET @OutputViews = 1
SET @OutputProcedures = 1
SET @OutputFunctions = 1
SET @OutputTableColumns = 1
SET @OutputViewColumns = 1
SET @OutputIndexes = 1
SET @OutputConstraints = 1
-----------------------------------------------------------------------
-- Process variables
-----------------------------------------------------------------------
DECLARE @ObjectType NVARCHAR(50) = ''
DECLARE @SecondaryObjectType NVARCHAR(50) = ''
-----------------------------------------------------------------------
-- Create the temporary table to hold the scripts and metadata
-----------------------------------------------------------------------
IF OBJECT_ID('tempdb..#ModifyCreate') IS NOT NULL
	DROP TABLE tempdb..#ModifyCreate;
CREATE TABLE #ModifyCreate (
	PrimaryObjectType VARCHAR(25)
	, SecondaryObjectType VARCHAR(25)
	, SchemaName NVARCHAR(128)
	, PrimaryObjectName NVARCHAR(128)
	, SecondaryObjectName NVARCHAR(128)
	, Classification NVARCHAR(128)
	, DescriptionText NVARCHAR(1700)
	, SQLText NVARCHAR(2500)
)
-----------------------------------------------------------------------
-- Output scripts for Table objects
-----------------------------------------------------------------------
IF @OutputTables = 1
BEGIN
	SET @ObjectType = 'Table'
	INSERT INTO #ModifyCreate
	SELECT 
		@ObjectType AS PrimaryObjectType
		,CAST(NULL AS VARCHAR(25)) AS SecondaryObjectType
		,SCH.name AS SchemaName
		,CAST(TBL.name AS NVARCHAR(128)) AS PrimaryObjectName
		,CAST(NULL AS VARCHAR(25)) AS SecondaryObjectName
		,EX.DescriptionType AS Classification
		,CAST(EX.DescriptionDefinition AS NVARCHAR(128)) AS DescriptionText
		,CASE
			WHEN EX.DescriptionType IS NULL THEN 'sp_addextendedproperty @level0type = N''Schema'', @level0name = [' + SCH.name + '], @level1type = ''' + @ObjectType + ''', @level1name = [' + TBL.name + '], @name = N'''', @value = '''';'
			ELSE 'sp_updateextendedproperty @level0type = N''Schema'', @level0name = [' + SCH.name + '], @level1type = ''' + @ObjectType + ''', @level1name = [' + TBL.name + '], @name = N''' + EX.DescriptionType + ''', @value = ''' + CAST(EX.DescriptionDefinition AS NVARCHAR(1700)) + ''';'
			END AS SQLText
	FROM sys.tables TBL
		INNER JOIN sys.schemas SCH
		ON TBL.schema_id = SCH.schema_id 
		LEFT OUTER JOIN
		(
	SELECT DISTINCT 
		SEP.name AS DescriptionType
		,SEP.value AS DescriptionDefinition
		,SEP.major_id
	FROM sys.extended_properties SEP
	WHERE SEP.class = 1 
		AND SEP.minor_id = 0
		AND (SEP.value <> '1' AND SEP.value <> 1)
		) EX
	ON TBL.object_id = EX.major_id
END -- Tables
-----------------------------------------------------------------------
-- Output scripts for View objects
-----------------------------------------------------------------------
IF @OutputViews = 1
BEGIN
	SET @ObjectType = 'View'
	INSERT INTO #ModifyCreate
	SELECT 
		@ObjectType AS PrimaryObjectType
		,CAST(NULL AS VARCHAR(25)) AS SecondaryObjectType
		,SCH.name AS SchemaName
		,CAST(VIW.name AS NVARCHAR(128)) AS PrimaryObjectName
		,CAST(NULL AS VARCHAR(25)) AS SecondaryObjectName
		,EX.DescriptionType AS Classification
		,CAST(EX.DescriptionDefinition AS NVARCHAR(128)) AS DescriptionText
		,CASE
			WHEN EX.DescriptionType IS NULL THEN 'sp_addextendedproperty @level0type = N''Schema'', @level0name = [' + SCH.name + '], @level1type = ''' + @ObjectType + ''', @level1name = [' + VIW.name + '], @name = N'''', @value = '''';'
		ELSE 'sp_updateextendedproperty @level0type = N''Schema'', @level0name = [' + SCH.name + '], @level1type = ''' + @ObjectType + ''', @level1name = [' + VIW.name + '], @name = N''' + EX.DescriptionType + ''', @value = ''' + CAST(EX.DescriptionDefinition AS NVARCHAR(1700)) + ''';'
		END AS SQLText
	FROM sys.views VIW
		INNER JOIN sys.schemas SCH
		ON VIW.schema_id = SCH.schema_id 
		LEFT OUTER JOIN
		(
		SELECT DISTINCT 
		SEP.name AS DescriptionType
		,SEP.value AS DescriptionDefinition
		,SEP.major_id
	FROM sys.extended_properties SEP
	WHERE SEP.class = 1 
		AND SEP.minor_id = 0
		AND (SEP.value <> '1' AND SEP.value <> 1)
		) EX
	ON VIW.object_id = EX.major_id
END -- Views
-----------------------------------------------------------------------
-- Output scripts for Stored procedure objects
-----------------------------------------------------------------------
IF @OutputProcedures = 1
BEGIN
SET @ObjectType = 'Procedure'
INSERT INTO #ModifyCreate
SELECT 
@ObjectType AS PrimaryObjectType
,CAST(NULL AS VARCHAR(25)) AS SecondaryObjectType
,SCH.name AS SchemaName
,CAST(PRC.name AS NVARCHAR(128)) AS PrimaryObjectName
,CAST(NULL AS VARCHAR(25)) AS SecondaryObjectName
,EX.DescriptionType AS Classification
,CAST(EX.DescriptionDefinition AS NVARCHAR(128)) AS DescriptionText
,CASE
WHEN EX.DescriptionType IS NULL THEN 'sp_addextendedproperty @level0type = N''Schema'', @level0name = [' + SCH.name + '], @level1type = ''' + @ObjectType + ''', @level1name = [' + PRC.name + '], @name = N'''', @value = '''';'
ELSE 'sp_updateextendedproperty @level0type = N''Schema'', @level0name = [' + SCH.name + '], @level1type = ''' + @ObjectType + ''', @level1name = [' + PRC.name + '], @name = N''' + EX.DescriptionType + ''', @value = ''' + CAST(EX.DescriptionDefinition AS NVARCHAR(1700)) + ''';'
END AS SQLText
FROM sys.procedures PRC
 INNER JOIN sys.schemas SCH
 ON PRC.schema_id = SCH.schema_id 
 LEFT OUTER JOIN
 (
 SELECT DISTINCT 
 SEP.name AS DescriptionType
 ,SEP.value AS DescriptionDefinition
 ,SEP.major_id
 FROM sys.extended_properties SEP
 WHERE SEP.class = 1 
 AND SEP.minor_id = 0
 AND (SEP.value <> '1' AND SEP.value <> 1)
 ) EX
 ON PRC.object_id = EX.major_id
END -- Procedures
-----------------------------------------------------------------------
-- Output scripts for Function objects
-----------------------------------------------------------------------
IF @OutputFunctions = 1
BEGIN
SET @ObjectType = 'Function'
INSERT INTO #ModifyCreate
SELECT 
@ObjectType AS PrimaryObjectType
,CAST(NULL AS VARCHAR(25)) AS SecondaryObjectType
,SCH.name AS SchemaName
,CAST(OBJ.name AS NVARCHAR(128)) AS PrimaryObjectName
,CAST(NULL AS VARCHAR(25)) AS SecondaryObjectName
,EX.DescriptionType AS Classification
,CAST(EX.DescriptionDefinition AS NVARCHAR(128)) AS DescriptionText
,CASE
WHEN EX.DescriptionType IS NULL THEN 'sp_addextendedproperty @level0type = N''Schema'', @level0name = [' + SCH.name + '], @level1type = ''' + @ObjectType + ''', @level1name = [' + OBJ.name + '], @name = N'''', @value = '''';'
ELSE 'sp_updateextendedproperty @level0type = N''Schema'', @level0name = [' + SCH.name + '], @level1type = ''' + @ObjectType + ''', @level1name = [' + OBJ.name + '], @name = N''' + EX.DescriptionType + ''', @value = ''' + CAST(EX.DescriptionDefinition AS NVARCHAR(1700)) + ''';'
END AS SQLText
FROM sys.objects OBJ
 INNER JOIN sys.schemas SCH
 ON OBJ.schema_id = SCH.schema_id 
 LEFT OUTER JOIN
 (
 SELECT DISTINCT 
 SEP.name AS DescriptionType
 ,SEP.value AS DescriptionDefinition
 ,SEP.major_id
 FROM sys.extended_properties SEP
 WHERE SEP.class = 1 
 AND SEP.minor_id = 0
 AND (SEP.value <> '1' AND SEP.value <> 1)
 ) EX
 ON OBJ.object_id = EX.major_id

WHERE OBJ.type_desc = 'SQL_SCALAR_FUNCTION'
END -- Functions
-----------------------------------------------------------------------
-- Output scripts for Table Column objects
-----------------------------------------------------------------------
IF @OutputTableColumns = 1
BEGIN
SET @ObjectType = 'Table'
SET @SecondaryObjectType = 'Column'
INSERT INTO #ModifyCreate
SELECT 
@ObjectType AS PrimaryObjectType
,@SecondaryObjectType AS SecondaryObjectType
,SCH.name AS SchemaName
,CAST(TBL.name AS NVARCHAR(128)) AS PrimaryObjectName
,CAST(COL.name AS NVARCHAR(128)) AS SecondaryObjectName
,EX.DescriptionType AS Classification
,CAST(EX.DescriptionDefinition AS NVARCHAR(128)) AS DescriptionText
,CASE
WHEN EX.DescriptionType IS NULL THEN 'sp_addextendedproperty @level0type = N''Schema'', @level0name = [' + SCH.name + '], @level1type = ''' + @ObjectType + ''', @level1name = [' + TBL.name + '], @level2type = N''' + ISNULL(@SecondaryObjectType,'') + ''', @level2name = [' + ISNULL(COL.name,'') + '], @name = N'''', @value = '''';'
ELSE 'sp_updateextendedproperty @level0type = N''Schema'', @level0name = [' + SCH.name + '], @level1type = ''' + @ObjectType + ''', @level1name = [' + TBL.name + '], @level2type = N''' + ISNULL(@SecondaryObjectType,'') + ''', @level2name = [' + ISNULL(COL.name,'') + '], @name = N''' + EX.DescriptionType + ''', @value = ''' + CAST(EX.DescriptionDefinition AS NVARCHAR(1700)) + ''';'
END AS SQLText
FROM sys.tables TBL
 INNER JOIN sys.schemas SCH
 ON TBL.schema_id = SCH.schema_id 
 INNER JOIN sys.columns COL
 ON COL.object_id = TBL.object_id
 LEFT OUTER JOIN
 (
 SELECT DISTINCT 
 SEP.name AS DescriptionType
 ,SEP.value AS DescriptionDefinition
 ,SEP.major_id
 ,SEP.minor_id 
 FROM sys.extended_properties SEP
 WHERE SEP.class = 1 
 ) EX
 ON TBL.object_id = EX.major_id
 AND COL.column_id = EX.minor_id
END -- Table Columns
-----------------------------------------------------------------------
-- Output scripts for View Column objects
-----------------------------------------------------------------------
IF @OutputViewColumns = 1
BEGIN
SET @ObjectType = 'View'
SET @SecondaryObjectType = 'Column'
INSERT INTO #ModifyCreate
SELECT 
@ObjectType AS PrimaryObjectType
,@SecondaryObjectType AS SecondaryObjectType
,SCH.name AS SchemaName
,CAST(VIW.name AS NVARCHAR(128)) AS PrimaryObjectName
,CAST(COL.name AS NVARCHAR(128)) AS SecondaryObjectName
,EX.DescriptionType AS Classification
,CAST(EX.DescriptionDefinition AS NVARCHAR(128)) AS DescriptionText
,CASE
WHEN EX.DescriptionType IS NULL THEN 'sp_addextendedproperty @level0type = N''Schema'', @level0name = [' + SCH.name + '], @level1type = ''' + @ObjectType + ''', @level1name = [' + VIW.name + '], @level2type = N''' + ISNULL(@SecondaryObjectType,'') + ''', @level2name = [' + ISNULL(COL.name,'') + '], @name = N'''', @value = '''';'
ELSE 'sp_updateextendedproperty @level0type = N''Schema'', @level0name = [' + SCH.name + '], @level1type = ''' + @ObjectType + ''', @level1name = [' + VIW.name + '], @level2type = N''' + ISNULL(@SecondaryObjectType,'') + ''', @level2name = [' + ISNULL(COL.name,'') + '], @name = N''' + EX.DescriptionType + ''', @value = ''' + CAST(EX.DescriptionDefinition AS NVARCHAR(1700)) + ''';'
END AS SQLText
FROM sys.views VIW
 INNER JOIN sys.schemas SCH
 ON VIW.schema_id = SCH.schema_id 
 INNER JOIN sys.columns COL
 ON COL.object_id = VIW.object_id
 LEFT OUTER JOIN
 (
 SELECT DISTINCT 
 SEP.name AS DescriptionType
 ,SEP.value AS DescriptionDefinition
 ,SEP.major_id
 ,SEP.minor_id 
 FROM sys.extended_properties SEP
 WHERE SEP.class = 1 
 ) EX
 ON VIW.object_id = EX.major_id
 AND COL.column_id = EX.minor_id
END -- View Columns
-----------------------------------------------------------------------
-- Output scripts for Indexes
-----------------------------------------------------------------------
IF @OutputIndexes = 1
BEGIN
SET @SecondaryObjectType = 'Index'
INSERT INTO #ModifyCreate
SELECT 
CASE
WHEN OBJ.type_desc = N'USER_TABLE' THEN 'Table'
WHEN OBJ.type_desc = N'VIEW' THEN 'View'
END AS PrimaryObjectType
,@SecondaryObjectType AS SecondaryObjectType
,SCH.name AS SchemaName
,CAST(OBJ.name AS NVARCHAR(128)) AS PrimaryObjectName
,CAST(SIX.name AS NVARCHAR(128)) AS SecondaryObjectName
,EX.DescriptionType AS Classification
,CAST(EX.DescriptionDefinition AS NVARCHAR(128)) AS DescriptionText
,CASE
WHEN EX.DescriptionType IS NULL THEN 'sp_addextendedproperty @level0type = N''Schema'', @level0name = [' + SCH.name + '], @level1type = ''' + CASE WHEN OBJ.type_desc = N'USER_TABLE' THEN 'Table' WHEN OBJ.type_desc = N'VIEW' THEN 'View' END + ''', @level1name = [' + OBJ.name + '], @level2type = N''' + ISNULL(@SecondaryObjectType,'') + ''', @level2name = [' + ISNULL(SIX.name,'') + '], @name = N'''', @value = '''';'
ELSE 'sp_updateextendedproperty @level0type = N''Schema'', @level0name = [' + SCH.name + '], @level1type = ''' + CASE WHEN OBJ.type_desc = N'USER_TABLE' THEN 'Table' WHEN OBJ.type_desc = N'VIEW' THEN 'View' END + ''', @level1name = [' + OBJ.name + '], @level2type = N''' + ISNULL(@SecondaryObjectType,'') + ''', @level2name = [' + ISNULL(SIX.name,'') + '], @name = N''' + EX.DescriptionType + ''', @value = ''' + CAST(EX.DescriptionDefinition AS NVARCHAR(1700)) + ''';'
END AS SQLText
FROM sys.objects OBJ
 INNER JOIN sys.schemas SCH
 ON OBJ.schema_id = SCH.schema_id 
 INNER JOIN sys.indexes SIX
 ON OBJ.object_id = SIX.object_id 
 LEFT OUTER JOIN
 (
 SELECT DISTINCT 
 SEP.name AS DescriptionType
 ,SEP.value AS DescriptionDefinition
 ,SEP.major_id
 ,SEP.minor_id
 FROM sys.extended_properties SEP
 WHERE SEP.class_desc = N'INDEX'
 ) EX
 ON OBJ.object_id = EX.major_id
 AND SIX.index_id = EX.minor_id
WHERE OBJ.type_desc IN ('USER_TABLE','VIEW')
 AND SIX.is_primary_key = 0
 AND SIX.is_unique = 0
 AND SIX.is_unique_constraint = 0
 AND SIX.name IS NOT NULL
END -- Indexes
-----------------------------------------------------------------------
-- Output scripts for Constraints
-----------------------------------------------------------------------
IF @OutputConstraints = 1
BEGIN
SET @ObjectType = 'Table'
SET @SecondaryObjectType = 'Constraint'
INSERT INTO #ModifyCreate
SELECT 
CASE
WHEN OBJ.type_desc = N'USER_TABLE' THEN 'Table'
WHEN OBJ.type_desc = N'VIEW' THEN 'View'
END AS PrimaryObjectType
,@SecondaryObjectType AS SecondaryObjectType
,SCH.name AS SchemaName
,CAST(OBJ.name AS NVARCHAR(128)) AS PrimaryObjectName
,CAST(SIX.name AS NVARCHAR(128)) AS SecondaryObjectName
,EX.DescriptionType AS Classification
,CAST(EX.DescriptionDefinition AS NVARCHAR(128)) AS DescriptionText
,CASE
WHEN EX.DescriptionType IS NULL THEN 'sp_addextendedproperty @level0type = N''Schema'', @level0name = [' + SCH.name + '], @level1type = ''' + @ObjectType + ''', @level1name = [' + OBJ.name + '], @level2type = N''' + ISNULL(@SecondaryObjectType,'') + ''', @level2name = [' + ISNULL(SIX.name,'') + '], @name = N'''', @value = '''';'
ELSE 'sp_updateextendedproperty @level0type = N''Schema'', @level0name = [' + SCH.name + '], @level1type = ''' + @ObjectType + ''', @level1name = [' + OBJ.name + '], @level2type = N''' + ISNULL(@SecondaryObjectType,'') + ''', @level2name = [' + ISNULL(SIX.name,'') + '], @name = N''' + EX.DescriptionType + ''', @value = ''' + CAST(EX.DescriptionDefinition AS NVARCHAR(1700)) + ''';'
END AS SQLText
FROM sys.objects OBJ
 INNER JOIN sys.schemas SCH
 ON OBJ.schema_id = SCH.schema_id 
 INNER JOIN sys.indexes SIX
 ON OBJ.object_id = SIX.object_id 
 LEFT OUTER JOIN
 (
 SELECT DISTINCT 
 SEP.name AS DescriptionType
 ,SEP.value AS DescriptionDefinition
 ,SEP.major_id
 ,SEP.minor_id
 FROM sys.extended_properties SEP
 WHERE SEP.class_desc = N'INDEX'
 ) EX
 ON OBJ.object_id = EX.major_id
 AND SIX.index_id = EX.minor_id
WHERE OBJ.type_desc = 'USER_TABLE'
 AND (SIX.is_primary_key = 1 OR SIX.is_unique = 1 OR SIX.is_unique_constraint = 1)
END -- Constraints
-----------------------------------------------------------------------
-- Output scripts
-----------------------------------------------------------------------
SELECT * FROM #ModifyCreate
-----------------------------------------------------------------------