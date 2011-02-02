                                                                    CREATE PROC usp_CreateSysObjectsReport
AS
   /***
    *   Date:         4/18/2002
    *   Author:       <mikemcw@4segway.biz>
    *   Project:      Just for fun!
    *   Location:     Any database
    *   Permissions:  PUBLIC EXECUTE
    *   
    *   Description:  Creates an HTML table from SYSOBJECTS
    *   
    *   Restrictions: some permissions may need to be set
    *   
    ***/
BEGIN
   SET CONCAT_NULL_YIELDS_NULL OFF
   SET NOCOUNT ON

   SELECT '<TABLE>'
   UNION ALL
   SELECT '<tr><td><CODE>' + name + '</CODE></td></tr>' FROM sysobjects
   UNION ALL
   SELECT '</TABLE>'
END
GO
GRANT EXECUTE ON usp_CreateSysObjectsReport TO PUBLIC
GO
CREATE PROC usp_writeSysObjectReport(@outfile VARCHAR(255))
AS
   /***
    *   Date:         4/18/2002
    *   Author:       <mikemcw@4segway.biz>
    *   Project:      Just for fun!
    *   Location:     Any database
    *   Permissions:  PUBLIC EXECUTE
    *   
    *   Description:  Writes the SYSOBJECTS report to specified @outfile
    *   
    *   Restrictions: some permissions may need to be set
    *   
    *   TODO!!!!!  CHANGE MYDATABASE TO YOUR DATABASE NAME!!!
    *   
    ***/
BEGIN
   DECLARE @strCommand VARCHAR(255)
   DECLARE @lret       INT

   SET @strCommand = 'bcp "EXECUTE MYDATABASE..usp_CreateSysObjectsReport"'
       + ' QUERYOUT "' + @outfile + '" -T -S' + LOWER(@@SERVERNAME) + ' -c'

   --BCP the HTML file
   PRINT 'EXEC master..xp_cmdshell ''' + @strCommand + ''''
   EXEC @lRet = master..xp_cmdshell @strCommand, NO_OUTPUT

   IF @lret = 0
      PRINT 'File Created'
   ELSE
      PRINT 'Error: ' + str(@lret)
END
GO
GRANT EXECUTE ON usp_writeSysObjectReport TO PUBLIC
GO


