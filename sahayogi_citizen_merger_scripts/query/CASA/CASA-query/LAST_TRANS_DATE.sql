------ONE TIME RUN---------Last Transaction Date---------------------------

IF OBJECT_ID('FINMIG.dbo.LAST_TRANS_DATE', 'U') IS NOT NULL
  DROP TABLE FINMIG.dbo.LAST_TRANS_DATE;
  
SELECT * INTO FINMIG.dbo.LAST_TRANS_DATE FROM(
select MAX(TranDate) AS LastTranDate,MainCode from TransDetail group by MainCode)X