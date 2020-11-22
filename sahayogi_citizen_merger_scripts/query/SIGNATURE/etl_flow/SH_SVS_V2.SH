#!/bin/hash

echo "-------------------SVS generate file solewise-----------------";

rm -r solwise_SVS_final
mkdir solwise_SVS_final

cut -c-3 SVS_ALL.TXT | sort | uniq > branch_SVS


for line in `cat branch_SVS` ;
	
	do
		
		awk '{if (substr($file,1,3)=="'$line'" ) print $0;}' SVS_ALL.TXT >> "P:/Banks/citizen/signature/etl_flow/solwise_SVS_final/"$line'_SVS.TXT';


done

rm -r P:/Banks/citizen/signature/etl_output/solwise_SVS_final
mv solwise_SVS P:/Banks/citizen/signature/etl_output/


