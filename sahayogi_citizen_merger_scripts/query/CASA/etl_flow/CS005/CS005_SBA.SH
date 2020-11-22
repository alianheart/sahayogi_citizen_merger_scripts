#!/bin/hash

echo "-------------------CS005 generate file solewise-----------------";

rm -r solwise_SBA
mkdir solwise_SBA
rm -r P:/Banks/citizen/CASA/etl_result/solwise_SBA

cut -c47-52 CS005_SBA.TXT | uniq > branch_currency_sba
cut -c47-49 CS005_SBA.TXT | sort | uniq > currency_sba
DESTDIR="P:/Banks/citizen/CASA/etl_flow/CS005/";
FILENAME="CS005_SBA";

for line in `cat currency_sba` ;
	
	do
		cr=$(cut -c-3 <<< "$line")
		mkdir  P:/Banks/citizen/CASA/etl_flow/CS005/solwise_SBA/$cr

	done

for line in `cat branch_currency_sba` ;
	
	do
		br=$(cut -c4-6 <<< "$line")
		cr=$(cut -c-3 <<< "$line") 
		grep $line CS005_SBA.TXT >> "P:/Banks/citizen/CASA/etl_flow/CS005/solwise_SBA/$cr/"$br'_'$cr'_CS005_SBA'.TXT;

done

mv solwise_SBA	P:/Banks/citizen/CASA/etl_result/
