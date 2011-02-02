/*
This script will script the role members for all roles on the database.

This is useful for scripting permissions in a development environment before refreshing
  development with a copy of production.  This will allow us to easily ensure
  development permissions are not lost during a prod to dev restoration. 

Author: S Kusen

*/
/*********************************************/
/*********   DB CONTEXT STATEMENT    *********/
/*********************************************/
SELECT '-- [-- DB CONTEXT --] --' AS [-- SQL STATEMENTS --],
       1                          AS [-- RESULT ORDER HOLDER --]
UNION
SELECT 'USE' + Space(1) + Quotename(Db_name()) AS [-- SQL STATEMENTS --],
       1                                       AS [-- RESULT ORDER HOLDER --]
UNION
SELECT '' AS [-- SQL STATEMENTS --],
       2  AS [-- RESULT ORDER HOLDER --]
UNION
/*********************************************/
/*********    DB ROLE PERMISSIONS    *********/
/*********************************************/
SELECT '-- [-- DB ROLES --] --' AS [-- SQL STATEMENTS --],
       3                        AS [-- RESULT ORDER HOLDER --]
UNION
SELECT 'EXEC sp_addrolemember @rolename =' + Space(1) + Quotename(
              User_name(rm.role_principal_id), '''') +
              ', @membername =' + Space(1) +
       Quotename(
       User_name(rm.member_principal_id), '''')
         AS [-- SQL STATEMENTS --],
       3 AS [-- RESULT ORDER HOLDER --]
FROM   sys.database_role_members AS rm
WHERE  User_name(rm.member_principal_id) IN (
                                            --get user names on the database
                                            SELECT [name]
                                             FROM   sys.database_principals
                                             WHERE  [principal_id] > 4
                                                    -- 0 to 4 are system users/schemas
                                                    AND [type] IN (
                                                        'G', 'S', 'U' )
                                            -- S = SQL user, U = Windows user, G = Windows group
                                            )
--ORDER BY rm.role_principal_id ASC
UNION
SELECT '' AS [-- SQL STATEMENTS --],
       4  AS [-- RESULT ORDER HOLDER --]
UNION
/*********************************************/
/*********  OBJECT LEVEL PERMISSIONS *********/
/*********************************************/
SELECT '-- [-- OBJECT LEVEL PERMISSIONS --] --' AS [-- SQL STATEMENTS --],
       5                                        AS [-- RESULT ORDER HOLDER --]
UNION
SELECT CASE
         WHEN perm.state <> 'W' THEN perm.state_desc
         ELSE 'GRANT'
       END + Space(1) + perm.permission_name + Space(1) + 'ON ' +
              Quotename(User_name(
                        obj.schema_id)) + '.' + Quotename(obj.name)
        --select, execute, etc on specific objects
        + CASE
            WHEN cl.column_id IS NULL THEN Space(0)
            ELSE '(' + Quotename(cl.name) + ')'
          END + Space(1) + 'TO' + Space(1) + Quotename(
                                             User_name(usr.principal_id))
       COLLATE database_default + CASE
                                    WHEN perm.state <> 'W' THEN Space(0)
                                    ELSE Space(1) + 'WITH GRANT OPTION'
                                  END AS [-- SQL STATEMENTS --],
       5                              AS [-- RESULT ORDER HOLDER --]
FROM   sys.database_permissions AS perm
       INNER JOIN sys.objects AS obj
         ON perm.major_id = obj.[object_id]
       INNER JOIN sys.database_principals AS usr
         ON perm.grantee_principal_id = usr.principal_id
       LEFT JOIN sys.columns AS cl
         ON cl.column_id = perm.minor_id
            AND cl.[object_id] = perm.major_id
--WHERE  usr.name = @OldUser
--ORDER BY perm.permission_name ASC, perm.state_desc ASC
UNION
SELECT '' AS [-- SQL STATEMENTS --],
       6  AS [-- RESULT ORDER HOLDER --]
UNION
/*********************************************/
/*********    DB LEVEL PERMISSIONS   *********/
/*********************************************/
SELECT '-- [--DB LEVEL PERMISSIONS --] --' AS [-- SQL STATEMENTS --],
       7                                   AS [-- RESULT ORDER HOLDER --]
UNION
SELECT CASE
         WHEN perm.state <> 'W' THEN perm.state_desc --W=Grant With Grant Option
         ELSE 'GRANT'
       END + Space(1) + perm.permission_name --CONNECT, etc
        + Space(1) + 'TO' + Space(1) + '[' + User_name(usr.principal_id) + ']'
       COLLATE
              database_default --TO 
        + CASE
            WHEN perm.state <> 'W' THEN Space(0)
            ELSE Space(1) + 'WITH GRANT OPTION'
          END AS [-- SQL STATEMENTS --],
       7      AS [-- RESULT ORDER HOLDER --]
FROM   sys.database_permissions AS perm
       INNER JOIN sys.database_principals AS usr
         ON perm.grantee_principal_id = usr.principal_id
--WHERE  usr.name = @OldUser
WHERE  [perm].[major_id] = 0
       AND [usr].[principal_id] > 4 -- 0 to 4 are system users/schemas
       AND [usr].[type] IN ( 'G', 'S', 'U' )
-- S = SQL user, U = Windows user, G = Windows group
ORDER  BY [-- RESULT ORDER HOLDER --]  