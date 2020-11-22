#!/bin/hash

echo "-------------------CS005 generate file solewise-----------------";

rm -r solwise_CAA
mkdir solwise_CAA
rm -r P:/Banks/citizen/CASA/etl_result/solwise_CAA

cut -c47-52 CS005_CAA.TXT | uniq > branch_currency_caa
cut -c47-49 CS005_CAA.TXT | sort | uniq > currency_caa

DESTDIR="P:/Banks/citizen/CASA/etl_flow/CS005/";
FILENAME="CS005_SBA";

for line in `cat currency_caa` ;
	
	do
		cr=$(cut -c-3 <<< "$line")
		mkdir  P:/Banks/citizen/CASA/etl_flow/CS005/solwise_CAA/$cr

	done
for line in `cat branch_currency_caa` ;
	
	do
		br=$(cut -c4-6 <<< "$line")
		cr=$(cut -c-3 <<< "$line") 
		
		grep $line CS005_CAA.TXT >> "P:/Banks/citizen/CASA/etl_flow/CS005/solwise_CAA/$cr/"$br'_'$cr'_CS005_CAA'.TXT;

	done

mv solwise_CAA	P:/Banks/citizen/CASA/etl_result/
