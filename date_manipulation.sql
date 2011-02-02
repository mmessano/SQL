

Declare @now CHAR(12)
Declare @min CHAR(2) 
Declare @min2 CHAR(2)
--SELECT @Now = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(50), GETDATE(), 120), '-', ''), ' ', ''), ':', '')
SELECT @Now = LEFT(REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(50), GETDATE(), 120), '-', ''), ' ', ''), ':', ''),12)
print @now
SELECT @min = RIGHT(@now,2)
print @min




Declare @date CHAR(10)
SELECT @date = LEFT(REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(50), GETDATE()-1, 120), '-', ''), ' ', ''), ':', ''),8) + '11'
print @date

print char(42)