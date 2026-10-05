#!/bin/bash

etcdctl endpoint status -w json | jq '.[0].Status | {dbSize_MB: (.dbSize/1024/1024), dbInUse_MB: (.dbSizeInUse/1024/1024), fragmentation_pct: (((.dbSize - .dbSizeInUse) / .dbSize) * 100)}'