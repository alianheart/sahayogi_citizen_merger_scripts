use PPIVSahayogiVBL;

DECLARE @MigDate DATE, @v_MigDate nvarchar(15);

set @MigDate = (select Today from ControlTable);
set @v_MigDate=REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-');



IF OBJECT_ID('tempdb.dbo.#Loan', 'U') IS NOT NULL
  DROP TABLE #Loan;

select * into #Loan from (
select  distinct ForAcid,t1.MainCode
from FINMIG..TotalLoan t1 join FINMIG..ForAcidLAA t2
on t1.MainCode=t2.MainCode
where isnull(Deal_MainCode,'')=''
union all
select  distinct ForAcid as ForAcid,t1.Deal_MainCode as MainCode
from FINMIG..TotalLoan t1 join FINMIG..ForAcidLAA t2
on t1.MainCode=t2.MainCode
where isnull(Deal_MainCode,'')<>''

)x
order by MainCode

select distinct
'SRM' Record_Indicator
,mt.ReferenceNo
,ForAcid Account_Number
--,mt.MortgageCode as MortgageCode
,'NPR' Currency_Code
,'MIG' Security_Code
,'MIG' Security_Group_Code
,'' Security_Class_Code
,'P' Primary_Collateral
,'N' Penal_interest_applicable
,'' Lien_Account_ID
,'' Certificate_alpha
,'' Certificate_Number
,CASE when isnull(mt.MortgageValue,'')<>'' then 
		RIGHT(SPACE(17)+CAST(isnull(round(abs(mt.MortgageValue),2),'') AS VARCHAR(17)),17)
	 else case when isnull(round(M.Limit,2),'')<>'' then 
		RIGHT(SPACE(17)+CAST(isnull(ABS(M.Limit),'') AS VARCHAR(17)),17)
			else case when isnull(round(M.IntDrAmt,2),'')<>'' then 	
		RIGHT(SPACE(17)+CAST(isnull(round(ABS(M.IntDrAmt),2),'') AS VARCHAR(17)),17) 
			else RIGHT(SPACE(17)+CAST('1.00' AS VARCHAR(17)),17)  end
		end 
end  as  Unit_Value
,'1' Number_of_Units
,CASE when isnull(mt.MortgageValue,'')<>'' then 
		RIGHT(SPACE(17)+CAST(isnull(round(abs(mt.MortgageValue),2),'') AS VARCHAR(17)),17)
	 else case when isnull(round(M.Limit,2),'')<>'' then 
		RIGHT(SPACE(17)+CAST(isnull(ABS(M.Limit),'') AS VARCHAR(17)),17)
			else case when isnull(round(M.IntDrAmt,2),'')<>'' then 	
		RIGHT(SPACE(17)+CAST(isnull(round(ABS(M.IntDrAmt),2),'') AS VARCHAR(17)),17) 
			else RIGHT(SPACE(17)+CAST('1.00' AS VARCHAR(17)),17)  end
		end 
end as  Security_value
,CASE when isnull(mt.MortgageValue,'')<>'' then 
		RIGHT(SPACE(17)+CAST(isnull(round(abs(mt.MortgageValue),2),'') AS VARCHAR(17)),17)
	 else case when isnull(round(M.Limit,2),'')<>'' then 
		RIGHT(SPACE(17)+CAST(isnull(ABS(M.Limit),'') AS VARCHAR(17)),17)
			else case when isnull(round(M.IntDrAmt,2),'')<>'' then 	
		RIGHT(SPACE(17)+CAST(isnull(round(ABS(M.IntDrAmt),2),'') AS VARCHAR(17)),17) 
			else RIGHT(SPACE(17)+CAST('1.00' AS VARCHAR(17)),17)  end
		end 
end  as Maximum_Ceiling_Limit
,'' Margin_Percent
,'Q' Item_Frequency_Type
,'1' Item_Frequency_Week_Number
,'1' Item_Frequency_Week_Day
,'' Item_Frequency_Start_Date
,'N' Item_Frequency_Holiday_Status
,'' Item_Due_Date
,'' Item_Renew_Received_Date
--,case when isnull(mc.Remarks,'')='' then 'Migration' else
--	replace(mc.Remarks,'"','') end as Remarks
,CASE WHEN ISNULL(InsPolicyNo,'')<>'' AND InsPolicyNo<>'-' THEN RIGHT(InsPolicyNo,15)
	ELSE 'MIG' END AS  Remarks
,'' Debit_Account_for_Fees
,'' Derived_value_indicator
,'' Third_party_lien_amount
,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17)  Assessed_Value
,'' Invoice_Value
,'' Market_Value
,'' Written_Down_Value
,CASE when isnull(mt.MortgageValue,'')<>'' then 
		RIGHT(SPACE(17)+CAST(isnull(round(abs(mt.MortgageValue),2),'') AS VARCHAR(17)),17)
	 else case when isnull(round(M.Limit,2),'')<>'' then 
		RIGHT(SPACE(17)+CAST(isnull(ABS(M.Limit),'') AS VARCHAR(17)),17)
			else case when isnull(round(M.IntDrAmt,2),'')<>'' then 	
		RIGHT(SPACE(17)+CAST(isnull(round(ABS(M.IntDrAmt),2),'') AS VARCHAR(17)),17) 
			else RIGHT(SPACE(17)+CAST('1.00' AS VARCHAR(17)),17)  end
		end 
end  as Apportioned_Value
,'' Purchase_Date
,'' Year_of_Creation
,case when LatestValDate< @MigDate then @v_MigDate
	else isnull(REPLACE(CONVERT(VARCHAR,LatestValDate,105), ' ','-'),@v_MigDate)
	end as  Review_Date
,'' Net_Value_Remarks_1
,'' Net_Value_Remarks_2
,'' Net_Value_Remarks_3
,'' Net_Value_Remarks_4
,'' Net_Value_Amount_1
,'' Net_Value_Amount_2
,'' Net_Value_Amount_3
,'' Net_Value_Amount_4
,'' Net_Value_Operand_1
,'' Net_Value_Operand_2
,'' Net_Value_Operand_3
,'' Net_Value_Operand_4
,'' Full_Benefit_Flag
,case when InsIssueDate>@MigDate then @v_MigDate
		when InsIssueDate ='1899-12-30' then @v_MigDate
else isnull(REPLACE(CONVERT(VARCHAR,InsIssueDate,105), ' ','-'),@v_MigDate) end as Lodge_Date
,'' Gross_Value
,cif_id Customer_ID
,'' Last_Valuation_Date
,'' Sequence_Number
,'' Security_From_Serial_Number
,'' Security_To_Serial_Number
,'' Vehicle_Chassis_Number
,'' Vehicle_Registration_Number
,'' Vehicle_Engine_Number
,'' Property_Document_Number
,'' as Property_Address_1
,'' Property_Address_2
,'' Property_City
,'' Property_State
,'' Property_Pin_Code
,'' Guarantor_ID
,'' Guarantee_Type
--,CASE WHEN ISNULL(InsPolicyNo,'')<>'' AND InsPolicyNo<>'-' THEN RIGHT(InsPolicyNo,15)
--	ELSE 'MIG' END AS  Life_Insurance_Policy_Number
,'' Life_Insurance_Policy_Number
--,RIGHT(SPACE(17)+CAST(isnull(round(isnull(InsuredAmt,''),2),'') AS VARCHAR(17)),17) Life_Insurance_Policy_Amount
,'' Life_Insurance_Policy_Amount
from FINMIG.dbo.collateral mt 
join (select MainCode,ForAcid from #Loan union all select MainCode,ForAcid from FINMIG..ForAcidOD
union all select MainCode,ForAcid from FINMIG..ForAcidSBA) fl
on fl.MainCode = mt.ReferenceNo
join MortgageCode mc 
on mt.MortgageCode = mc.MortgageCode 
JOIN Master M
on M.MainCode = mt.ReferenceNo
join FINMIG..GEN_CIFID cm
on M.ClientCode = cm.ClientCode
where ForAcid is not null

--and (round(abs(mt.MortgageValue),2)>0 or round(abs(M.Limit),2)>0 or round(IntDrAmt,2)<>0 )
--and (isnull(InsuredAmt,0)<>0)
--and M.MainCode='0010000091MD'

order by 2
/*
 select MainCode,AcType,Balance,IntDrAmt,Name,BranchCode,CyCode  from Master where MainCode in (SELECT ReferenceNo FROM  FINMIG.dbo.collateral mt 
where ReferenceNo not in  (select MainCode from #Loan union all select MainCode from FINMIG..ForAcidOD
union all select MainCode from FINMIG..ForAcidSBA))

--8437 rows 

select * from FINMIG.dbo.collateral where ReferenceNo='0010000090PB' 
select * from MortgageCode where MortgageCode='C2263222'


select MainCode,count(*) from #Loan 
group by MainCode
having count(MainCode)>=2
*/