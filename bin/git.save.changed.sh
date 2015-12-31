#!/bin/bash

# archive all changed files including files that haven't been added to version control
tar czf "/tmp/changed_files_`date +"%Y%m%d"`.tar.gz" `git status -s -u | awk '{print $2}'`
echo "archive saved in /tmp"
