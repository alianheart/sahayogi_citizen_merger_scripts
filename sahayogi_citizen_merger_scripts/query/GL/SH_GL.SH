#!/bin/hash

echo "-------------------GL generate file solewise-----------------";

rm -r solwise_GL

mkdir solwise_GL


cut -c17-22 GL_TTUM.TXT | uniq > branch_GL


for line in `cat branch_GL` ;
	
	do	
		br=$(cut -c4-6 <<< "$line")
		 
		grep $line GL_TTUM.TXT >> "D:/Banks/citizen/GL/etl/job/solwise_GL/"$br'_GL_TTUM.TXT';
		

done

rm -r D:Banks/citizen/GL/output/solwise_GL/

mv solwise_GL D:/Banks/citizen/GL/output/

