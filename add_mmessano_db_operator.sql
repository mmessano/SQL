-- Script generated on 4/27/2007 3:21 PM
-- By: HOME_OFFICE\MMessano
-- Server: NEWTON

IF (EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'rzheng'))
 ---- Delete operator with the same name.
  EXECUTE msdb.dbo.sp_delete_operator @name = N'rzheng'


IF (EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'mmessano'))
 ---- Delete operator with the same name.
  EXECUTE msdb.dbo.sp_delete_operator @name = N'mmessano' 
BEGIN
EXECUTE msdb.dbo.sp_add_operator @name = N'mmessano', @enabled = 1, @email_address = N'mmessano@primealliancesolutions.com', @netsend_address = N'messano338', @category_name = N'[Uncategorized]', @weekday_pager_start_time = 80000, @weekday_pager_end_time = 180000, @saturday_pager_start_time = 80000, @saturday_pager_end_time = 180000, @sunday_pager_start_time = 80000, @sunday_pager_end_time = 180000, @pager_days = 62
END

IF (EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'sbrown'))
 ---- Delete operator with the same name.
  EXECUTE msdb.dbo.sp_delete_operator @name = N'sbrown'
BEGIN
EXECUTE msdb.dbo.sp_add_operator @name = N'sbrown', @enabled = 1, @email_address = N'sbrown@primealliancesolutions.com', @netsend_address = N'brown322', @category_name = N'[Uncategorized]', @weekday_pager_start_time = 80000, @weekday_pager_end_time = 180000, @saturday_pager_start_time = 80000, @saturday_pager_end_time = 180000, @sunday_pager_start_time = 80000, @sunday_pager_end_time = 180000, @pager_days = 62
END