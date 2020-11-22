use PPIVSahayogiVBL;
IF OBJECT_ID('tempdb.dbo.#collateral', 'U') IS NOT NULL
  DROP TABLE #collateral;
  
  select * into #collateral from MortgageTable;
  
  update #collateral set MortgageValue='0'
  where MortgageValue is null;
  
  update #collateral set MortgageValue=round(MortgageValue,2);
  
 IF OBJECT_ID('FINMIG.dbo.collateral', 'U') IS NOT NULL
  DROP TABLE FINMIG.dbo.collateral;
  SELECT * INTO FINMIG.dbo.collateral
  FROM #collateral;