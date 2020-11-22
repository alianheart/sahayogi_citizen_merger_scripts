Use FINMIG
go;

CREATE FUNCTION [F_IsValidEmail] (
 @EmailAddr varchar(360) -- Email address to check
)   RETURNS BIT -- 1 if @EmailAddr is a valid email address

AS BEGIN
 
       
-- Check basic conditions
IF @EmailAddr IS NULL 
   OR @EmailAddr NOT LIKE '[0-9a-zA-Z]%@__%.__%' 
   OR @EmailAddr LIKE '%@%@%' 
   OR @EmailAddr LIKE '%..%' 
   OR @EmailAddr LIKE '%.@' 
   OR @EmailAddr LIKE '%@.' 
   OR @EmailAddr LIKE '%@%.-%' 
   OR @EmailAddr LIKE '%@%-.%' 
   OR @EmailAddr LIKE '%@-%' 
   OR CHARINDEX(' ',LTRIM(RTRIM(@EmailAddr))) > 0
       RETURN(0)



declare @AfterLastDot varchar(360);
declare @AfterArobase varchar(360);
declare @BeforeArobase varchar(360);
declare @HasDomainTooLong bit=0;

--len after .
set @AfterLastDot=REVERSE(SUBSTRING(REVERSE(@EmailAddr),0,CHARINDEX('.',REVERSE(@EmailAddr))));
if  len(@AfterLastDot) not between 2 and 17
RETURN(0);

--len after @
set @AfterArobase=REVERSE(SUBSTRING(REVERSE(@EmailAddr),0,CHARINDEX('@',REVERSE(@EmailAddr))));
if len(@AfterArobase) not between 2 and 255
RETURN(0);

return(1);
END