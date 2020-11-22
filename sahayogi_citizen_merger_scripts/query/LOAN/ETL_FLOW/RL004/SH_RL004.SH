#!/bin/hash

echo "-------------------RL004 generate file solewise-----------------";

rm -r solwise_LOAN_BAL
mkdir solwise_LOAN_BAL

rm -r D:/Banks/citizen/loan/etl_result/RL004/

cut -c4-6 RL004.TXT | sort | uniq > branch_LOAN


for line in `cat branch_LOAN` ;
	
	do
	#	br=$(cut -c4-6 <<< "$line")
		 
	#grep $line RL004.TXT >> "P:/Banks/citizen/loan/etl_flow/RL004/solwise_LOAN_BAL/"$br'_LAM_DISBT.TXT';
	awk '{if (substr($file,4,3)=="'$line'") print $0;}' RL004.TXT >> "D:/Banks/citizen/loan/etl_flow/RL004/solwise_LOAN_BAL/"$line'_LAM_DISBT.TXT'
done

mv solwise_LOAN_BAL D:/Banks/citizen/loan/etl_result/RL004/

