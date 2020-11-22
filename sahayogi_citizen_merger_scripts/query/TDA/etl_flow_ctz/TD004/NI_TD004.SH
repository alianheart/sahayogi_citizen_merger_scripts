#!/bin/hash

echo "-------------------CS005 generate file solewise-----------------";

rm -r solwise_TD_NI
mkdir solwise_TD_NI



cut -c4-6 TD004_NI_NPR.TXT | sort | uniq > branch_TD_NI


for line in `cat branch_TD_NI` ;
	
	do
		#br=$(cut -c4-6 <<< "$line")
		 
		#grep $line TD004_NI_NPR.TXT >> "P:/Banks/citizen/TD/etl_flow_ctz/TD004/solwise_TD_NI/"$br'_TDNI_NPR.TXT';
		awk '{if (substr($file,4,3)=="'$line'") print $0}' TD004_NI_NPR.TXT >> "P:/Banks/citizen/TD/etl_flow_ctz/TD004/solwise_TD_NI/"$line'_TDNI_NPR.TXT';
done

rm -r P:/Banks/citizen/TD/etl_result/TD004/solwise_TD_NI
mv solwise_TD_NI P:/Banks/citizen/TD/etl_result/TD004/
