#!/bin/bash

# Prompt the user to enter the namespace
read -p "Enter the namespace: " namespace

# Get the current timestamp
timestamp=$(date +"%Y%m%d_%H%M%S")

# Create a directory to store the log files with the timestamp
mkdir -p "${namespace}_logs_${timestamp}"

# Get the list of pods in the specified namespace
pods=$(kubectl get pods -n "$namespace" --no-headers -o custom-columns=":metadata.name")

# Iterate over each pod and dump its logs to a file
for pod in $pods; do
  echo "Dumping logs for pod: $pod"
  kubectl logs -n "$namespace" "$pod" > "${namespace}_logs_${timestamp}/${pod}.log"
done

echo "Log dumping completed. Logs are stored in the ${namespace}_logs_${timestamp} directory."