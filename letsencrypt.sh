#!/bin/bash
TIME=0
EXIT=1
until [[ $EXIT -eq 0 ]]; do 
    kubectl apply -f letsencrypt-clusterissuer-prod.yaml
    EXIT=$?
    TIME=$(($TIME + 1))
    sleep 1
    echo "Time: $TIME"
    if [[ $TIME -eq 120 ]]; then
        exit 1
    fi
done
