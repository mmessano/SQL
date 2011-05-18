DECLARE @Permissions TABLE (
	[DBName] NVARCHAR(128),
	Permissions NVARCHAR(MAX)
	)
	
INSERT INTO @Permissions
EXEC sp_MSForEachDB '
USE ?
SELECT ''?'', CASE dperms.state_desc
    WHEN ''GRANT_WITH_GRANT_OPTION'' THEN ''GRANT''
    ELSE state_desc
  END
  + '' '' + permission_name + '' ON '' +
  CASE dperms.class
    WHEN 0 THEN ''DATABASE::['' + DB_NAME() + '']''
    WHEN 1 THEN
      CASE dperms.minor_id
        WHEN 0 THEN ''OBJECT::['' + sch.[name] + ''].['' + obj.[name] + '']''
        ELSE ''OBJECT::['' + sch.[name] + ''].['' + obj.[name] + ''] (['' + col.[name] + ''])''
      END
    WHEN 3 THEN ''SCHEMA::['' + SCHEMA_NAME(major_id) + '']''
    WHEN 4 THEN ''USER::['' + USER_NAME(major_id) + '']''
    WHEN 24 THEN ''SYMMETRIC KEY::['' + symm.[name] + '']''
    WHEN 25 THEN ''CERTIFICATE::['' + certs.[name] + '']''
    WHEN 26 THEN ''ASYMMETRIC KEY::['' + asymm.[name] +'']''
  END
  + '' TO ['' + dprins.[name] + '']'' +
  CASE dperms.state_desc
    WHEN ''GRANT_WITH_GRANT_OPTION'' THEN '' WITH GRANT OPTION;''
    ELSE '';''
  END COLLATE database_default AS ''Permissions''
FROM sys.database_permissions dperms
  INNER JOIN sys.database_principals dprins
    ON dperms.grantee_principal_id = dprins.principal_id
  LEFT JOIN sys.columns col
    ON dperms.major_id = col.object_id AND dperms.minor_id = col.column_id
  LEFT JOIN sys.objects obj
    ON dperms.major_id = obj.object_id
  LEFT JOIN sys.schemas sch
    ON obj.schema_id = sch.schema_id
  LEFT JOIN sys.asymmetric_keys asymm
    ON dperms.major_id = asymm.asymmetric_key_id
  LEFT JOIN sys.symmetric_keys symm
    ON dperms.major_id = symm.symmetric_key_id
  LEFT JOIN sys.certificates certs
    ON dperms.major_id = certs.certificate_id
WHERE dperms.type <> ''CO''
    AND dperms.major_id > 0;'

SELECT * FROM @Permissions
ORDER BY 1, 2