
--use PumoriPlusCTZ1
-- SQL query for RC005

SELECT 
ORGKEY	AS	      ORGKEY	
,DOCDUEDATE	 AS     DOCDUEDATE
,DOCRECEIVEDDATE	AS      DOCRECEIVEDDATE
,DOCEXPIRYDATE	   AS   DOCEXPIRYDATE
,DOCDELFLG	   AS   DOCDELFLG
,DOCREMARKS	  AS    DOCREMARKS
,SCANNED	AS	      SCANNED
,DOCCODE	AS	      DOCCODE
,DOCDESCR	  AS    DOCDESCR
,left(REFERENCENUMBER, 20)	AS      REFERENCENUMBER
,TYPE	AS	      TYPE
,ISMANDATORY	AS      ISMANDATORY
,SCANREQUIRED	 AS     SCANREQUIRED
,ROLE	AS	      ROLE
,DOCTYPECODE	AS      DOCTYPECODE
,DOCTYPEDESCR	  AS    DOCTYPEDESCR
,MINDOCSREQD	  AS    MINDOCSREQD
,WAIVEDORDEFEREDDATE AS  WAIVEDORDEFEREDDATE
,COUNTRYOFISSUE	  AS    COUNTRYOFISSUE
,PLACEOFISSUE	 AS     PLACEOFISSUE
,DOCISSUEDATE	 AS     DOCISSUEDATE
,IDENTIFICATIONTYPE AS   IDENTIFICATIONTYPE
,CORE_CUST_ID	AS      CORE_CUST_ID
,IS_DOCUMENT_VERIFIED AS IS_DOCUMENT_VERIFIED
,BEN_OWN_KEY   AS	      BEN_OWN_KEY
,BANK_ID	AS	      BANK_ID
,DOCTYPEDESCR_ALT1  AS   DOCTYPEDESCR_ALT1
,DOCDESCR_ALT1	 AS     DOCDESCR_ALT1
,STATUS		AS      STATUS
FROM FINMIG.dbo.RC005_LOOKUP
ORDER BY ORGKEY