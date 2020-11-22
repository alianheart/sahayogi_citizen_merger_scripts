#!/bin/hash

echo "-------------------TD004_II generate file solewise-----------------";

rm -r solwise_TD_II
mkdir solwise_TD_II

#rm -r P:/Banks/citizen/TD/etl_result/TD004/solwise_TD_II

cut -c4-6 TD004_II_NPR.TXT | sort | uniq > branch_TD_II


for line in `cat branch_TD_II` ;
	
	do
		#br=$(cut -c4-6 <<< "$line")
		 
		#grep $line TD004_II_NPR.TXT >> "P:/Banks/citizen/TD/etl_flow_ctz/TD004/solwise_TD_II/"$br'_TDII_NPR.TXT';
		awk '{if (substr($file,4,3)=="'$line'") print $0}' TD004_II_NPR.TXT >> "P:/Banks/citizen/TD/etl_flow_ctz/TD004/solwise_TD_II/"$line'_TDII_NPR.TXT';
		

done

rm -r P:/Banks/citizen/TD/etl_result/TD004/solwise_TD_II
mv solwise_TD_II P:/Banks/citizen/TD/etl_result/TD004/
