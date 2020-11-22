USE FINMIG

Drop table CIFINFO
Go
drop table #Temp
go
drop sequence new_cif
go
create sequence new_cif
as int
Start with 01258950 --maximum cif id from finacle +1
INCREMENT by 1
go 

select ClientCode, 
next value for new_cif  over (order by ClientCode) AS [ClientCode_New], 
CustomerType= case when FinacleClientCategory='Retail' then 'Retail' 
					when (isnull(FinacleClientCategory,'')='' and ClientCategory like 'Individ%') Then 'Retail' else 'Corporate' end,
			 DateOfBirth, Null as 'DOB_AD'
into #Temp
from PPIVKanchanDBL..ClientTable
where ClientCode in (select ClientCode from PPIVKanchanDBL..Master where AcTypeType='C' and IsBlocked<>'C') 
 order by ClientCode
go
select ClientCode ,
ClientCode_New=N'0'+cast(ClientCode_New as nvarchar(8)),
Case when CustomerType='Retail' then N'R'+'0'+cast(ClientCode_New as nvarchar(8))
else N'C'+'0'+cast(ClientCode_New as nvarchar(8)) end as CIFID,
CustomerType,DateOfBirth , 

CASE WHEN  DateOfBirth > (select Today from PPIVKanchanDBL..ControlTable) THEN 
PPIVKanchanDBL.dbo.f_GetRomanDate(DatePart(Day,DateOfBirth),DatePart(MONTH,DateOfBirth),DatePart(YEAR,DateOfBirth))

WHEN CustomerType ='Retail' and ISNULL (DateOfBirth,'') = '' THEN  cast('01-Jan-1900' as date)

ELSE DateOfBirth  END as DOB_AD   
into CIFINFO
from #Temp 
order by 1


--select * from CIFINFO  order by 1--00000061
/*

(139925 row(s) affected)
(140154 rows affected)
*/