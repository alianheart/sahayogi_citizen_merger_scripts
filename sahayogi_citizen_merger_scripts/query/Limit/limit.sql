Declare @MigDate date, @v_MigDate nvarchar(15)
select  @MigDate=Today from ControlTable;
set @v_MigDate=REPLACE(CONVERT(VARCHAR,@MigDate,106), ' ','-')

select 
LimitPrefix pumori,
cif_id as LimitPrefix,
LimitSuffix,
rtrim(left(Limit_Desc,25)) Limit_Desc,
'NPR' Currency,
Limit_Type,
--Limit_Type_Id,
APPROVAL_LIMIT, 
Drawing_Power_Ind,
DRAWING_POWER,
--REPLACE(CONVERT(VARCHAR,SanctionDate,106), ' ','-'), 

REPLACE(CONVERT(VARCHAR,Sanction_Date,106), ' ','-') as SanctionDate,

--REPLACE(CONVERT(VARCHAR,ExpiryDate,106), ' ','-') as ExpiryDate,
--REPLACE(CONVERT(VARCHAR,@v_MigDate,106), ' ','-')  as SanctionDate,

REPLACE(CONVERT(VARCHAR,Expiry_Date,106), ' ','-') as ExpiryDate,

--REPLACE(CONVERT(VARCHAR,(select Today+365 from ControlTable),106), ' ','-') ExpiryDate


Master_Limit_Node,
'' Cust_ID
,case when Loan_Type = 'REVOLVING' then 'N'
else 'Y' end as LC_SINGLE_TRAN_FLG
from FINMIG.dbo.Limit_Node a join FINMIG..GEN_CIFID b on a.LimitPrefix = b.ClientCode
--where isnull(Sanction_Date, '') <> ''
