#!/bin/hash

echo "-------------------OD DUE INDEM generate file solewise-----------------";

rm -r solwise_OD_DUE_INDEM
mkdir solwise_OD_DUE_INDEM

cut -c17-22 OD_INDEM_DUE.TXT | uniq > branch_currency_OD_INDEM


for line in `cat branch_currency_OD_INDEM` ;
	
	do
		br=$(cut -c4-6 <<< "$line")
		cr=$(cut -c-3 <<< "$line") 
		grep $line OD_INDEM_DUE.TXT >> "D:/Banks/citizen/CASA/OD_due/etl_flow/solwise_OD_DUE_INDEM/"$br'_'$cr'_OD_INDEM_DUE'.TXT;

done


echo "-------------------OD DUE PIDEM generate file solewise-----------------";

rm -r solwise_OD_DUE_PIDEM
mkdir solwise_OD_DUE_PIDEM

cut -c17-22 OD_PIDEM_DUE.TXT | uniq > branch_currency_OD_PIDEM


for line in `cat branch_currency_OD_PIDEM` ;
	
	do
		br=$(cut -c4-6 <<< "$line")
		cr=$(cut -c-3 <<< "$line") 
		grep $line OD_PIDEM_DUE.TXT >> "D:/Banks/citizen/CASA/OD_due/etl_flow/solwise_OD_DUE_PIDEM/"$br'_'$cr'_OD_PIDEM_DUE'.TXT;

done

rm -r D:/Banks/citizen/CASA/OD_due/result/solwise_OD_DUE_PIDEM/
rm -r D:/Banks/citizen/CASA/OD_due/result/solwise_OD_DUE_INDEM/
mv solwise_OD_DUE_PIDEM	D:/Banks/citizen/CASA/OD_due/result/
mv solwise_OD_DUE_INDEM	D:/Banks/citizen/CASA/OD_due/result/
