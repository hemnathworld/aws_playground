#!/bin/bash

rman target / <<EOF
SET ENCRYPTION IDENTIFIED BY "hadrtest" ONLY;
BACKUP INCREMENTAL LEVEL 0 SECTION SIZE 512M DATABASE PLUS ARCHIVELOG;
BACKUP INCREMENTAL LEVEL 1 SECTION SIZE 512M DATABASE PLUS ARCHIVELOG;
BACKUP ARCHIVELOG ALL NOT BACKED UP 2 TIMES;
EXIT;
EOF
