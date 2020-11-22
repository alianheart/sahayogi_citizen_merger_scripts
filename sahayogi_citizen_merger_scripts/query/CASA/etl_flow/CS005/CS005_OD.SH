#!/bin/hash

echo "-------------------CS005 generate file solewise-----------------";

rm -r solwise_OD
mkdir solwise_OD

rm -r P:/Banks/citizen/CASA/etl_result/solwise_OD

cut -c47-52 CS005_OD.TXT | uniq > branch_currency_OD
cut -c47-49 CS005_OD.TXT | sort | uniq > currency_OD
DESTDIR="P:/Banks/citizen/CASA/etl_flow/CS005/";
FILENAME="CS005_OD";

for line in `cat currency_OD` ;
	
	do
		cr=$(cut -c-3 <<< "$line")
		mkdir  P:/Banks/citizen/CASA/etl_flow/CS005/solwise_OD/$cr

	done

for line in `cat branch_currency_OD` ;
	
	do
		br=$(cut -c4-6 <<< "$line")
		cr=$(cut -c-3 <<< "$line") 
		grep $line CS005_OD.TXT >> "P:/Banks/citizen/CASA/etl_flow/CS005/solwise_OD/$cr/"$br'_'$cr'_CS005_ODA_BAL'.TXT;

done

mv solwise_OD P:/Banks/citizen/CASA/etl_result/
