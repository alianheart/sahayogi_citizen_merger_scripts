--/wasapp/SIGN_UPLOAD/signatures/IMAGE/ImageD/Images/SAHAYOGI_IMAGES/Images
--SVS_001
use PPIVSahayogiVBL
Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate =(select Today from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','')

select 
--'Z' AS INDI, --FOR SOLWISE DATA SEPERATION PURPOSE 
ForAcid AS AccId,
' ' CustId,
' ' AS EmpId,
'NORM' as Imgaccesscode,
' ' as SignpowerNo,
' ' as Keyword,
--left(imt.MainCode,3) as SolId,
s.F_SolId as SolId,
'31-12-2099' As SignExpiryDate,
CONVERT(VARCHAR(10),@MigDate,105) As SignEffectiveDate,
'/wasapp/SIGN_UPLOAD/signatures/IMAGE/ImageD/Images/SAHAYOGI/'+imt.BranchCode+'/'+ltrim(rtrim(imt.MainCode))+''+rtrim(ltrim(cast(SeqNo as varchar)))+'.jpeg' as SignFile,-- ac+seqno+.jpeg
'31-12-2099'  as PhotoExpityDate,
' ' as PhotoEffectiveDate,
' ' as Photo,
--replace(REPLACE(replace((isnull(imt.Name,' ') +'-' +isnull(imt.Remarks,' ')),'&','and'),',',' ') ,'\n', '_') as CustName,
replace(replace(case when isnull(imt.Name,'')<>'' and isnull(imt.Remarks,' ')<>'' then
		left(REPLACE(replace((isnull(imt.Name,' ') +' ' +isnull(imt.Remarks,' ')),'&','and'),',',' '),100) 
	else isnull(left(replace(replace(replace(replace(M.Name,'&','and'),',',' '),';', ' '),':', ' '),100),' ') end,';',' '),':',' ') as CustName,
' ' as  SignGrpId,
'N' AS AccType,
--'2001' as BankCode, /*Reason    : Failed to insert record because BankCode not given with EmpId or SignPowerNo*/
' ' as BankCode,
--'01' as BankCode,
--Replace(Replace(cast(st.SignRemark as varchar),'"',''),',',' ') AS Remarks
LEFT(isnull(replace(replace(replace(REPLACE(replace(REPLACE(REPLACE(Replace(Replace(cast(st.SignRemark as nvarchar(max)),'"',''),',',' '), CHAR(13), ''), CHAR(10), ''),'\','/'),',',' '),'&','and'),';',' '), ':', ' '),'MIGRATION'),199) AS Remarks
--isnull(replace(cast(st.SignRemark as varchar),'\','/'),'') AS Remarks
from ImageTable imt
join FINMIG..SolMap s on imt.BranchCode = s.BranchCode
 JOIN (select ForAcid,MainCode from FINMIG.dbo.ForAcidSBA UNION ALL select ForAcid,MainCode from FINMIG.dbo.ForAcidOD)t1
 ON t1.MainCode = imt.MainCode
join Master M on M.MainCode =imt.MainCode
 left join SignTable st on st.MainCode = imt.MainCode
 where 1=1 
 --and t1.ForAcid not in (select ForAcid from FINMIG..SVS_ForAcid)
 and upper(imt.IsApproved)='T'
 order by SolId
 
--PhotoExpityDate changed to 31-12-2099
 --189,880 sign 2nd mig