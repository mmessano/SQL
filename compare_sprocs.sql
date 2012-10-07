DECLARE @Sourcespname NVARCHAR(4000) 
DECLARE @Destspname NVARCHAR(4000)
DECLARE @Sourcespdefinition NVARCHAR(4000) 
DECLARE @Destspdefinition NVARCHAR(4000)
DECLARE @SourcehashedVal VARBINARY(4000) 
DECLARE @DestHashedVal VARBINARY(4000)
-----------------------------------------------------------------------------------
SET @Sourcespname = 'dbm_PermissionsAll'
SET @Destspname = 'sp_permissions_all'
-----------------------------------------------------------------------------------
SET @Sourcespdefinition = (SELECT OBJECT_DEFINITION (OBJECT_ID(@Sourcespname )))     
SET @SourceHashedVal = (SELECT HashBytes('SHA1', @Sourcespdefinition))
-----------------------------------------------------------------------------------
SET @Destspdefinition = (SELECT OBJECT_DEFINITION (OBJECT_ID(@Destspname )))     
SET @DestHashedVal = (SELECT HashBytes('SHA1', @Destspdefinition)) 
-----------------------------------------------------------------------------------
--select @SourceHashedVal
--select @DestHashedVal
IF @SourcehashedVal = @DestHashedVal
	BEGIN
		SELECT 'The sprocs are the same.'
	END
ELSE
	BEGIN
		SELECT 'Please manually review the sprocs:  ' + @Sourcespname + ' != ' + @Destspname + '.'
	END

