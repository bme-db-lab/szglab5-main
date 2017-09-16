#!/bin/bash
pg_dump --username=postgres laboradmin | tee >(xz >/var/backups/laboradmin/dump_"`date "+%Y%m%d_%H%M"`".dump.xz)
