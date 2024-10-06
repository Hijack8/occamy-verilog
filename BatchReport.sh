#!/bin/bash

echo "--------------------- BatchReport ---------------------"

if [ ! -d ./temp_reports ]; then
    mkdir ./temp_reports
fi
rm ./TotalReport.rpt
rm ./BatchExecution.log
rm -r ./temp_reports/*

touch BatchExecution.log
touch TotalReport.rpt

export rtl_files=$(ls ./rtl/ -F | grep ".v")
rtl_files=$(echo "$rtl_files" | sed 's/\.v//g')

echo "Files in ./rtl:"
for file in $rtl_files; do
    echo "  $file"
done

echo "Running Synopsys for each file..."

for file in $rtl_files; do
    echo "Processing $file..."
    
    export TOP_MODULE=$file
    bash  ./synopsys.sh -s $file >> BatchExecution.log 2>&1
    mkdir ./temp_reports/$file
    bash  ./synopsys.sh -r >> BatchExecution.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo "$file Synopsys finished successfully"
        cp ./report/area.rpt ./temp_reports/$file/area.rpt
        cp ./report/power.rpt ./temp_reports/$file/power.rpt
        cp ./report/design.rpt ./temp_reports/$file/design.rpt
    else
        echo "$file Synopsys failed"
        exit 1
    fi

    bash  ./synopsys.sh >> BatchExecution.log -c 2>&1
done

echo "Generating TotalReport.rpt..."

for file in $rtl_files; do
    cd ./temp_reports/$file
    echo "Report for $file" >> ../../TotalReport.rpt 
    
    area=$(grep "Total cell area" area.rpt | awk '{print $4}')
    power=$(grep "Total" power.rpt | awk '{print $8}')
    power=$(echo "$power" | tr -d '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    echo -e "\tArea: $area" >> ../../TotalReport.rpt
    echo -e "\tPower: $power mW\n---------------" >> ../../TotalReport.rpt

    cd ../../
done

echo "TotalReport.rpt generated successfully"

echo "--------------------- END BatchReport ---------------------"
