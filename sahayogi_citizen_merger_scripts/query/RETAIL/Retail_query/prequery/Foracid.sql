USE PPIVKanchanDBL

IF OBJECT_ID('tempdb.dbo.#foracid','U') IS NOT NULL
DROP TABLE #foracid;

select * into #foracid from(

SELECT 
              M.ClientCode
			  ,t.ClientCode_New
              ,t.CIFID
              ,M.AcType
              ,M.BranchCode P_BranchCode
			  ,cast(bm.F_SolID as varchar) BranchCode
              ,M.Obligor
              ,AcOpenDate
              ,M.MainCode
              ,ReferenceNo			 
              ,M.CyCode
              ,IsBlocked
              ,M.AcOfficer
              ,IsDormant
			  ,left( replace(checksum(M.MainCode),'-',''),1) ChkSum
FROM Master M with (NOLOCK) 
left join DealTable d on d.MainCode = M.MainCode and d.BranchCode = M.BranchCode
join FINMIG.dbo.CIFINFO t with (NOLOCK) on M.ClientCode=t.ClientCode 
join FINMIG.dbo.BranchMapping bm on  bm.P_BranchCode=M.BranchCode
WHERE
LEFT(t.ClientCode,1) <> '_'
and M.IsBlocked not in ('C','o')

)x

---------------------Foracid------------------

SELECT		  
			ClientCode
			,ClientCode_New
			  ,CIFID
              ,AcType
              ,P_BranchCode
			  ,BranchCode
              ,Obligor
              ,AcOpenDate
              ,MainCode
              ,ReferenceNo			 
			  ,BranchCode+ClientCode_New +  Right('0000'+ cast(SerialNumber as nvarchar) ,4)+ ChkSum Foracid
              ,CyCode
              ,IsBlocked
              ,AcOfficer
              ,IsDormant INTO FINMIG.dbo.ForAcid 
    FROM (
   		SELECT 
              ClientCode
			  ,ClientCode_New
              ,CIFID
              ,AcType
              ,P_BranchCode
			  ,BranchCode
              ,Obligor
              ,AcOpenDate
              ,MainCode
              ,ReferenceNo			 
              ,CyCode
              ,IsBlocked
              ,AcOfficer
              ,IsDormant
			  ,ROW_NUMBER() OVER( PARTITION BY ClientCode ORDER BY AcOpenDate,MainCode) AS SerialNumber			   
			  ,ChkSum
FROM #foracid 
)x

/*
(157628 row(s) affected)

(158119 row(s) affected)

(158194 row(s) affected)

(155554 rows affected)
*/
--select Foracid,count(Foracid) from FINMIG..ForAcid group by Foracid having count(Foracid)<>1

--select * from FINMIG..ForAcid