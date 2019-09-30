#!/bin/bash

#Get ccid list file
echo "Enter the ccid list file name which contains all ccid's(eg. ccidlist.txt):"
read ccidlist

#Get log file
echo "Enter the log file name(eg. wso2carbon.log.2019-08-24.gz):"
read logfile

#Get output file
echo "Enter the output file name(eg. Batch1-Output.xlsx):"
read outputfile

#ccid count
number=$(sed -n '$=' $ccidlist)

#print all the ccid present in the ccid file
#cat $ccidlist

#Total number of ccid
echo $number

#Grep ccid one by one and check the response status
for value in $(seq $number);
do
	echo $value
	ccid=$(sed -n "${value}p" $ccidlist)
        response1="Request has been execute successfully"
        response2="Insufficient Balance"
	echo "ccid is $ccid"
	echo $ccid  >> xltran.txt
	status=$(zgrep $ccid $logfile | zgrep  'Response from XL' | sed -e 's/.*responseDesc\(.*\)responseDesc.*/\1/' | sed -e 's/[^a-zA-Z*0-9-]/ /g;s/  */ /g')
	echo "first status is $status"

#check status value
        case $status in
                *$response1*)
                        echo "response1"
                        echo $status >> xltran.txt
                        ;;
		*$response2*)
			echo "response2"
                        echo $status >> xltran.txt
                        ;;
                "")
                        echo "ccid not present" >> xltran.txt
                        ;;
                *)
			echo "Activity timeout occurred"
                        status1=$(zgrep $ccid $logfile | zgrep  'Response from XL' | sed -e 's/.*message\(.*\)message.*/\1/' | sed -e 's/[^a-zA-Z*0-9-]/ /g;s/  */ /g')
			
			xltransid=$(zgrep $ccid $logfile | zgrep  'Response to MIFE' | sed -e 's/.*serverReferenceCode\(.*\)serverReferenceCode.*/\1/' | sed -e 's/[^a-zA-Z*0-9-]/ /g;s/  */ /g' | sed "s/ //g")
			echo "xltransid is $xltransid"

			status=$(curl -H 'Accept: application/xml' -H 'Content-Type: application/xml' -X GET http://172.30.120.32:9006/BusinessServices/svcBilPaymentCarrierBilling/V1.0/opCheckStatus/?transactionId="$xltransid" | sed -n 's|.*"responseDesc":"\([^"]*\)".*|\1|p' )
			echo "activity timeout status is $status"
                        echo $status1$status >> xltran.txt
        esac



#Print Charged or Not Charged according to the response status
	case $status in
		*$response1*)
			echo "Charged" >> xltran.txt
			;;
		*$response2*)
			echo "Not Charged" >> xltran.txt
			;;
		"")
			echo "No Status" >> xltran.txt
			;;
		*)
			echo $status >> xltran.txt
			echo "different status"
			;;
	esac
done

#move the final result to a excel sheet
awk '{printf "%s%s",$0,NR%3?"\t":RS}' xltran.txt  > $outputfile
echo "created output file"

#rm xltran.txt
#echo "xltran file deleted"
exit 0
