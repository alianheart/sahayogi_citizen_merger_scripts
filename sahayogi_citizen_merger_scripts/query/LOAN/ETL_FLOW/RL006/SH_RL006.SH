#!/bin/hash

echo "-------------------RL006 generate file solewise-----------------";

rm -r solwise_RL006

mkdir solwise_RL006

cut -c-3 RL006.TXT | sort | uniq > branch_LOAN


for line in `cat branch_LOAN` ;
	
	do
				 
		awk '{if (substr($file,1,3)=="'$line'" ) print $0;}' RL006.TXT >> "D:/Banks/citizen/loan/etl_flow/RL006/solwise_RL006/"$line'_RL006.TXT';
 
		
done

rm -r D:/Banks/citizen/loan/etl_result/RL006/
mv solwise_RL006 D:/Banks/citizen/loan/etl_result/RL006/

