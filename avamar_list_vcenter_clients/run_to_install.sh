#!/bin/sh
echo " "
echo "hostname_reporter.pl installer begins..."
echo " "
echo "copying proxycp.jar to /usr/local/avamar/lib/proxycp.jar"
cp ./proxycp.jar /usr/local/avamar/lib/proxycp.jar
echo " "
echo " "
echo "You must be root to run the hostname_reporter.pl"
echo " "
echo "when root prompt # enter this command to see the hosts attached vla vCenter:"
echo " "
echo " type in: ./hostname_reporter.pl"
echo " "
echo " To save the output run as: hostname_reporter.pl > hosts_found.txt"
echo " "
echo "hostname_reporter.pl installer finished." 
