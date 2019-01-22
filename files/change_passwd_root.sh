#!/bin/bash

echo -e "Content-Type: text/plain\r\nTo:  monitoring@initlab.ru\r\nSubject: Change password of root on `hostname`\r\n\r\nChange password of root!!!!!!" | sendmail -v monitoring@initlab.ru

