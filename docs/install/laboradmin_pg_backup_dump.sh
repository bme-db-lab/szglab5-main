#!/bin/bash
pg_dump --username=postgres laboradmin > /var/backups/laboradmin/dump_"`date "+%Y%m%d_%H%M"`".dump
