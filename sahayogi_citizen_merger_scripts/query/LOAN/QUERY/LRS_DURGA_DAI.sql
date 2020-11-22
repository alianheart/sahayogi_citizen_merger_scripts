/*USE [FINMIG]
GO
Alter PROCEDURE RL003_SCH
 As
 */

Declare @ForAcid	varchar(20) ,	@BranchCode	varchar(20), @CyDesc	varchar(20), @MainCode	varchar(20), @AcType	varchar(20) , @LoanType varchar(20),
  @MigDate date, @v_MigDate nvarchar(15), @IntCalTillDate date, @flow_start_date date, @num_of_flows int, @RepayFreq varchar(3), @L_LoanType varchar(20)
  ,@v_RepayFreq varchar(3), @Serno numeric, @flow_amt money, 	  @ERROR_MESSAGE nvarchar(100),@HasRepaySched nvarchar(3), @v_count numeric=0, @v_RepayFreq_Pri nvarchar(3)
  ,@Next_Month_End date, @Next_Quarter_End date, @Next_HalfYear_End date, @Next_Year_End date;
Begin


	select  @MigDate=Today ,@IntCalTillDate=LastDay   from  PPIVSahayogiVBL.dbo.ControlTable;

set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','') 

declare @LA_SCH table(
foracid	varchar(16) not null,
flow_id	varchar(5) not null,
flow_start_date date not null,
lr_freq_type	Char(1) not null,
lr_freq_week_num Char(1),
lr_freq_week_day numeric(1),
lr_freq_start_dd numeric(2),
lr_freq_months Numeric(4),
lr_freq_days numeric(3),
lr_freq_hldy_stat char(1),
num_of_flows Numeric(3) not null,
flow_amt money not null,
instlmnt_pcnt	Numeric(8),
num_of_dmds	 Numeric(3),
next_dmd_date	date,
next_int_dmd_date	date,
lr_int_freq_type	Char(1),
lr_int_freq_week_num	 Char(1),
lr_int_freq_week_day  Numeric(1),
lr_int_freq_start_dd Numeric(2),
lr_int_freq_months	Numeric(4),
lr_int_freq_days	 Numeric(3),
lr_int_freq_hldy_stat	Char(1),
instlmnt_ind	Char(1)
);



DECLARE RL003 CURSOR FOR   
select fla.ForAcid,fla.BranchCode,fla.CyDesc,fla.MainCode,fla.AcType, fla.LoanType,RepayFreq , T_LoanType, HasRepaySched
from FINMIG.dbo.ForAcidLAA fla  
where 1=1
--and  fla.BranchCode between '001' and '064' --and (round(abs(Balance+IntDrAmt_IntAccrued),2))>0;
--and MainCode in ('0060000181HL','0010000057HL')

OPEN RL003  

FETCH NEXT FROM RL003   
INTO @ForAcid	, @BranchCode	, @CyDesc	, @MainCode	, @AcType	,@LoanType ,@RepayFreq , @L_LoanType,@HasRepaySched

WHILE @@FETCH_STATUS = 0  
BEGIN  
set @v_count=@v_count+1

 print (cast(@v_count as varchar) +  ' - '  +@MainCode + ' Time : ' + cast(getdate() as nvarchar))

  --Do remaining Frequerncy conversion here..
	set @v_RepayFreq=(select 
							case 
							 --when @RepayFreq='1' then 'D'
							 when @RepayFreq='5' then 'Q'
							 when @RepayFreq='6' then 'H'
							 when @RepayFreq='7' then 'Y'
							else 'M'
					 end);
 
	 				 
	set @Next_Month_End    = (select NextMonthEnd from FINMIG.dbo.NextIntRunDate);
	set @Next_Quarter_End  = (select NextQtrEnd from FINMIG.dbo.NextIntRunDate);
	set @Next_HalfYear_End = (select NextHalfYearEnd from FINMIG.dbo.NextIntRunDate);
	set @Next_Year_End 	   = (select NextYeaerEnd from FINMIG.dbo.NextIntRunDate);

	
	if @L_LoanType='LOAN' and  not exists (select   1 from PPIVSahayogiVBL.dbo.LoanRepaySched where MainCode=@MainCode and DueDate>=@MigDate)
	--Loan WIthout schedule
 			begin
					begin try
					select @flow_amt=Abs(m.Balance) ,@flow_start_date= case when  m.LimitExpiryDate < m.AcOpenDate then  m.AcOpenDate else m.LimitExpiryDate  end   from PPIVSahayogiVBL.dbo.Master m  where MainCode=@MainCode
		 /*
					insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  ,flow_amt  
											,next_dmd_date ,next_int_dmd_date ,lr_int_freq_type	 
												,lr_int_freq_days	 ,lr_int_freq_hldy_stat ) values 
											(@ForAcid,'PRDEM',@flow_start_date,@v_RepayFreq ,1,@flow_amt
											,@flow_start_date,@flow_start_date, @v_RepayFreq
												, DatePart(Day,@flow_start_date),'P' );

					insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  ,flow_amt  
											,next_dmd_date ,next_int_dmd_date ,lr_int_freq_type	 
												,lr_int_freq_days	 ,lr_int_freq_hldy_stat ) values 
											(@ForAcid,'PIDEM',@flow_start_date,@v_RepayFreq ,1,0
											,@flow_start_date,@flow_start_date, @v_RepayFreq
												, DatePart(Day,@flow_start_date),'P' );
*/
					if @LoanType = 'EMI'  --EMI without schedule 
					begin 
					insert into @LA_SCH(foracid	 ,flow_id	
											,flow_start_date,lr_freq_type  , num_of_flows  
											,flow_amt  
											,next_dmd_date 
											,next_int_dmd_date 
											,lr_int_freq_type	 
												,lr_int_freq_days	 ,lr_int_freq_hldy_stat ) values 
											(@ForAcid, 'EIDEM'
											,@flow_start_date,@v_RepayFreq ,1
											,@flow_amt		/* Need to confirm EMI Amt for schedule issue loan*/
											,@MigDate 	--cast('30-DEC-2099' as date)		--,@flow_start_date   -- For Expire Loan As dicussed Jun 5th
											,@MigDate			---@flow_start_date  
											,@v_RepayFreq
											, DatePart(Day,@flow_start_date),'P' );
					END	
						
				if @LoanType = 'NONEMI'		
				begin		
					if @flow_start_date<@MigDate		
					/*---for expired NEMI loan to generate only INDEM at first but error in uploading so generate PRDEM and sending '0.01' in flow_amt  */
					BEGIN
						insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  
											,flow_amt  
											,next_dmd_date 
											,next_int_dmd_date 
											,lr_int_freq_type	 
												,lr_int_freq_days	 
												,lr_int_freq_hldy_stat ) values 
												(@ForAcid, 'PRDEM',@flow_start_date,@v_RepayFreq ,1
											,0.01			--@flow_amt
											,cast('30-DEC-2099' as date)		--,@flow_start_date   -- For Expire Loan As dicussed Jun 5th
											,NULL		-- For Expire Loan As dicussed Jun 5th
											,NULL		--@v_RepayFreq		-- Interest freq dtls should not be entered for Principal / Int installments
											, DatePart(Day,@flow_start_date),'P' );

						insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  
											,flow_amt  
											,next_dmd_date 
											,next_int_dmd_date ,lr_int_freq_type	 
											,lr_int_freq_days	 ,lr_int_freq_hldy_stat ) values 
											(@ForAcid,'INDEM' ,@flow_start_date,@v_RepayFreq ,0--1
											,0
											,cast('30-DEC-2099' as date)		--,@flow_start_date		-- For Expire Loan As dicussed Jun 5th
											,NULL				--@flow_start_date		-- For Expire Loan As dicussed Jun 5th		
											, NULL --@v_RepayFreq		-- Interest freq dtls should not be entered for Principal / Int installments
											, DatePart(Day,@flow_start_date),'P' );
					end
					ELSE
						Begin
					---for not expired loan and to send the PRDEM for NEMI loan and Not Sch in Pumori
					-- But in INDEM to generate as it is in pumori
			
							insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  ,flow_amt  
												,next_dmd_date ,next_int_dmd_date ,lr_int_freq_type	 
													,lr_int_freq_days	 ,lr_int_freq_hldy_stat ) values 
												(@ForAcid, 'PRDEM',@flow_start_date,@v_RepayFreq ,1,@flow_amt
												,@flow_start_date,@flow_start_date, @v_RepayFreq
													, DatePart(Day,@flow_start_date),'P' );
						
/*	commented as per Roman dai suggested to send prdem and indem same as expiry date 2018-10-08

						set @flow_start_date = (select case 
															when @RepayFreq='5' then @Next_Quarter_End
															when @RepayFreq = '6' then @Next_HalfYear_End
															when @RepayFreq = '7' then @Next_Year_End
															else @Next_Month_End
												   end);
*/
							insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  
												,flow_amt  
												,next_dmd_date ,next_int_dmd_date ,lr_int_freq_type	 
													,lr_int_freq_days	 ,lr_int_freq_hldy_stat ) values 
												(@ForAcid,'INDEM' ,@flow_start_date,@v_RepayFreq ,0--1
												,0
												,@flow_start_date,@flow_start_date, @v_RepayFreq
													, DatePart(Day,@flow_start_date),'P' );
						end
						
					end


					End try
		
					begin catch
		
						set @ERROR_MESSAGE=(sELECT ERROR_MESSAGE());				 
						print (@ERROR_MESSAGE + ' SEC:4 ' + @MainCode );
					end catch
				end;




	SELECT @flow_start_date=  MIN(lrs.DueDate)  ,@num_of_flows= COUNT(*) , @Serno=min(lrs.Serno) 
	FROM  PPIVSahayogiVBL.dbo.LoanRepaySched lrs  join PPIVSahayogiVBL.dbo.Master m on lrs.MainCode=m.MainCode
	and lrs.BranchCode=m.BranchCode
	and  DueDate>= @MigDate
	and lrs.MainCode=@MainCode

	--Print ('HERE 1')
	Declare @RepayStartDate date , @GracePeriod int, @EMI_StartDate date,@New_flow_start_date date;
	 

	if  @LoanType= 'EMI' and @L_LoanType='LOAN' and  exists (select   1 from PPIVSahayogiVBL.dbo.LoanRepaySched where MainCode=@MainCode and DueDate>=@MigDate)
		begin-- For EMI Schedule Details
			Begin try
			--Print ('HERE 1.1')
			select  @RepayStartDate=m.RepayStartDate , @GracePeriod=isnull(m.GracePeriod,0) 
			from PPIVSahayogiVBL.dbo.LoanMaster m where MainCode=@MainCode
			set @EMI_StartDate= DATEADD(Month,@GracePeriod,@RepayStartDate);
			

		/*  EMI within Grace Period  */
			if @EMI_StartDate > @MigDate  and @GracePeriod>1  		 
				Begin
			
				Print (cast(@EMI_StartDate as nvarchar) + 'HERE 1.1.1')
					
					select   @New_flow_start_date=  MIN(sh.DueDate)  ,@num_of_flows= COUNT(*) 
					from PPIVSahayogiVBL.dbo.LoanRepaySched sh where MainCode=@MainCode 
					and DueDate > =   @MigDate and DueDate <= @EMI_StartDate
					
					print (cast(@New_flow_start_date as nvarchar)+'test')
					/*  NON EMI GRACE for to Define Single INDEM with Num_of_Flows as Actual count */
					
					insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  ,flow_amt  
													,next_dmd_date ,next_int_dmd_date ,lr_int_freq_type	 
														,lr_int_freq_days	 ,lr_int_freq_hldy_stat ) values 
													(@ForAcid,'INDEM' ,@New_flow_start_date,@v_RepayFreq ,@num_of_flows,0
													,@New_flow_start_date,@New_flow_start_date, @v_RepayFreq
														, DatePart(Day,@New_flow_start_date),'P' );
				
				/*
					insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  ,flow_amt  
								,next_dmd_date ) 
				
				select  @ForAcid,  'INDEM' flow_id,DueDate, @v_RepayFreq ,count(1)  , 0 FlowAmt,  
								DueDate	  from PPIVSahayogiVBL.dbo.LoanRepaySched l 
								where  l.MainCode =@MainCode   
								and DueDate >=    @MigDate and DueDate < @EMI_StartDate
								GROUP BY DueDate
						*/
					select   @New_flow_start_date=  MIN(sh.DueDate)  ,@num_of_flows= COUNT(*) 
					from PPIVSahayogiVBL.dbo.LoanRepaySched sh where MainCode=@MainCode 
					and DueDate >= @EMI_StartDate
						
				
				set @flow_amt = (select isnull(TotPayment,0) from PPIVSahayogiVBL.dbo.LoanRepaySched l 
				where l.MainCode =@MainCode and cast(l.DueDate  as Date)= @New_flow_start_date --and l.Serno=@Serno
				);

				print ( @MainCode + ' EMI - GRACE '+ cast(@flow_start_date as nvarchar) );

					insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  ,flow_amt  
					,next_dmd_date ,next_int_dmd_date ,lr_int_freq_type	 
					,lr_int_freq_days	 ,lr_int_freq_hldy_stat ) values 
					(@ForAcid,'EIDEM',@New_flow_start_date,@v_RepayFreq ,@num_of_flows,@flow_amt
					,@New_flow_start_date,@New_flow_start_date, @v_RepayFreq
					, DatePart(Day,@New_flow_start_date),'P' );


				end

			Else
			
				Begin  
			/*  EMI- without Grace Or Over  */
			
				Print ('HERE 1.1.2')
				set @flow_amt = (select isnull(TotPayment,0) from PPIVSahayogiVBL.dbo.LoanRepaySched l 
				where l.MainCode =@MainCode and cast(l.DueDate  as Date)= @flow_start_date --and l.Serno=@Serno
				);
				-------------
		   
				print ( @MainCode + ' EMI NO GRACE '+ cast(@flow_start_date as nvarchar) );

				--		 		if not exists (select 1 from FINMIG.dbo.PastDue p where p.ReferenceNo = @MainCode)
				--------------EMI for A/C not in Past Due-----------
				insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  ,flow_amt  
				,next_dmd_date ,next_int_dmd_date ,lr_int_freq_type	 
				,lr_int_freq_days	 ,lr_int_freq_hldy_stat ) values 
				(@ForAcid,'EIDEM',@flow_start_date,@v_RepayFreq ,@num_of_flows,@flow_amt
				,@flow_start_date,@flow_start_date, @v_RepayFreq
				, DatePart(Day,@flow_start_date),'P' );
								 
				/*			else
				-----------EMI for Past Due-------------
				begin
				SELECT @flow_start_date=  MIN(lrs.DueDate)  ,@num_of_flows= COUNT(*) , @Serno=min(lrs.Serno) 
				FROM  LoanRepaySched lrs  join Master m on lrs.MainCode=m.MainCode
				and lrs.BranchCode=m.BranchCode
				and lrs.MainCode=@MainCode
					 			
				insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  ,flow_amt  
				,next_dmd_date ,next_int_dmd_date ,lr_int_freq_type	 
				,lr_int_freq_days	 ,lr_int_freq_hldy_stat ) values 
				(@ForAcid,'EIDEM',@flow_start_date,@v_RepayFreq ,@num_of_flows,@flow_amt
				,@flow_start_date,@flow_start_date, @v_RepayFreq
				, DatePart(Day,@flow_start_date),'P' );
				end
				
				-------------
				*/

			end
			end try
			begin catch
 
			set @ERROR_MESSAGE=(sELECT ERROR_MESSAGE());				 
				print (@ERROR_MESSAGE + ' SEC:1 ' + @MainCode );
			end catch
		end
		
	if   @LoanType= 'NONEMI' and @L_LoanType='LOAN'
	-------Scheduled Loan-------
	/*
		Multiple PRDEM, Single INDEM 

	*/
	BEGIN

	if  exists (select   1 from PPIVSahayogiVBL.dbo.LoanRepaySched where MainCode=@MainCode and DueDate>=@MigDate)
	begin

		Begin try
	
		Declare @DuePrincipal money
		
		set @v_RepayFreq_Pri=(select Case							
							 when PrinRepayFreq='5' then 'Q'
							 when PrinRepayFreq='6' then 'H'
							 when PrinRepayFreq='7' then 'Y'
							else 
								case 
								 when @RepayFreq='5' then 'Q'
								when @RepayFreq='6' then 'H'
								when @RepayFreq='7' then 'Y'
								else 'M' end
						end from PPIVSahayogiVBL.dbo.LoanMaster 
						where MainCode=@MainCode );

/*		insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  ,flow_amt  
								--,next_dmd_date  
								)  
		select  @ForAcid,  'PRDEM' flow_id, MIN(l.DueDate) DueDate, @v_RepayFreq_Pri , Count(*) , DuePrincipal FlowAmt
								--, MIN(l.DueDate)	next_dmd_date  
								from PPIVSahayogiVBL.dbo.LoanRepaySched l
								 where  l.MainCode =@MainCode  and DueDate>=@MigDate 
								 group by DuePrincipal;
		*/	
	
/*			IF CURSOR_STATUS('global','Name_Cursor')>=-1
			BEGIN
			 DEALLOCATE Name_Cursor
			END

			DECLARE Name_Cursor CURSOR FOR  
			SELECT    lrs.MainCode, DatePart(Day,DueDate) Dayprt 
				FROM  PPIVSahayogiVBL.dbo.LoanRepaySched lrs  join PPIVSahayogiVBL.dbo.Master m on lrs.MainCode=m.MainCode
				and lrs.BranchCode=m.BranchCode
				and  DueDate>= @MigDate
				and lrs.MainCode=@MainCode
				group by lrs.MainCode, DatePart(Day,DueDate)				

			OPEN Name_Cursor;  
			FETCH NEXT FROM Name_Cursor;  

			if  isnull(@@CURSOR_ROWS,0) > 1
				BEGIN
				----For Nepali Calander	@@Cursor_rows>1 else not
				insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  ,flow_amt  
								--,next_dmd_date  
								)  
				select  @ForAcid,  'PRDEM' flow_id, MIN(l.DueDate) DueDate, @v_RepayFreq_Pri , Count(*) , DuePrincipal FlowAmt
								--, MIN(l.DueDate)	next_dmd_date  
								from PPIVSahayogiVBL.dbo.LoanRepaySched l
								 where  l.MainCode =@MainCode  and DueDate>=@MigDate 
								 group by DueDate,DuePrincipal;

				
				insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  ,flow_amt  
								--,next_dmd_date 
								) 
				select  @ForAcid,  'INDEM' flow_id, DueDate, @v_RepayFreq , 1  , isnull(ProjectedInt,0)   --ProjectedInt as Flow IntAMt to be confirmed
								--, DueDate	  
								from PPIVSahayogiVBL.dbo.LoanRepaySched l where  l.MainCode =@MainCode   
								and DueDate>=@MigDate group by DueDate,ProjectedInt;	  
				
				print @ForAcid
				END
			else
			BEGIN
*/			
			 -- ---For AD Calander as RepayDate is common
			 insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  ,flow_amt  
								--,next_dmd_date  
								)  
			 select  @ForAcid,  'PRDEM' flow_id, l.DueDate DueDate, @v_RepayFreq_Pri , 1 , sum(isnull(DuePrincipal, 0)-isnull(PaidPrincipal, 0)) FlowAmt
								--, --l.DueDate	next_dmd_date  
								from PPIVSahayogiVBL.dbo.LoanRepaySched l
								 where  l.MainCode =@MainCode  
								 and DueDate>=@MigDate and (isnull(DuePrincipal, 0)-isnull(PaidPrincipal, 0)) > 0
								 group by DueDate;
								 --,DuePrincipalSEC:4

				insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  
				,flow_amt  
								,next_dmd_date ) 
				select  @ForAcid,  'INDEM' flow_id, max(DueDate), @v_RepayFreq ,0--count(1)  
				, 0 FlowAmt,  --Flow IntAMt to be confirmed
								max(DueDate)	  from PPIVSahayogiVBL.dbo.LoanRepaySched l 
								where  l.MainCode =@MainCode   
								and DueDate>=@MigDate 
								--and isnull(ProjectedInt,1)>0; --group by DueDate ;	 /* For Single INDEM for NEMI*/
				
				PRINT @ForAcid 
	/*		
			END
	
			CLOSE Name_Cursor;  
			DEALLOCATE Name_Cursor;  
	*/		 
		End try
		
			begin catch
			
				set @ERROR_MESSAGE=(sELECT ERROR_MESSAGE());				 
				print (@ERROR_MESSAGE + ' SEC:2 ' + @MainCode );
			end catch
		end
	END


	if   @LoanType= 'NONEMI' and @L_LoanType='DEAL'
	begin
		begin try
		select @flow_amt=DealAmt ,@flow_start_date= MaturityDate  from PPIVSahayogiVBL.dbo.DealTable where ReferenceNo=@MainCode
		if @flow_start_date >  @MigDate 
		insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  ,flow_amt  
								,next_dmd_date ,next_int_dmd_date ,
								lr_int_freq_type	 
								 ,lr_int_freq_days	 ,lr_int_freq_hldy_stat ) values 
								(@ForAcid,'PRDEM',@flow_start_date,@v_RepayFreq ,1,@flow_amt
								,@flow_start_date,@flow_start_date
								, NULL		--@v_RepayFreq		-- Interest freq dtls should not be entered for Principal / Int installments						 @v_RepayFreq
								 , DatePart(Day,@flow_start_date),'P' );
		else
				insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  ,flow_amt  
								,next_dmd_date ,next_int_dmd_date ,
								lr_int_freq_type	 
								 ,lr_int_freq_days	 ,lr_int_freq_hldy_stat ) values 
								(@ForAcid,'PRDEM',@flow_start_date,@v_RepayFreq ,1,0.01
								,@MigDate,@MigDate
								, NULL		--@v_RepayFreq		-- Interest freq dtls should not be entered for Principal / Int installments						 @v_RepayFreq
								 , DatePart(Day,@flow_start_date),'P' );
		
		
		insert into @LA_SCH(foracid	 ,flow_id	,flow_start_date,lr_freq_type  , num_of_flows  ,flow_amt  
								,next_dmd_date ,next_int_dmd_date 
								,lr_int_freq_type	 
								 ,lr_int_freq_days	 ,lr_int_freq_hldy_stat ) values 
								(@ForAcid,'INDEM',@flow_start_date,@v_RepayFreq ,0--1
								,0
								,@flow_start_date,@flow_start_date
								, NULL		--@v_RepayFreq		-- Interest freq dtls should not be entered for Principal / Int installments
								 , DatePart(Day,@flow_start_date),'P' );

		End try
		
		begin catch
		
			set @ERROR_MESSAGE=(sELECT ERROR_MESSAGE());				 
			print (@ERROR_MESSAGE + ' SEC:3 ' + @MainCode );
		end catch
	end;
	
    FETCH NEXT FROM RL003   
		INTO @ForAcid	, @BranchCode	, @CyDesc	, @MainCode	, @AcType	,@LoanType ,@RepayFreq , @L_LoanType,@HasRepaySched

END   
CLOSE RL003;  
DEALLOCATE RL003;  
	 IF OBJECT_ID('FINMIG.dbo.LRS', 'U') IS NOT NULL
		DROP TABLE FINMIG.dbo.LRS;

	select * into FINMIG.dbo.LRS from @LA_SCH;

End


/*
--select * from FINMIG.dbo.ForAcidLAA where MainCode='0010000320TL'

--select * from FINMIG.dbo.LRS where foracid='0010100000006612'  




IF OBJECT_ID('tempdb.dbo.#flow', 'U') IS NOT NULL
DROP TABLE #flow;

select * into #flow	from 
(select foracid as foracid, max(flow_start_date)as flow_start_date, 'INDEM' as flow_id, '0' as num_of_flows 
,ROW_NUMBER() OVER( PARTITION BY foracid ORDER BY flow_start_date desc) as serial
from FINMIG.dbo.LRS  where flow_id = 'INDEM' 
--and foracid in (select distinct(foracid) from FINMIG.dbo.LRS where flow_id = 'INDEM')
group by foracid, flow_start_date)j where serial = 1


--select * from #flow

 
merge into FINMIG.dbo.LRS a using #flow b on (a.foracid = b.foracid and a.flow_id = b. flow_id and a.flow_start_date = b.flow_start_date) when
matched then update set a.num_of_flows = b.num_of_flows;	
 
*/