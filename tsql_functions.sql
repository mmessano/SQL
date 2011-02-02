SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function A2ROMAN(@n int ) 
--Converts an arabic numeral to roman, as a string.
returns VARCHAR(20)
as
BEGIN
DECLARE @i int, @temp char(1), @s VARCHAR(20)
DECLARE @p1 char(4),@p2 char(4),@p3 char(4),@p4 char(4)
SET @s=STR(@n,4,0)
SET @p1=' '
SET @p2=' '
SET @p3=' '
SET @p4=' '
SET @i=LEN(@s)
WHILE (@i>0)
BEGIN
SET @temp=UPPER(SUBSTRING(@s,@i,1))
IF LEN(@s)-@i=0
	SET @p1=CASE UPPER(SUBSTRING(@s,@i,1))
	WHEN '1' THEN 'I'
	WHEN '2' THEN 'II'
	WHEN '3' THEN 'III'
	WHEN '4' THEN 'IV'
	WHEN '5' THEN 'V'
	WHEN '6' THEN 'VI'
	WHEN '7' THEN 'VII'
	WHEN '8' THEN 'VIII'
	WHEN '9' THEN 'IX'
	ELSE ' '
	END
IF LEN(@s)-@i=1
	SET @p2=CASE UPPER(SUBSTRING(@s,@i,1))
	WHEN '1' THEN 'X'
	WHEN '2' THEN 'XX'
	WHEN '3' THEN 'XXX'
	WHEN '4' THEN 'XL'
	WHEN '5' THEN 'L'
	WHEN '6' THEN 'LX'
	WHEN '7' THEN 'LXX'
	WHEN '8' THEN 'LXXX'
	WHEN '9' THEN 'XC'
ELSE ' '
	END
IF LEN(@s)-@i=2
	SET @p3=CASE UPPER(SUBSTRING(@s,@i,1))
	WHEN '1' THEN 'C'
	WHEN '2' THEN 'CC'
	WHEN '3' THEN 'CCC'
	WHEN '4' THEN 'CD'
	WHEN '5' THEN 'D'
	WHEN '6' THEN 'DC'
	WHEN '7' THEN 'DCC'
	WHEN '8' THEN 'DCCC'
	WHEN '9' THEN 'CM'
ELSE ' '
	END
IF LEN(@s)-@i=3
	SET @p4=CASE UPPER(SUBSTRING(@s,@i,1))
	WHEN '1' THEN 'M'
	WHEN '2' THEN 'MM'
	WHEN '3' THEN 'MMM'
	WHEN '4' THEN 'MMMM'
ELSE ' '
	END
SET @i=@i-1
END
SET @s= @p4+@p3+@p2+@p1
SET @s=REPLACE(@s,' ','')
RETURN @s
END





GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ACOSEC(@a float ) 
--Returns the angle in radians whose cosecant is the given float expression (also called arccosecant).
returns float
as
BEGIN
return (ASIN(1/@a))
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ACOSH(@a float ) 
--Returns the inverse hyperbolic cosine of a number
returns float
as
BEGIN
return LOG(@a+SQRT(@a*@a-1))
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ACOT(@a float ) 
--Returns the angle in radians whose cotangent is the given float expression (also called arccotangent).
returns float
as
BEGIN
return (ATAN(1/@a))
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ADD_MONTHS (@d datetime, @n int ) 
--Returns the date d plus i months
returns datetime
as
BEGIN
RETURN dateadd(m,@n,@d)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ARR(@n bigint, @k bigint) 
--Returns the number of arrangements for a given number of objects.
returns bigint
as
BEGIN
return dbo.FACT(@n)/(dbo.FACT(@n-@k))
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ASCII2EBCDIC(@s VARCHAR(255) ) 
--Converts a string from ASCII to EBCDIC.
returns  VARCHAR(255)
as
BEGIN
DECLARE @i int, @temp char(1),@ebcdic char(1), @result VARCHAR(255) 
SET @i=1
SET @result=''
WHILE (@i<=LEN(@s))
BEGIN
SET @temp=SUBSTRING(@s,@i,1)
SET @ebcdic=CASE @temp
		WHEN char(13) THEN '%'
		WHEN ' ' THEN '@'
		WHEN '.' THEN 'K'
		WHEN '<' THEN 'L'
		WHEN '(' THEN 'M'
		WHEN '+' THEN 'N'
		WHEN '|' THEN 'O'
		WHEN '&' THEN 'P'
		WHEN '!' THEN 'Z'
		WHEN '$' THEN CHAR(91)
		WHEN ')' THEN CHAR(92)
		WHEN '*' THEN CHAR(93)
		WHEN ';' THEN CHAR(94)
		WHEN '-' THEN CHAR(96)
		WHEN '`' THEN CHAR(185)
		WHEN '/' THEN 'a'
		WHEN ',' THEN 'k'
		WHEN '%' THEN 'l'
		WHEN '_' THEN 'm'
		WHEN '>' THEN 'n'
		WHEN '?' THEN 'o'
		WHEN '' THEN 'p'
		WHEN ':' THEN 'z'
		WHEN '#' THEN CHAR(123)
		WHEN '@' THEN CHAR(124)
		WHEN '''' THEN CHAR(125)
		WHEN '=' THEN CHAR(126)
		WHEN '"' THEN CHAR(127)
		ELSE ''
		END
IF @ebcdic=''
SET @ebcdic=CASE
	WHEN ASCII(@temp) BETWEEN 97 AND 105 THEN CHAR(ASCII(@temp)+32) 
	WHEN ASCII(@temp) BETWEEN 106 AND 114 THEN CHAR(ASCII(@temp)+39) 
	WHEN ASCII(@temp) BETWEEN 115 AND 122 THEN CHAR(ASCII(@temp)+47) 
	WHEN ASCII(@temp) BETWEEN 65 AND 73 THEN CHAR(ASCII(@temp)+128) 
	WHEN ASCII(@temp) BETWEEN 74 AND 82 THEN CHAR(ASCII(@temp)+135)
	WHEN ASCII(@temp) BETWEEN 83 AND 90 THEN CHAR(ASCII(@temp)+143)
	WHEN ASCII(@temp) BETWEEN 48 AND 57 THEN CHAR(ASCII(@temp)+192)
	ELSE ''
	END
SET @result=@result+@ebcdic
SET @i=@i+1
END
RETURN   @result
END




GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ASEC(@a float ) 
--Returns the angle in radians whose secant is the given float expression (also called arcsecant).
returns float
as
BEGIN
return (ACOS(1/@a))
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ASINH(@a float ) 
--Returns the inverse hyperbolic sine of a number.
returns float
as
BEGIN
return LOG(@a+SQRT(@a*@a+1))
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ATANH(@a float ) 
--Returns the inverse hyperbolic tangent of a number.
returns float
as
BEGIN
return LOG((1+@a)/(1-@a))/2
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function BINTODEC(@s VARCHAR(255) ) 
--Converts a binary number to decimal.
returns int
as
BEGIN
DECLARE @i int, @temp char(1), @result int
SELECT @i=1
SELECT @result=0
WHILE (@i<=LEN(@s))
BEGIN
SELECT @temp=SUBSTRING(@s,@i,1)
SELECT @result=@result+ (ASCII(@temp)-48)*POWER(2,LEN(@s)-@i)
SELECT @i=@i+1
END
return @result
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function CHARINDEXREV(@s varchar(255),@p varchar(255) ) 
--Returns the position of an occurrence of one string within another, from the end of string.
returns int
as
BEGIN
DECLARE @i int
SET @i=1
WHILE charindex(@s, @p, @i)>0
BEGIN
SET @i=charindex(@s, @p, @i)+1
END
IF @i>0
	SET @i=@i-1
RETURN  @i
END




GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function COMBIN(@n bigint, @k bigint) 
--Returns the number of combinations for a given number of objects.
returns bigint
as
BEGIN
return dbo.FACT(@n)/(dbo.FACT(@k)*dbo.FACT(@n-@k))
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function COMPLEMENT1(@a int ) 
--Returns a number's one's complement.
returns int
as
BEGIN
return ~@a
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function COMPLEMENT2(@a int ) 
--Returns a number's two's complement.
returns int
as
BEGIN
return (~@a+1)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function COSEC(@a float ) 
--Returns the trigonometric cosecant of the given angle (in radians) in the given expression.
returns float
as
BEGIN
return (1/SIN(@a))
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function COSECH(@a float ) 
--Returns the hyperbolic cosecant of a number.
returns float
as
BEGIN
return 2/( POWER(dbo.E(),@a) -  POWER(dbo.E(),-@a) )
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function COSH(@a float ) 
--Returns the hyperbolic cosine of a number.
returns float
as
BEGIN
return ( POWER(dbo.E(),@a) +  POWER(dbo.E(),-@a) )/2
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function COTH(@a float ) 
--Returns the hyperbolic cotangent of a number.
returns float
as
BEGIN
return (dbo.COSH(@a)/dbo.SINH(@a))
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function CRYPTX8( @s VARCHAR(1024), @k VARCHAR(8) ) 
--Returns a string s1 encrypted/decrypted with key s2, up to 8 chars ( XOR encryption ). 
returns VARCHAR(1024)
as
BEGIN
DECLARE @result VARCHAR(1024), @l int, @i int, @j int, @temp tinyint, @x tinyint
SET @i=LEN(@k)
IF @i<8--if the pwd<8 char
	BEGIN
	SET @k=@k+@k+@k+@k+@k+@k+@k+@k--add pwd to itself
	SET @k=LEFT(@k,8)
	END
SET @l=(LEN(@s) % 8)
IF @l<>0--if there are no complete 64 bit blocks
	BEGIN
	SET @i=(LEN(@s))/8+1
	SET @l= @i*8-len(@s)
	SET @s=@s+replicate('*',@l)
	END
SET @i=1
SET @result=''
WHILE @i<=LEN(@s)
	BEGIN
	SET @j=0
	WHILE @j<8
		BEGIN	
		SET @temp=ASCII(SUBSTRING(@s,@i+@j,1))
		SET @x=ASCII(SUBSTRING(@k,@j+1,1))
		SET @result=@result + CHAR(@temp ^ @x)	
		SET @j=@j+1
		END
	SET @i=@i+8
	END
IF @l<>0
	BEGIN	
	SET @result=LEFT(@result,LEN(@result)-@l)
	END
RETURN    @result
END




GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function CUBE(@a float ) 
--Returns the cube of the given expression.
returns float
as
BEGIN
return @a*@a*@a
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO


CREATE function DDATE( @d as DATETIME) 
--Returns the date from a datetime input as a string.
returns varchar(255)
as
BEGIN
DECLARE @s varchar(255) 
SET @s= CONVERT(VARCHAR(255),@d,101)
RETURN @s
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function DEC(@a int ) 
--Returns a number decremented by 1.
returns int
as
BEGIN
return @a-1
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function DECTOBIN(@n int ) 
--Converts a decimal number to binary.
returns varchar(255)
as
BEGIN
DECLARE @i int,@temp int, @s varchar(255)
SET @i=@n
SET @s=''
WHILE (@i>0)
BEGIN
SET @temp=@i % 2
SET @i=@i /2
SET @s=char(48+@temp)+@s
END
RETURN @s
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function DECTOHEX(@n int ) 
--Converts a decimal number to hexadecimal.
returns varchar(255)
as
BEGIN
DECLARE @i int,@temp int, @s varchar(255)
SET @i=@n
SET @s=''
WHILE (@i>0)
BEGIN
SET @temp=@i % 16
SET @i=@i /16
IF @temp>9
	SET @s=char(55+@temp)+@s
ELSE
	SET @s=char(48+@temp)+@s
END
RETURN @s
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function DECTON(@n int, @b int ) 
--Converts a decimal number to base n.
returns varchar(255)
as
BEGIN
DECLARE @i int,@temp int, @s varchar(255)
SET @i=@n
SET @s=''
WHILE (@i>0)
BEGIN
SET @temp=@i % @b
SET @i=@i /@b
IF @temp>9
	SET @s=char(55+@temp)+@s
ELSE
	SET @s=char(48+@temp)+@s
END
RETURN @s
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function DECTOOCT(@n int ) 
--Converts a decimal number to octal.
returns varchar(255)
as
BEGIN
DECLARE @i int,@temp int, @s varchar(255)
SET @i=@n
SET @s=''
WHILE (@i>0)
BEGIN
SET @temp=@i % 8
SET @i=@i /8
SET @s=char(48+@temp)+@s
END
RETURN @s
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function DEG2GRAD(@a float ) 
--Converts an angle from degrees to grads.
returns float
as
BEGIN
return (@a*10.0/9.0)
END

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO


CREATE function DISTANCE(@x1 float,@y1 float, @x2 float,@y2 float) 
--Returns the distance between 2 points P(f1, f2) to T(f3, f4). 
returns float
as
BEGIN
return sqrt((@x1-@x2)*(@x1-@x2)+(@y1-@y2)*(@y1-@y2))
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function DIVI(@a bigint, @b bigint, @precision bigint) 
--Returns the result of the division of i1 by i2 with precision i3 (Infinite precision division).  
returns VARCHAR(5000)
as
BEGIN
DECLARE @l bigint, @p bigint,@d bigint,@t bigint,@result VARCHAR(5000), @err bit
SET @result=''
SET @l=10
SET @err=0
SET @t=@a/@b
WHILE @err=0
	BEGIN
	SET @a=@a*@l
	IF @b>@a
		SET @result=@result+'0'
	WHILE (@b > @a)
		BEGIN
		SET @a=@a*@l
		IF @b>@a
			SET @result=@result+'0'
		END
	SET @p=@a/@b
	IF (@p * @b) < @a 
		SET @p = @p + 1
	SET @d = @p * @b
	IF @d=@a
		BEGIN
		SET @err=1
		SET @result=@result+CONVERT(VARCHAR(20),(@p))
		END
	IF @d>@a
		BEGIN
		SET @p=@p-1
		SET @result=@result+CONVERT(VARCHAR(20),(@p))
		IF LEN(@result)>@precision
			SET @err=1
		SET @a = @a - @p * @b
		END
	END
SET @l=LEN(CONVERT(VARCHAR(20),(@t)))
IF @p=0
	SET @result='0.'+@result
ELSE
	SET @result=LEFT(@result,@l)+'.'+RIGHT(@result,LEN(@result)-@l)
RETURN  @result
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO


CREATE function DTIME( @d as DATETIME) 
--Returns the time from a datetime input as a string.
returns varchar(255)
as
BEGIN
DECLARE @s varchar(255) 
SET @s= CONVERT(VARCHAR(255),@d,108)
RETURN @s
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function E( ) 
--Returns e, Natural Logarithmic Base.
returns float
as
BEGIN
return EXP(1)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function EBCDIC2ASCII(@s VARCHAR(255) ) 
--Converts a string from EBCDIC to ASCII.
returns  VARCHAR(255)
as
BEGIN
DECLARE @i int, @temp char(1),@ebcdic char(1), @result VARCHAR(255) 
SET @i=1
SET @result=''
WHILE (@i<=LEN(@s))
BEGIN
SET @temp=SUBSTRING(@s,@i,1)
SET @ebcdic=CASE @temp
		WHEN '%' THEN char(13)
		WHEN '@' THEN ' '
		WHEN 'K' THEN '.'
		WHEN 'L' THEN '<'
		WHEN 'M' THEN '('
		WHEN 'N' THEN '+'
		WHEN 'O' THEN '|'
		WHEN 'P' THEN '&'
		WHEN 'Z' THEN '!'
		WHEN CHAR(91) THEN '$'
		WHEN CHAR(92) THEN ')'
		WHEN CHAR(93) THEN '*'
		WHEN CHAR(94) THEN ';'
		WHEN CHAR(96) THEN '-'
		WHEN CHAR(185) THEN '`'
		WHEN 'a' THEN '/'
		WHEN 'k' THEN ','
		WHEN 'l' THEN '%'
		WHEN 'm' THEN '_'
		WHEN 'n' THEN '>'
		WHEN 'o' THEN '?'
		WHEN 'p' THEN ''
		WHEN 'z' THEN ':'
		WHEN CHAR(123) THEN '#'
		WHEN CHAR(124) THEN '@'
		WHEN CHAR(125) THEN ''''
		WHEN CHAR(126) THEN '='
		WHEN CHAR(127) THEN '"'
		ELSE ''
		END
IF @ebcdic=''
	SET @ebcdic=CASE
			WHEN ASCII(@temp) BETWEEN 129 AND 137 THEN CHAR(ASCII(@temp)-32) 
			WHEN ASCII(@temp) BETWEEN 145 AND 153 THEN CHAR(ASCII(@temp)-39) 
			WHEN ASCII(@temp) BETWEEN 162 AND 169 THEN CHAR(ASCII(@temp)-47) 
			WHEN ASCII(@temp) BETWEEN 193 AND 201 THEN CHAR(ASCII(@temp)-128) 
			WHEN ASCII(@temp) BETWEEN 209 AND 217 THEN CHAR(ASCII(@temp)-135)
			WHEN ASCII(@temp) BETWEEN 226 AND 233 THEN CHAR(ASCII(@temp)-143)
			WHEN ASCII(@temp) BETWEEN 240 AND 249 THEN CHAR(ASCII(@temp)-192)
			ELSE ''
			END
SET @result=@result+@ebcdic
SET @i=@i+1
END
RETURN @result
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function EQUIVALENT(@a int, @b int ) 
--Returns the result of a logical formal equivalence.
returns int
as
BEGIN
return ~(@a ^ @b)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function FACT(@n bigint) 
--Returns the factorial of a number.
returns bigint
as
BEGIN
    declare @temp bigint
    if (@n <= 1) 
	select @temp = 1
    else 
        select @temp = @n * dbo.FACT(@n - 1)
    return @temp
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function FACTDOUBLE(@n float ) 
--Returns the double factorial of a number.
returns float 
as
BEGIN
    declare @temp float 
    if (@n <= 1) 
	select @temp = 1
    else 
        select @temp = @n * dbo.FACTDOUBLE(@n - 1)
    return @temp
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function FIBONACCI(@n bigint) 
--Returns the Fibonacci series for a given number.
returns bigint
as
BEGIN
    declare @temp bigint
    if (@n <=2) 
	select @temp = 1
    else 
        select @temp =  dbo.FACT(@n - 1)+ dbo.FACT(@n - 2)
    return @temp
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function FRAC(@a float ) 
--Returns the decimal part of a number.
returns float
as
BEGIN
return (@a-convert(int,@a))
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function FROMMORSE(@s varchar(255) ) 
--Returns the text corresponding to a morse code string.
returns  varchar(255)
as
BEGIN
DECLARE @i int,@j int,@p int, @result varchar(255),@chars1 char(26),@chars2 char(10)
DECLARE @chars3 char(3), @morse1 char(104)
DECLARE @morse2 char(50),@morse3 char(18), @temp varchar(6)
SET @chars1='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
SET @chars2='0123456789'
SET @chars3='.,?'
SET @morse1='.-  -...-.-.-.. .   ..-.--. ......  .----.- .-..--  -.  --- .--.--.-.-. ... -   ..- ...-.-- -..--.----..'
SET @morse2='-----.----..---...--....-.....-....--...---..----.'
SET @morse3='.-.-.---..--..--..'
SET @result=''
SET @s=LTRIM(RTRIM(@s))
WHILE CHARINDEX('  ',@s)>0
	SET @s=REPLACE(@s,'  ',' ')
SET @s=@s+' '
SET @i=1
SET @j=CHARINDEX(' ',@s,@i)-1
WHILE (@j>0)
BEGIN
SET @temp=(SUBSTRING(@s,@i,@j-@i+1))
IF LEN(@temp)<5
	BEGIN
	SET @p=1
	WHILE @p<(104)
		BEGIN
		IF @temp=LTRIM(RTRIM(SUBSTRING(@morse1,@p,4)))
			SET @result=@result+SUBSTRING(@chars1,@p/4+1,1)
		SET @p=@p+4
		END
	END 
IF LEN(@temp)=5
	BEGIN
	SET @p=1
	WHILE @p<(50)
		BEGIN
		IF @temp=LTRIM(RTRIM(SUBSTRING(@morse2,@p,5)))
			SET @result=@result+SUBSTRING(@chars2,@p/5+1,1)
		SET @p=@p+5
		END
	END 
IF LEN(@temp)=6
	BEGIN
	SET @p=1
	WHILE @p<(18)
		BEGIN
		IF @temp=LTRIM(RTRIM(SUBSTRING(@morse3,@p,6)))
			SET @result=@result+SUBSTRING(@chars3,@p/6+1,1)
		SET @p=@p+6
		END
	END 
SET @i=@j+2
SET @j=CHARINDEX(' ',@s,@i)-1
END
RETURN @result
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function GCD(@a int, @b int) 
--Returns the greatest common divisor of 2 numbers.
returns int
as
BEGIN
declare @c int
select @c=1
While (@c <> 0)
	BEGIN        
	select @c=@a % @b
	select @a=@b
	select @b=@c
        END
return @a
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function GETBIT(@a int, @b int ) 
--Returns the value of a certain bit.
returns int
as
BEGIN
return ABS(SIGN(@a & (POWER(2,@b))))
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function GRAD2DEG(@a float ) 
--Converts an angle from grads to degrees.
returns float
as
BEGIN
return (@a*9.0/10.0)
END

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function GRAD2RAD(@a float ) 
--Converts an angle from grads to radians.
returns float
as
BEGIN
return (@a*200.0/PI())
END

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO


CREATE function GREGORIAN2HIJRI(@d datetime) 
--Returns the date FROM Gregorian into Hijri calendar
returns NVARCHAR(100)
as
BEGIN
return CONVERT(NVARCHAR(100), @d, 131)
END




GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function HEXTODEC(@s VARCHAR(255) ) 
--Converts an hexadecimal number to decimal.
returns int
as
BEGIN
DECLARE @i int, @temp char(1), @result int
SELECT @i=1
SELECT @result=0
WHILE (@i<=LEN(@s))
BEGIN
SELECT @temp=UPPER(SUBSTRING(@s,@i,1))
IF (@temp>='0') AND (@temp<='9') 
	SELECT @result=@result+ (ASCII(@temp)-48)*POWER(16,LEN(@s)-@i)
ELSE
	IF (@temp>='A') AND (@temp<='F') 
		SELECT @result=@result+ (ASCII(@temp)-55)*POWER(16,LEN(@s)-@i)
SELECT @i=@i+1
END
return @result
END




GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO


CREATE function HIJRI2GREGORIAN(@d NVARCHAR(100)) 
--Returns the date FROM Hijri into Gregorian calendar
returns datetime
as
BEGIN
return  CONVERT(datetime, @d, 131)
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function IIF(@b bit, @t SQL_VARIANT,@f SQL_VARIANT  ) 
--Returns one of two parts, depending on the evaluation of an expression.
returns SQL_VARIANT
as
BEGIN
DECLARE @temp SQL_VARIANT
IF @b=1
	SELECT @temp=@t
ELSE 
	SELECT @temp=@f
return @temp
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function IMPLIES(@a int, @b int ) 
--Returns the result of a logical formal implication.
returns int
as
BEGIN
return ~@a | @b
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function INC(@a int ) 
--Returns a number incremented by 1.
returns int
as
BEGIN
return @a+1
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function INCLUDED(@s varchar(255),@p varchar(255) ) 
--Returns how many times a string is included (occurs) into another one.
returns int
as
BEGIN
DECLARE @i int,@c int
SET @i=1
SET @c=0
WHILE charindex(@s, @p, @i)>0
BEGIN
SET @i=charindex(@s, @p, @i)+1
SET @c=@c+1
END
RETURN  @c
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function INITCAP (@s varchar(255) ) 
--Returns a string with the first letter of each word in uppercase, all other letters in lowercase (capitalize first character).  
returns varchar(255)
as
BEGIN
DECLARE @i int, @c char(1),@result varchar(255)
SET @result=LOWER(@s)
SET @i=2
SET @result=STUFF(@result,1,1,UPPER(SUBSTRING(@s,1,1)))
WHILE @i<=LEN(@s)
	BEGIN
	SET @c=SUBSTRING(@s,@i,1)
	IF (@c=' ') OR (@c=';') OR (@c=':') OR (@c='!') OR (@c='?') OR (@c=',')OR (@c='.')OR (@c='_')
		IF @i<LEN(@s)
			BEGIN
			SET @i=@i+1
			SET @result=STUFF(@result,@i,1,UPPER(SUBSTRING(@s,@i,1)))
			END
	SET @i=@i+1
	END
RETURN  @result
END




GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function IPOCTECT(@s varchar(15), @o int) 
--Returns an octect i (1-4) from an IP.
returns varchar(3)
as
BEGIN
DECLARE @u VARCHAR(3), @v VARCHAR(3), @x VARCHAR(3),@y VARCHAR(3), @i int, @j int, @result varchar(15)
IF (dbo.INCLUDED('.',@s)<>3) OR (@i<1) OR (@i>4)
	BEGIN
	SET @result=''
	GOTO done
	END
SET @i=CHARINDEX('.',@s)
SET @u=LEFT(@s,@i-1)
SET @j=CHARINDEX('.',@s,@i+1)
SET @v=substring(@s,@i+1,@j-@i-1)
SET @i=CHARINDEX('.',@s,@j+1)
SET @x=substring(@s,@j+1,@i-@j-1)
SET @y=substring(@s,@i+1,LEN(@s)-@i)
IF ISNUMERIC(@u)=0 OR ISNUMERIC(@v)=0 OR ISNUMERIC(@x)=0 OR ISNUMERIC(@y)=0
	BEGIN
	SET @result=''
	GOTo done
	END
IF (CONVERT(INT, @u)<0) OR  (CONVERT(INT, @v)<0) OR  (CONVERT(INT, @x)<0)  OR  (CONVERT(INT, @y)<0) 
	BEGIN
	SET @result=''
	GOTo done
	END
IF (CONVERT(INT, @u)>255) OR  (CONVERT(INT, @v)>255) OR  (CONVERT(INT, @x)>255)  OR  (CONVERT(INT, @y)>255) 
	BEGIN
	SET @result=''
	GOTo done
	END
SET @result=CASE @o
	WHEN 1 THEN @u
	WHEN 2 THEN @v
	WHEN 3 THEN @x
	WHEN 4 THEN @y
	END
done:
RETURN  @result
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISABUNDNUM(@n bigint ) 
--Returns true if the number is abundant
returns bit
as
BEGIN
DECLARE @b bit
IF dbo.SUMALIQUOT(@n)>@n
	SET @b=1
ELSE
	SET @b=0
RETURN @b
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISALPHA(@s VARCHAR(50) ) 
--Returns true if the string has valid alphanumeric characters.
returns bit
as
BEGIN
DECLARE @i int, @temp char(1), @bool bit
SELECT @i=1
SELECT @bool=0
WHILE (@i<=LEN(@s))
BEGIN
SELECT @temp=SUBSTRING(@s,@i,1)
--PRINT @temp
if (@temp<='z') AND (@temp>='a') OR  (@temp<='Z') AND (@temp>='A') OR  (@temp<='9') AND (@temp>='0') OR (@temp='-')  OR (@temp='.') 
	SELECT @bool=1
SELECT @i=@i+1
END
return @bool
END





GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISBIN(@s VARCHAR(50) ) 
--Returns true if the string is a valid binary number. 
returns bit
as
BEGIN
DECLARE @i int, @temp char(1), @bool bit
SELECT @i=1
SELECT @bool=0
WHILE (@i<=LEN(@s))
BEGIN
SELECT @temp=SUBSTRING(@s,@i,1)
--PRINT @temp
if  (@temp='0')  OR (@temp='1') 
	SELECT @bool=1
SELECT @i=@i+1
END
return @bool
END






GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISDEFNUM(@n bigint ) 
--Returns true if the number is deficient
returns bit
as
BEGIN
DECLARE @b bit
IF dbo.SUMALIQUOT(@n)<@n
	SET @b=1
ELSE
	SET @b=0
RETURN @b
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISEMPTY(@a SQL_VARIANT ) 
--Returns true if the input is empty.
returns BIT
as
BEGIN
DECLARE @temp bit
IF (@a='')
	SELECT @temp=1
ELSE
	SELECT @temp=0
return @temp
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISEVEN(@a int ) 
--Returns true if the number is even.
returns bit
as
BEGIN
return ~(CONVERT(bit, @a & 1 ))
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISHEX(@s VARCHAR(50) ) 
--Returns true if the string is a valid hexadecimalal number. 
returns bit
as
BEGIN
DECLARE @i int, @temp char(1), @bool bit
SELECT @i=1
SELECT @bool=0
WHILE (@i<=LEN(@s))
BEGIN
SELECT @temp=SUBSTRING(@s,@i,1)
if (@temp<='f') AND (@temp>='a') OR  (@temp<='F') AND (@temp>='A') OR  (@temp<='9') AND (@temp>='0')  
	SELECT @bool=1
SELECT @i=@i+1
END
return @bool
END






GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISINTNUMBER(@s VARCHAR(50) ) 
--Returns true if the string is a valid integer number.
returns bit
as
BEGIN
DECLARE @i int, @temp char(1), @bool bit
SELECT @i=1
SELECT @bool=0
WHILE (@i<=LEN(@s))
BEGIN
SELECT @temp=SUBSTRING(@s,@i,1)
if (@temp<='9') AND (@temp>='0') OR (@temp='-') 
	SELECT @bool=1
SELECT @i=@i+1
END
return @bool
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISINTPOSNUMBER(@s VARCHAR(50) ) 
--Returns true if the string is a valid positive integer number. 
returns bit
as
BEGIN
DECLARE @i int, @temp char(1), @bool bit
SELECT @i=1
SELECT @bool=1
WHILE (@i<=LEN(@s))
BEGIN
SELECT @temp=SUBSTRING(@s,@i,1)
--PRINT @temp
if (@temp>'9') OR (@temp<'0')
	SELECT @bool=0
SELECT @i=@i+1
END
return @bool
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISITNULL(@a SQL_VARIANT ) 
--Returns true if the input is null.
returns BIT
as
BEGIN
DECLARE @temp bit
IF (@a=NULL)
	SELECT @temp=1
ELSE
	SELECT @temp=0
return @temp
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISLETTER(@s VARCHAR(50) ) 
--Returns true if the string has only letters.
returns bit
as
BEGIN
DECLARE @i int, @temp char(1), @bool bit
SELECT @i=1
SELECT @bool=0
WHILE (@i<=LEN(@s))
BEGIN
SELECT @temp=SUBSTRING(@s,@i,1)
--PRINT @temp
if (@temp<='z') AND (@temp>='a') OR  (@temp<='Z') AND (@temp>='A') 
	SELECT @bool=1
SELECT @i=@i+1
END
return @bool
END




GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISNEG(@a float ) 
--Returns true if the number is negative.
returns BIT
as
BEGIN
DECLARE @temp bit
IF (@a < 0)
	SELECT @temp=1
ELSE
	SELECT @temp=0
return @temp
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISNUMBER(@s VARCHAR(50) ) 
--Returns true if the string is a valid number. 
returns bit
as
BEGIN
DECLARE @i int, @temp char(1), @bool bit
SELECT @i=1
SELECT @bool=0
WHILE (@i<=LEN(@s))
BEGIN
SELECT @temp=SUBSTRING(@s,@i,1)
--PRINT @temp
if (@temp<='9') AND (@temp>='0') OR (@temp='-')  OR (@temp='.') 
	SELECT @bool=1
SELECT @i=@i+1
END
return @bool
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISOCT(@s VARCHAR(50) ) 
--Returns true if the string is a valid octal number.
returns bit
as
BEGIN
DECLARE @i int, @temp char(1), @bool bit
SELECT @i=1
SELECT @bool=1
WHILE (@i<=LEN(@s))
BEGIN
SELECT @temp=SUBSTRING(@s,@i,1)
--PRINT @temp
if (@temp>'7') OR (@temp<'0')
	SELECT @bool=0
SELECT @i=@i+1
END
return @bool
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISODD(@a int ) 
--Returns true if the number is odd.
returns bit
as
BEGIN
return CONVERT(bit, @a & 1 )
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISPERFNUM(@n bigint ) 
--Returns true if the number is perfect
returns bit
as
BEGIN
DECLARE @b bit
IF dbo.SUMALIQUOT(@n)=@n
	SET @b=1
ELSE
	SET @b=0
RETURN @b
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISPOSNUMBER(@s VARCHAR(50) ) 
--Returns true if the string is a valid positive number.
returns bit
as
BEGIN
DECLARE @i int, @temp char(1), @bool bit
SELECT @i=1
SELECT @bool=0
WHILE (@i<=LEN(@s))
BEGIN
SELECT @temp=SUBSTRING(@s,@i,1)
--PRINT @temp
if (@temp<='9') AND (@temp>='0')  OR (@temp='.') 
	SELECT @bool=1
SELECT @i=@i+1
END
return @bool
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISPRIME(@i INT ) 
--Returns true if the number is prime. 
returns bit
as
BEGIN
DECLARE @c int, @t int, @result bit
SET @result=1
IF (@i & 1)=0
	BEGIN
	SET @result=0
	GOTO done
	END
SET @c=3
SET @t=SQRT(@i)
WHILE @c<=@t
	BEGIN
	IF @i % @c=0
		BEGIN
		SET @result=0
		GOTO done
		END
	SET @c=@c+2
	END
done:
RETURN  @result
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ISROMAN(@s VARCHAR(255) ) 
--Returns true if the string is a valid Roman numeral.
returns bit
as
BEGIN
DECLARE @i int, @temp char(1), @bool bit
SELECT @i=1
SELECT @bool=1
WHILE (@i<=LEN(@s))
BEGIN
SELECT @temp=UPPER(SUBSTRING(@s,@i,1))
--LOOK FOR INVALID CHARS
if  NOT( (@temp='I')  OR (@temp='V') OR (@temp='X') OR (@temp='L') OR (@temp='C') OR (@temp='D')  OR (@temp='M') )
	SELECT @bool=0
SELECT @i=@i+1
END
--LOOK FOR INVALID SEQUENCE SUCH AS IIII INSTEAD OF IV
IF (CHARINDEX('IIII',UPPER(@s))>0) OR (CHARINDEX('VV',UPPER(@s))>0) OR (CHARINDEX('XXXX',UPPER(@s))>0) OR (CHARINDEX('LL',UPPER(@s))>0) OR (CHARINDEX('CCCC',UPPER(@s))>0) OR (CHARINDEX('DD',UPPER(@s))>0) OR (CHARINDEX('MMMMM',UPPER(@s))>0)
	SELECT @bool=0
--LOOK FOR INVALID PRECEDENCE SUCH AS IL (49?) INSTEAD OF XLIX
IF (CHARINDEX('IL',UPPER(@s))>0) OR (CHARINDEX('IC',UPPER(@s))>0) OR (CHARINDEX('ID',UPPER(@s))>0) OR (CHARINDEX('IM',UPPER(@s))>0) OR (CHARINDEX('VX',UPPER(@s))>0) OR (CHARINDEX('VL',UPPER(@s))>0) OR (CHARINDEX('VC',UPPER(@s))>0) OR (CHARINDEX('VD',UPPER(@s))>0) OR (CHARINDEX('VM',UPPER(@s))>0) OR (CHARINDEX('XC',UPPER(@s))>0) OR (CHARINDEX('XD',UPPER(@s))>0) OR (CHARINDEX('XM',UPPER(@s))>0) OR (CHARINDEX('LC',UPPER(@s))>0) OR (CHARINDEX('LD',UPPER(@s))>0) OR (CHARINDEX('LM',UPPER(@s))>0) OR (CHARINDEX('CM',UPPER(@s))>0) OR (CHARINDEX('DM',UPPER(@s))>0)
	SELECT @bool=0
--LOOK FOR INVALID PRECEDENCE SUCH AS IIV INSTEAD OF III
IF (CHARINDEX('IIV',UPPER(@s))>0) OR (CHARINDEX('IIX',UPPER(@s))>0) OR (CHARINDEX('XXL',UPPER(@s))>0) OR (CHARINDEX('XXC',UPPER(@s))>0) OR (CHARINDEX('CCD',UPPER(@s))>0) OR (CHARINDEX('CCM',UPPER(@s))>0)
	SELECT @bool=0
return @bool
END









GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function LAST_DAY(@d datetime ) 
returns datetime
as
BEGIN
DECLARE @nextmonth datetime, @i int
SET @nextmonth=dateadd(m,1,@d)
SET @i=-day(@nextmonth)
SET @nextmonth=dateadd(d,@i,@nextmonth)
return day(@nextmonth) 
END

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function LCM(@a int, @b int ) 
--Returns the least common multiple of 2 numbers.
returns int
as
BEGIN
return (@a * @b) / dbo.GCD(@a, @b)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function LEVENSHTEIN( @s varchar(50), @t varchar(50) ) 
--Returns the Levenshtein Distance between strings s1 and s2.
--Original developer: Michael Gilleland    http://www.merriampark.com/ld.htm
--Translated to TSQL by Joseph Gama
returns varchar(50)
as
BEGIN
DECLARE @d varchar(2500), @LD int, @m int, @n int, @i int, @j int,
@s_i char(1), @t_j char(1),@cost int
--Step 1
SET @n=LEN(@s)
SET @m=LEN(@t)
SET @d=replicate(CHAR(0),2500)
If @n = 0
	BEGIN
	SET @LD = @m
	GOTO done
	END
If @m = 0
	BEGIN
	SET @LD = @n
	GOTO done
	END
--Step 2
SET @i=0
WHILE @i<=@n
	BEGIN
	SET @d=STUFF(@d,@i+1,1,CHAR(@i))--d(i, 0) = i
	SET @i=@i+1
	END

SET @i=0
WHILE @i<=@m
	BEGIN
	SET @d=STUFF(@d,@i*(@n+1)+1,1,CHAR(@i))--d(0, j) = j
	SET @i=@i+1
	END
--goto done
--Step 3
	SET @i=1
	WHILE @i<=@n
		BEGIN
		SET @s_i=(substring(@s,@i,1))
--Step 4
	SET @j=1
	WHILE @j<=@m
		BEGIN
		SET @t_j=(substring(@t,@j,1))
		--Step 5
		If @s_i = @t_j
			SET @cost=0
		ELSE
			SET @cost=1
--Step 6
		SET @d=STUFF(@d,@j*(@n+1)+@i+1,1,CHAR(dbo.MIN3(
		ASCII(substring(@d,@j*(@n+1)+@i-1+1,1))+1,
		ASCII(substring(@d,(@j-1)*(@n+1)+@i+1,1))+1,
		ASCII(substring(@d,(@j-1)*(@n+1)+@i-1+1,1))+@cost)
		))
		SET @j=@j+1
		END
	SET @i=@i+1
	END      
--Step 7
SET @LD = ASCII(substring(@d,@n*(@m+1)+@m+1,1))
done:
--RETURN @LD
--I kept this code that can be used to display the matrix with all calculated values
--From Query Analyser it provides a nice way to check the algorithm in action
--
RETURN @LD
--declare @z varchar(8000)
--set @z=''
--SET @i=0
--WHILE @i<=@n
--	BEGIN
--	SET @j=0
--	WHILE @j<=@m
--		BEGIN
--		set @z=@z+CONVERT(char(3),ASCII(substring(@d,@i*(@m+1 )+@j+1 ,1)))
--		SET @j=@j+1 
--		END
--	SET @i=@i+1
--	END
--print dbo.wrap(@z,3*(@n+1))
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function LOG2( @n float) 
--Returns the logarithm (base 2) of the given float expression.
returns float
as
BEGIN
    return LOG(@n)/LOG(2)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function LOGN(@b float, @n float) 
--Returns the logarithm (base b) of the given float expression.
returns float
as
BEGIN
    return LOG(@n)/LOG(@b)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function LPAD(@s varchar(255), @n int, @p varchar(255) ) 
--Returns a string s1 left-padded to length i with a sequence of characters s2. 
returns varchar(255)
as
BEGIN
return REPLICATE(@p,@n)+@s
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function MAX2(@a int,@b int ) 
--Returns the largest of 2 numbers.
returns int
as
BEGIN
declare @temp int
if (@a > @b) 
	select @temp=@a
else 
	select @temp=@b
return @temp
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function MAX3(@a int,@b int,@c int ) 
--Returns the largest of 3 numbers.
returns int
as
BEGIN
declare @temp int
if (@a > @b)  AND (@a > @c)
	select @temp=@a
else 
	if (@b > @a)  AND (@b > @c)
		select @temp=@b
	else
		select @temp=@c
return @temp
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function MIN2(@a int,@b int ) 
--Returns the smallest of 2 numbers.
returns int
as
BEGIN
declare @temp int
if (@a < @b) 
	select @temp=@a
else 
	select @temp=@b
return @temp
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function MIN3(@a int,@b int,@c int ) 
--Returns the smallest of 3 numbers.
returns int
as
BEGIN
declare @temp int
if (@a < @b)  AND (@a < @c)
	select @temp=@a
else 
	if (@b < @a)  AND (@b < @c)
		select @temp=@b
	else
		select @temp=@c
return @temp
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function MONTHS_BETWEEN ( @d datetime, @e datetime ) 
--Returns number of months between dates d1 and d2. 
returns int
as
BEGIN
return datediff(m, @d, @e)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function MORSE(@s varchar(255) ) 
--Returns the morse code corresponding to a string.
returns  varchar(255)
as
BEGIN
DECLARE @i int,@result varchar(255),@chars1 char(26),@chars2 char(10)
DECLARE @chars3 char(3), @morse1 char(104)
DECLARE @morse2 char(50),@morse3 char(18), @temp char(1)
SET @chars1='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
SET @chars2='0123456789'
SET @chars3='.,?'
SET @morse1='.-  -...-.-.-.. .   ..-.--. ......  .----.- .-..--  -.  --- .--.--.-.-. ... -   ..- ...-.-- -..--.----..'
SET @morse2='-----.----..---...--....-.....-....--...---..----.'
SET @morse3='.-.-.---..--..--..'
SET @result=''
SET @i=1
WHILE (@i<=LEN(@s))
BEGIN
SET @temp=UPPER(SUBSTRING(@s,@i,1))
IF CHARINDEX(@temp,@chars1)>0
	SET @result=@result+' '+SUBSTRING(@morse1,CHARINDEX(@temp,@chars1)*4-3,4)
IF CHARINDEX(@temp,@chars2)>0
	SET @result=@result+' '+SUBSTRING(@morse2,CHARINDEX(@temp,@chars2)*5-4,5)
IF CHARINDEX(@temp,@chars3)>0
	SET @result=@result+' '+SUBSTRING(@morse3,CHARINDEX(@temp,@chars3)*6-5,6)
SET @i=@i+1
END
WHILE CHARINDEX('  ',@result)>0
	SET @result=REPLACE(@result,'  ',' ')
RETURN @result
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function NAND(@a int, @b int ) 
--Returns the result of a logical negated AND.
returns int
as
BEGIN
return ~(@a & @b)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function NEXT_DAY( @d datetime, @n int ) 
returns datetime
as
BEGIN
declare @i int, @result datetime
IF (@n<1)OR (@n>7)
	SET @n=1
SET @i=2
SET @result=dateadd(d,1,@d)
WHILE DATEPART(dw,@result)<>@n
	BEGIN
	set @result=dateadd(d,1,@result)
	set @i=@i+1
	END
RETURN  @result
END

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function NINT(@a float ) 
--Rounds a number to the nearest integer.
returns int
as
BEGIN
return convert(int,round(@a,0))
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function NOR(@a int, @b int ) 
--Returns the result of a logical negated OR.
returns int
as
BEGIN
return ~(@a | @b)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function NROOT(@a float, @b float) 
--Returns the n root of a number.
returns float
as
BEGIN
return POWER(@a,1/@b)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function NTODEC(@s VARCHAR(255), @b int) 
--Converts a number on base n to decimal.
returns int
as
BEGIN
DECLARE @i int, @temp char(1), @result int
SELECT @i=1
SELECT @result=0
WHILE (@i<=LEN(@s))
BEGIN
SELECT @temp=UPPER(SUBSTRING(@s,@i,1))
IF (@temp>='0') AND (@temp<='9') 
	SELECT @result=@result+ (ASCII(@temp)-48)*POWER(@b,LEN(@s)-@i)
ELSE
	SELECT @result=@result+ (ASCII(@temp)-55)*POWER(@b,LEN(@s)-@i)
SELECT @i=@i+1
END
return @result
END





GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function NUMBERTOWORDS(@n bigint ) 
--Returns the number as words.
returns VARCHAR(255) 
as
BEGIN
DECLARE @i int, @temp char(1),  @s VARCHAR(20), @result VARCHAR(255)
SELECT @s=convert(varchar(20), @n)
SELECT @i=LEN(@s)
SELECT @result=''
WHILE (@i>0)
BEGIN
SELECT @temp=(SUBSTRING(@s,@i,1))
IF ((LEN(@s)-@i) % 3)=1
IF @temp='1'
SELECT @result=CASE (SUBSTRING(@s,@i+1,1))
	WHEN '0' THEN 'ten'
	WHEN '1' THEN 'eleven'
	WHEN '2' THEN 'twelve'
	WHEN '3' THEN 'thirteen'
	WHEN '4' THEN 'fourteen'
	WHEN '5' THEN 'fifteen'
	WHEN '6' THEN 'sixteen'
	WHEN '7' THEN 'seventeen'
	WHEN '8' THEN 'eighteen'
	WHEN '9' THEN 'nineteen'
	END+' '+CASE
			WHEN ((LEN(@s)-@i)=4) THEN 'thousand '
			WHEN ((LEN(@s)-@i)=7) THEN 'million '
			WHEN ((LEN(@s)-@i)=10) THEN 'billion '
			WHEN ((LEN(@s)-@i)=13) THEN 'trillion '
			WHEN ((LEN(@s)-@i)=16) THEN 'quadrillion '
			WHEN ((LEN(@s)-@i)=19) THEN 'quintillion '
			WHEN ((LEN(@s)-@i)=22) THEN 'sextillion '
			WHEN ((LEN(@s)-@i)=25) THEN 'septillion '
			WHEN ((LEN(@s)-@i)=28) THEN 'octillion '
			WHEN ((LEN(@s)-@i)=31) THEN 'nonillion '
			WHEN ((LEN(@s)-@i)=34) THEN 'decillion '
			WHEN ((LEN(@s)-@i)=37) THEN 'undecillion '
			WHEN ((LEN(@s)-@i)=40) THEN 'duodecillion '
			WHEN ((LEN(@s)-@i)=43) THEN 'tredecillion '
			WHEN ((LEN(@s)-@i)=46) THEN 'quattuordecillion '
			WHEN ((LEN(@s)-@i)=49) THEN 'quindecillion '
			WHEN ((LEN(@s)-@i)=52) THEN 'sexdecillion '
			WHEN ((LEN(@s)-@i)=55) THEN 'septendecillion '
			WHEN ((LEN(@s)-@i)=58) THEN 'octodecillion '
			WHEN ((LEN(@s)-@i)=61) THEN 'novemdecillion '
			ELSE ''
			END+@result
ELSE
BEGIN
	SELECT @result=CASE (SUBSTRING(@s,@i+1,1))
		WHEN '0' THEN ''
		WHEN '1' THEN 'one'
		WHEN '2' THEN 'two'
		WHEN '3' THEN 'three'
		WHEN '4' THEN 'four'
		WHEN '5' THEN 'five'
		WHEN '6' THEN 'six'
		WHEN '7' THEN 'seven'
		WHEN '8' THEN 'eight'
		WHEN '9' THEN 'nine'
		END+' '+ CASE
			WHEN ((LEN(@s)-@i)=4) THEN 'thousand '
			WHEN ((LEN(@s)-@i)=7) THEN 'million '
			WHEN ((LEN(@s)-@i)=10) THEN 'billion '
			WHEN ((LEN(@s)-@i)=13) THEN 'trillion '
			WHEN ((LEN(@s)-@i)=16) THEN 'quadrillion '
			WHEN ((LEN(@s)-@i)=19) THEN 'quintillion '
			WHEN ((LEN(@s)-@i)=22) THEN 'sextillion '
			WHEN ((LEN(@s)-@i)=25) THEN 'septillion '
			WHEN ((LEN(@s)-@i)=28) THEN 'octillion '
			WHEN ((LEN(@s)-@i)=31) THEN 'nonillion '
			WHEN ((LEN(@s)-@i)=34) THEN 'decillion '
			WHEN ((LEN(@s)-@i)=37) THEN 'undecillion '
			WHEN ((LEN(@s)-@i)=40) THEN 'duodecillion '
			WHEN ((LEN(@s)-@i)=43) THEN 'tredecillion '
			WHEN ((LEN(@s)-@i)=46) THEN 'quattuordecillion '
			WHEN ((LEN(@s)-@i)=49) THEN 'quindecillion '
			WHEN ((LEN(@s)-@i)=52) THEN 'sexdecillion '
			WHEN ((LEN(@s)-@i)=55) THEN 'septendecillion '
			WHEN ((LEN(@s)-@i)=58) THEN 'octodecillion '
			WHEN ((LEN(@s)-@i)=61) THEN 'novemdecillion '
			ELSE ''
			END+@result
	SELECT @result=CASE @temp
		WHEN '0' THEN ''
		WHEN '1' THEN 'ten'
		WHEN '2' THEN 'twenty'
		WHEN '3' THEN 'thirty'
		WHEN '4' THEN 'fourty'
		WHEN '5' THEN 'fifty'
		WHEN '6' THEN 'sixty'
		WHEN '7' THEN 'seventy'
		WHEN '8' THEN 'eighty'
		WHEN '9' THEN 'ninety'
		END+' '+@result
END
IF (((LEN(@s)-@i) % 3)=2) OR (((LEN(@s)-@i) % 3)=0) AND (@i=1)
BEGIN
SELECT @result=CASE @temp
	WHEN '0' THEN ''
	WHEN '1' THEN 'one'
	WHEN '2' THEN 'two'
	WHEN '3' THEN 'three'
	WHEN '4' THEN 'four'
	WHEN '5' THEN 'five'
	WHEN '6' THEN 'six'
	WHEN '7' THEN 'seven'
	WHEN '8' THEN 'eight'
	WHEN '9' THEN 'nine'
	END +' '+CASE
		WHEN (@s='0') THEN 'zero'
		WHEN (@temp<>'0')AND( ((LEN(@s)-@i) % 3)=2) THEN 'hundred '
		ELSE ''
		END + CASE
		WHEN ((LEN(@s)-@i)=3) THEN 'thousand '
		WHEN ((LEN(@s)-@i)=6) THEN 'million '
		WHEN ((LEN(@s)-@i)=9) THEN 'billion '
		WHEN ((LEN(@s)-@i)=12) THEN 'trillion '
		WHEN ((LEN(@s)-@i)=15) THEN 'quadrillion '
		WHEN ((LEN(@s)-@i)=18) THEN 'quintillion '
		WHEN ((LEN(@s)-@i)=21) THEN 'sextillion '
		WHEN ((LEN(@s)-@i)=24) THEN 'septillion '
		WHEN ((LEN(@s)-@i)=27) THEN 'octillion '
		WHEN ((LEN(@s)-@i)=30) THEN 'nonillion '
		WHEN ((LEN(@s)-@i)=33) THEN 'decillion '
		WHEN ((LEN(@s)-@i)=36) THEN 'undecillion '
		WHEN ((LEN(@s)-@i)=39) THEN 'duodecillion '
		WHEN ((LEN(@s)-@i)=42) THEN 'tredecillion '
		WHEN ((LEN(@s)-@i)=45) THEN 'quattuordecillion '
		WHEN ((LEN(@s)-@i)=48) THEN 'quindecillion '
		WHEN ((LEN(@s)-@i)=51) THEN 'sexdecillion '
		WHEN ((LEN(@s)-@i)=54) THEN 'septendecillion '
		WHEN ((LEN(@s)-@i)=57) THEN 'octodecillion '
		WHEN ((LEN(@s)-@i)=60) THEN 'novemdecillion '
		ELSE ''
			END+ @result
END
SELECT @i=@i-1
END
return REPLACE(@result,'  ',' ')
END











GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function OCTTODEC(@s VARCHAR(255) ) 
--Converts an octal number to decimal.
returns int
as
BEGIN
DECLARE @i int, @temp char(1), @result int
SELECT @i=1
SELECT @result=0
WHILE (@i<=LEN(@s))
BEGIN
SELECT @temp=SUBSTRING(@s,@i,1)
SELECT @result=@result+ (ASCII(@temp)-48)*POWER(8,LEN(@s)-@i)
SELECT @i=@i+1
END
return @result
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function PALINDROME(@n int ) 
--Returns true if the number is a palindrome.
returns bit
as
BEGIN
DECLARE @i int,@bool bit, @s varchar(20)
SET @s=convert(varchar(20),@n)
SET @i=1
SET @bool=1
WHILE (@i<=LEN(@s)/2)
BEGIN
IF SUBSTRING(@s,@i,1)<>SUBSTRING(@s,LEN(@s)-@i+1,1)
	SET @bool=0
SET @i=@i+1
END
RETURN @bool
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function PALINDROMEW( @s varchar(255) ) 
--Returns true if the string is a palindrome.
returns bit
as
BEGIN
DECLARE @i int,@bool bit
SET @i=1
SET @bool=1
WHILE (@i<=LEN(@s)/2)
BEGIN
IF SUBSTRING(@s,@i,1)<>SUBSTRING(@s,LEN(@s)-@i+1,1)
	SET @bool=0
SET @i=@i+1
END
RETURN @bool
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function PENTIUMBUG( ) 
returns bit
as
BEGIN
DECLARE @i float, @j float, @b bit
SET @i=4195835
SET @j=3145727
IF convert(varchar(255),(@i / @j))='1.33382'
	SET @b=0
ELSE
	SET @b=1
RETURN (@b)
END

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO


CREATE function PERFNUMBER(@n int ) 
--Returns the nth perfect number. 
returns bigint
as
BEGIN
RETURN POWER(2,@n-1)*(POWER(2,@n)-1)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function PHI() 
--Returns phi, the "golden ratio".
returns float
as
BEGIN
declare @temp float
select @temp=(1 + SQRT(5))/2 
return @temp
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function PROPERCASE(@s varchar(255)) 
--Returns a string with the first letter of each word at the beginning of a sentence  in uppercase, all other letters in lowercase
returns  varchar(255)
as
BEGIN
DECLARE @i int, @c char(1),@result varchar(255)
SET @result=LOWER(@s)
SET @i=2
SET @result=STUFF(@result,1,1,UPPER(SUBSTRING(@s,1,1)))
WHILE @i<=LEN(@s)
	BEGIN
	SET @c=SUBSTRING(@s,@i,1)
	IF (@c='!') OR (@c='?') OR (@c='_')OR (@c='.')
		IF @i<LEN(@s)
			BEGIN
lblSeek:
			SET @i=@i+1
			IF UPPER(SUBSTRING(@s,@i,1)) LIKE '[A-Z]'
				SET @result=STUFF(@result,@i,1,UPPER(SUBSTRING(@s,@i,1)))
			ELSE
				IF @i<LEN(@s)
					GOTO lblSeek
			END
	SET @i=@i+1
	END
RETURN  @result
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function RAD2GRAD(@a float ) 
--Converts an angle from radians to grads.
returns float
as
BEGIN
return (@a*PI()/200.0)
END

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function RESETBIT(@a int, @b int ) 
--Resets the value of a certain bit.
returns int
as
BEGIN
return @a | ~(POWER(2,@b))
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function REWRAP(@s varchar(255), @n int ) 
--Returns a string s wrapped in blocks of i characters, removing previous wrapping. 
returns varchar(255)
as
BEGIN
DECLARE @t VARCHAR(255), @i int
SET @i=1
SET @t=''
SET @s=REPLACE(@s,CHAR(10),'')
SET @s=REPLACE(@s,CHAR(13),'')
WHILE @i<=LEN(@s)
	BEGIN
	SET @t=@t+substring(@s,@i,1)
	IF (@i % @n)=0
		SET @t=@t+CHAR(13)
	SET @i=@i+1
	END
RETURN  @t
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function ROMAN2A(@s VARCHAR(20)) 
--Converts an roman numeral to arabic.
returns int
as
BEGIN
declare @f int, @k int, @z int, @z1 int
select @f=LEN(@s)
select @k=0
select @z1=0
WHILE (@f>0)
BEGIN
	select @z = CASE UPPER(SUBSTRING(@s,@f,1))
	WHEN 'I' THEN 1
	WHEN 'V' THEN 5
	WHEN 'X' THEN 10
	WHEN 'L' THEN 50
	WHEN 'C' THEN 100
	WHEN 'D' THEN 500
	WHEN 'M' THEN 1000
	END
IF @z1>@z
	SELECT @k=@k-@z
ELSE
	BEGIN
	SELECT @k=@k+@z
	SELECT @z1=@z
	END
select @f=@f-1
END
return @k
END







GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function RPAD(@s varchar(255), @n int, @p varchar(255) ) 
--Returns a string s1 right-padded to length i with a sequence of characters s2. 
returns varchar(255)
as
BEGIN
return @s+REPLICATE(@p,@n)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function SEC(@a float ) 
--Returns the trigonometric secant of the given angle (in radians) in the given expression.
returns float
as
BEGIN
return (1/COS(@a))
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function SECH(@a float ) 
--Returns the hyperbolic secant of a number.
returns float
as
BEGIN
return 2/( POWER(dbo.E(),@a) +  POWER(dbo.E(),-@a) )
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function SETBIT(@a int, @b int ) 
--Sets the value of a certain bit.
returns int
as
BEGIN
return @a | (POWER(2,@b))
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function SHIFTLEFT(@a int, @b int ) 
--Returns a number shifted to the left.
returns int
as
BEGIN
return @a * POWER(2, @b)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function SHIFTRIGHT(@a int, @b int ) 
--Returns a number shifted to the right.
returns int
as
BEGIN
return @a / POWER(2, @b)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function SINH(@a float ) 
--Returns the hyperbolic sine of a number.
returns float
as
BEGIN
return ( POWER(dbo.E(),@a) -  POWER(dbo.E(),-@a) )/2
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO


CREATE function SLOPE(@x1 float,@y1 float, @x2 float,@y2 float) 
--Returns the slope of a line define by 2 points P(f1, f2) and T(f3, f4). 
returns float
as
BEGIN
return (@y2-@y1)/(@x2-@x1)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function SQRTPI(@a float ) 
--Returns the square root of (number * Pi).
returns float
as
BEGIN
return SQRT(@a*PI())
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function STRIPL(@s varchar(255) ) 
--Returns the left side of half of the string. 
returns varchar(255)
as
BEGIN
return LEFT(@s, LEN(@s)/2)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function STRIPR(@s varchar(255) ) 
--Returns the right side of half of the string. 
returns varchar(255)
as
BEGIN
DECLARE @i int
SET @i=LEN(@s)-LEN(@s)/2
return RIGHT(@s, @i)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO


CREATE function SUMALIQUOT (@n bigint ) 
--Returns the sum of all aliquots from i
returns bigint
as
BEGIN
DECLARE @i bigint, @j bigint
SET @i=1
SET @j=0
WHILE @i<=@n/2
BEGIN
IF (@n % @i)=0
	SET @j=@j+@i
SET @i=@i+1
END
RETURN @j
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function SUMSEQ(@n bigint) 
--Returns the summation of all integers from 1 to n.
returns bigint
as
BEGIN
    return (@n+@n*@n)/2
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function TANH(@a float ) 
--Returns the hyperbolic tangent of a number.
returns float
as
BEGIN
return (dbo.SINH(@a)/dbo.COSH(@a))
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function TRANSLATE( @s varchar(255), @f varchar(255), @t varchar(255) ) 
returns varchar(255)
as
BEGIN
DECLARE @i int, @j int, @c char(1),@result varchar(255)
SET @i=1
SET @result=''
WHILE @i<=LEN(@s)
	BEGIN
	SET @c=SUBSTRING(@s,@i,1)
	SET @j=CHARINDEX(@c,@f)
	IF @j>0
		SET @result=@result + SUBSTRING(@t,@j,1)
	SET @i=@i+1
	END
RETURN @result
END

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function TRIM(@s VARCHAR(255) ) 
--Returns a string removing spaces at both ends.
returns  VARCHAR(255) 
as
BEGIN
return RTRIM(LTRIM(@s))
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function TRUNC(@a float ) 
--Returns a number truncated to an integer.
returns int
as
BEGIN
return convert(int,@a)
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function UNWRAP(@s varchar(255)) 
--Returns a string removing all wrapping. 
returns varchar(255)
as
BEGIN
SET @s=REPLACE(@s,CHAR(10),'')
SET @s=REPLACE(@s,CHAR(13),'')
RETURN @s
END




GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function VAL(@a VARCHAR(50) ) 
--Returns a numeric value from a string, it is the opposite of STR.
returns float
as
BEGIN
declare @temp float
if (ISNUMERIC(@a)=1)
	select @temp=convert(float,@a)
ELSE
	select @temp=0
return @temp
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function VALIDEMAIL(@s varchar(255)) 
--Returns true if the string is a valid email address.
returns bit
as
BEGIN
DECLARE @u VARCHAR(60), @v VARCHAR(60), @x VARCHAR(60), @i int, @j int, @result bit
SET @result=1
SET @i=CHARINDEX('@',@s)
SET @u=LEFT(@s,@i-1)
SET @j=dbo.CHARINDEXREV('.',@s)
SET @v=RIGHT(@s,LEN(@s)-@j)
SET @x=substring(@s,@i+1,@j-@i-1)
IF LEN(@x)<3
	BEGIN
	SET @result=0
	GOTo done
	END
IF (LEN(@x)=3) AND (@x NOT LIKE '[a-z,A-Z][a-z,A-Z][a-z,A-Z]')
	BEGIN
	SET @result=0
	GOTo done
	END
IF (LEN(@x)=2) AND (@x NOT LIKE '[a-z,A-Z][a-z,A-Z]')
	BEGIN
	SET @result=0
	GOTo done
	END
SET @i=1
WHILE (@i<LEN(@u))
	BEGIN
	IF SUBSTRING(@u,@i,1) NOT LIKE '[a-z,A-Z,0-9,_,-,.]'
		BEGIN
		SET @result=0
		GOTo done
		END
	SET @i=@i+1
	END
SET @i=1
WHILE (@i<LEN(@v))
	BEGIN
	IF SUBSTRING(@v,@i,1) NOT LIKE '[a-z,A-Z,0-9,_,-,.]'
		BEGIN
		SET @result=0
		GOTo done
		END
	SET @i=@i+1
	END
done:
return @result
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function VALIDIP(@s varchar(15)) 
--Returns true if the string is a IP.
returns bit
as
BEGIN
DECLARE @u VARCHAR(3), @v VARCHAR(3), @x VARCHAR(3),@y VARCHAR(3), @i int, @j int, @result bit
SET @result=1
IF dbo.INCLUDED('.',@s)<>3
	BEGIN
	SET @result=0
	GOTO done
	END
SET @i=CHARINDEX('.',@s)
SET @u=LEFT(@s,@i-1)
SET @j=CHARINDEX('.',@s,@i+1)
SET @v=substring(@s,@i+1,@j-@i-1)
SET @i=CHARINDEX('.',@s,@j+1)
SET @x=substring(@s,@j+1,@i-@j-1)
SET @y=substring(@s,@i+1,LEN(@s)-@i)
IF ISNUMERIC(@u)=0 OR ISNUMERIC(@v)=0 OR ISNUMERIC(@x)=0 OR ISNUMERIC(@y)=0
	BEGIN
	SET @result=0
	GOTo done
	END
IF (CONVERT(INT, @u)<0) OR  (CONVERT(INT, @v)<0) OR  (CONVERT(INT, @x)<0)  OR  (CONVERT(INT, @y)<0) 
	BEGIN
	SET @result=0
	GOTo done
	END
IF (CONVERT(INT, @u)>255) OR  (CONVERT(INT, @v)>255) OR  (CONVERT(INT, @x)>255)  OR  (CONVERT(INT, @y)>255) 
	BEGIN
	SET @result=0
	GOTo done
	END
done:
RETURN  @result
END




GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function VALIDZIP(@s varchar(5)) 
--Returns true if the string is a valid zip code.
returns bit
as
BEGIN
DECLARE @result bit
IF @s LIKE '[1-9][0-9][0-9][0-9][0-9]'
SET @s=1
ELSE
SET @s=0
return @result
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function VALIDZIP9(@s varchar(10)) 
--Returns true if the string is a valid zip code 5+4.
returns bit
as
BEGIN
DECLARE @result bit
IF @s LIKE '[1-9][0-9][0-9][0-9][0-9][-][0-9][0-9][0-9][0-9]'
SET @s=1
ELSE
SET @s=0
return @result
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function WORDCOUNT(@s varchar(255)) 
--Returns the number of words from string s. 
returns INT
as
BEGIN
DECLARE @i INT
SET @s=REPLACE(@s,CHAR(10),' ')
SET @s=REPLACE(@s,CHAR(13),' ')
SET @s=REPLACE(@s,'0','')
SET @s=REPLACE(@s,'1','')
SET @s=REPLACE(@s,'2','')
SET @s=REPLACE(@s,'3','')
SET @s=REPLACE(@s,'4','')
SET @s=REPLACE(@s,'5','')
SET @s=REPLACE(@s,'6','')
SET @s=REPLACE(@s,'7','')
SET @s=REPLACE(@s,'8','')
SET @s=REPLACE(@s,'9','')
SET @s=REPLACE(@s,'!',' ')
SET @s=REPLACE(@s,';',' ')
SET @s=REPLACE(@s,':',' ')
SET @s=REPLACE(@s,'[',' ')
SET @s=REPLACE(@s,']',' ')
SET @s=REPLACE(@s,'+',' ')
SET @s=REPLACE(@s,'{',' ')
SET @s=REPLACE(@s,'}',' ')
SET @s=REPLACE(@s,'&','')
SET @s=REPLACE(@s,'.',' ')
SET @s=REPLACE(@s,',',' ')
SET @s=REPLACE(@s,'?',' ')
SET @s=REPLACE(@s,'/',' ')
SET @s=REPLACE(@s,'_',' ')
SET @s=REPLACE(@s,'-','')
SET @s=REPLACE(@s,'(',' ')
SET @s=REPLACE(@s,')',' ')
SET @s=REPLACE(@s,'''','')
SET @s=REPLACE(@s,'"',' ')
WHILE CHARINDEX ('  ',@s)>0
	SET @s=REPLACE(@s,'  ',' ')
SET @s=RTRIM(LTRIM(@s))
SET @i=dbo.INCLUDED(' ',@s)+1
RETURN @i
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function WRAP(@s varchar(255), @n int ) 
--Returns a string s wrapped in blocks of i characters. 
returns varchar(255)
as
BEGIN
DECLARE @t VARCHAR(255), @i int
SET @i=1
SET @t=''
WHILE @i<=LEN(@s)
	BEGIN
	SET @t=@t+substring(@s,@i,1)
	IF (@i % @n)=0
		SET @t=@t+CHAR(13)
	SET @i=@i+1
	END
RETURN  @t
END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


CREATE function XORCHAR( @s VARCHAR(255), @x tinyint ) 
--Returns a string encrypted/decrypted with key t ( XOR encryption )
returns VARCHAR(255)
as
BEGIN
DECLARE @result VARCHAR(255), @i int, @temp tinyint
SET @i=1
SET @result=''
WHILE @i<=LEN(@s)
	BEGIN
	SET @temp=ASCII(SUBSTRING(@s,@i,1))
	SET @result=@result + CHAR(@temp ^ @x)
	SET @i=@i+1
	END
RETURN @result
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO



