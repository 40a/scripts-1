#!/bin/bash
#
# Description:
# Bash script to delete old indices from elasticsearch. Could be useful if you use daily created indices.
#
# Usage:
# clear_elastic_indices.sh days_to_left [--delete]
# days_to_left - indices older than this date will be deleted
# --delete - perform real deletion, in all other cases do 'dry-run'
#
# Example:
# clear_elastic_indices.sh 30 - show list of indices and mark indices older than 30 days, but do not really delete them
# clear_elastic_indices.sh 20 - show and delete indices older than 20 days from elasticsearch
#
#
# (c) Adel-S   https://github.com/adel-s
#


# Constants
min_days_to_left=20                                 # Limit of minimum days to keep indices. Script will decline accidental attempts to delete younger indices
es_url="localhost:9200"
grep="/bin/grep -Po"
sed="/bin/sed -r"
curl="/usr/bin/curl -s"
index_regex='^[a-zA-Z-]+-\d\d\d\d\.\d\d\.\d\d'      # Regex for search indices. Only indices under this mask will be checked.
result_file='/tmp/clear_elastic_indices.status'     # File to store result of clearance. Used for Zabbix integration.

# Check input variables
if [[ -z $1 ]]; then echo "No keys provided, exiting. Usage: clear_elastic_indices.sh days_to_left [--delete]"; echo "FAIL" > $result_file; exit 1; fi
if [[ $1 =~ ^[0-9]+$ && "$1" -ge "$min_days_to_left" ]]; then days_to_left=$1; else echo "days_to_left must be an integer and can not be less than $min_days_to_left"; echo "FAIL" > $result_file; exit 1; fi
if [[ ! -z $2 && "$2" == "--delete" ]]; then delete="true"; else delete="false"; fi

# All indices older than $border_timestamp will be deleted
border_timestamp=$(date -d `date +"%Y-%m-%d" --date="$days_to_left days ago"` +"%s")
indices_list=$($curl $es_url"/_cat/indices?h=index" | $grep $index_regex | sort -n)

if [[ ! $indices_list ]]; then echo "Can not get indices list."; echo "FAIL" > $result_file; exit 1;
else
  for line in $indices_list
  do
    echo -n $line
#    index_timestamp=$($curl $es_url"/"$line"/_settings?pretty" | $grep '(?:creation_date.*)\d{13}.*' | $grep '\d{10}')     # Get creation date from index settings
    index_timestamp=$(date --date="`echo $line | sed -r 's/(.*)([0-9]{4})\.([0-9]{2})\.([0-9]{2})/\2-\3-\4/g'`" +"%s")      # Get creation date from index name
    if [[ ! $index_timestamp || ! $index_timestamp =~ ^[0-9]+$ ]]; then echo "Cannot get index  $line creation date ($index_timestamp). Aborting."; echo "FAIL" > $result_file; exit 1; fi
    if [[ "$index_timestamp" -lt "$border_timestamp" ]]; then
    echo -n " - need to be deleted - ";
      if [[ ! "$delete" == "true" ]]; then echo "dry run"; else $curl -XDELETE $es_url"/"$line; echo; fi
    else
      echo
    fi
  done
fi

echo "OK" > $result_file