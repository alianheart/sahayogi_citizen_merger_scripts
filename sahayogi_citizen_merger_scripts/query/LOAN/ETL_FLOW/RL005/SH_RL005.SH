#!/bin/hash

echo "-------------------RL005 generate file solewise-----------------";

rm -r solwise_RL005
mkdir solwise_RL005


cut -c4-6 RL005.TXT | sort | uniq > branch_LOAN


for line in `cat branch_LOAN` ;
	
	do
		#br=$(cut -c4-6 <<< "$line")
		 
		#grep $line RL005.TXT >> "D:/Banks/citizen/loan/etl_flow/RL005/solwise_RL005/"$br'_RL005.TXT';
		awk '{if (substr($file,4,3)=="'$line'") print $0;}' RL005.TXT >> "G:/CITIZEN/OUTPUT/Loan/RL005/solwise_RL005/"$line'_RL005.TXT'

done

#rm -r D:/Banks/citizen/loan/etl_result/RL005/
#mv solwise_RL005 D:/Banks/citizen/loan/etl_result/RL005/

