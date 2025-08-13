#!/bin/bash
# V-230232
GOOD=$(sudo cut -d: -f2 /etc/shadow | grep -E '^(!|\*|\$6\$)' | wc -l); BAD_ACCOUNTS=$(sudo cut -d: -f1,2 /etc/shadow | grep -vE ':(!|\*|\$6\$)'); BAD_COUNT=$(echo "$BAD_ACCOUNTS" | wc -l); echo -e "Good: $GOOD, Bad: $BAD_COUNT\n---Bad Accounts---\n$BAD_ACCOUNTS"

# check hash is 512 in /etc/login.defs

# ask all users with bad password to reset
# first check who will be effected
# sudo cut -d: -f1,2 /etc/shadow | grep -vE ':(!|\*|\$6\$)' | cut -d: -f1
# then run the password expire 
# for user in $(sudo cut -d: -f1,2 /etc/shadow | grep -vE ':(!|\*|\$6\$)' | cut -d: -f1); do sudo chage --lastday 0 $user; done


