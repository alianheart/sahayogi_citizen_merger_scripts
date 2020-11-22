#!/bin/hash

echo "-------------------TD004 generate file solewise-----------------";

rm -r solwise_TD_PI
mkdir solwise_TD_PI

cut -c4-6 TD004_PI_NPR.TXT | sort | uniq > branch_TD



#FILENAME="TD004_TD";

for line in `cat branch_TD` ;
	
	do
		#br=$(cut -c4-6 <<< "$line")
		 
		#grep $line TD004_PI_NPR.TXT >> "P:/Banks/citizen/TD/etl_flow_ctz/TD004/solwise_TD_PI/"$br'_TDPI_NPR.TXT';
		awk '{if (substr($file,4,3)=="'$line'") print $0}' TD004_PI_NPR.TXT >> "P:/Banks/citizen/TD/etl_flow_ctz/TD004/solwise_TD_PI/"$line'_TDPI_NPR.TXT';
done

rm -r P:/Banks/citizen/TD/etl_result/TD004/solwise_TD_PI
mv solwise_TD_PI P:/Banks/citizen/TD/etl_result/TD004/
