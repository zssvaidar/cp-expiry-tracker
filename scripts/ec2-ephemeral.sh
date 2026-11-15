#!/usr/bin/env bash
# Launch a throwaway EC2 instance, keep it for a fixed lifetime (default
# 4 minutes), then terminate it. Intended as a smoke test for the deployer.
#
# The instance is destroyed by two independent mechanisms:
#   1. this script terminates it once the lifetime has passed (or on
#      Ctrl-C / error, via an EXIT trap), and
#   2. a failsafe in the instance's user data shuts it down after the
#      lifetime; with shutdown behaviour "terminate" that destroys it even
#      if this script is killed or loses its connection.
#
# Requirements: AWS CLI v2 and credentials allowed to run ec2:RunInstances,
# ec2:CreateTags, ec2:DescribeInstances, ec2:TerminateInstances and
# ssm:GetParameter (the last only when AMI_ID is not set).
#
# Configuration (environment variables):
#   AWS_REGION        region to use (falls back to the AWS CLI default)
#   INSTANCE_TYPE     instance type                   (default: t3.micro)
#   AMI_ID            image to boot (default: latest Amazon Linux 2023,
#                     resolved through the public SSM parameter)
#   LIFETIME_SECONDS  how long the instance lives     (default: 240)
#   SUBNET_ID         optional subnet; otherwise the default VPC is used
#   SECURITY_GROUP_ID optional security group; otherwise the VPC default
#   NAME_TAG          value of the Name tag  (default: cp-expiry-tracker-ephemeral)
set -euo pipefail

INSTANCE_TYPE="${INSTANCE_TYPE:-t3.micro}"
LIFETIME_SECONDS="${LIFETIME_SECONDS:-240}"
NAME_TAG="${NAME_TAG:-cp-expiry-tracker-ephemeral}"
AMI_SSM_PARAM="/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"

log() { printf '[%s] %s\n' "$(date -u +%H:%M:%S)" "$*" >&2; }
die() { log "error: $*"; exit 1; }

command -v aws >/dev/null || die "AWS CLI not found on PATH"
[[ "$LIFETIME_SECONDS" =~ ^[0-9]+$ ]] && (( LIFETIME_SECONDS > 0 )) \
  || die "LIFETIME_SECONDS must be a positive integer (got '$LIFETIME_SECONDS')"

region_args=()
[[ -n "${AWS_REGION:-}" ]] && region_args=(--region "$AWS_REGION")
awsr() { aws "${region_args[@]}" "$@"; }

if [[ -z "${AMI_ID:-}" ]]; then
  AMI_ID="$(awsr ssm get-parameter --name "$AMI_SSM_PARAM" \
    --query Parameter.Value --output text)"
  [[ -n "$AMI_ID" && "$AMI_ID" != "None" ]] || die "could not resolve AMI from $AMI_SSM_PARAM"
fi

# Failsafe: power off after the lifetime (rounded up to whole minutes).
lifetime_minutes=$(( (LIFETIME_SECONDS + 59) / 60 ))
user_data="#!/bin/sh
shutdown -h +${lifetime_minutes}
"

expires_at="$(date -u -d "@$(( $(date +%s) + LIFETIME_SECONDS ))" +%Y-%m-%dT%H:%M:%SZ)"
tags="ResourceType=instance,Tags=[{Key=Name,Value=${NAME_TAG}},{Key=ManagedBy,Value=ec2-ephemeral.sh},{Key=ExpiresAt,Value=${expires_at}}]"

run_args=(
  --image-id "$AMI_ID"
  --instance-type "$INSTANCE_TYPE"
  --count 1
  --instance-initiated-shutdown-behavior terminate
  --user-data "$user_data"
  --tag-specifications "$tags"
  --query 'Instances[0].InstanceId'
  --output text
)
[[ -n "${SUBNET_ID:-}" ]] && run_args+=(--subnet-id "$SUBNET_ID")
[[ -n "${SECURITY_GROUP_ID:-}" ]] && run_args+=(--security-group-ids "$SECURITY_GROUP_ID")

instance_id=""
terminated=0

terminate() {
  [[ -n "$instance_id" && "$terminated" -eq 0 ]] || return 0
  terminated=1
  log "terminating $instance_id"
  awsr ec2 terminate-instances --instance-ids "$instance_id" >/dev/null
  awsr ec2 wait instance-terminated --instance-ids "$instance_id"
  log "$instance_id terminated"
}
trap terminate EXIT
trap 'exit 130' INT TERM

log "launching $INSTANCE_TYPE from $AMI_ID (lifetime ${LIFETIME_SECONDS}s, expires $expires_at)"
launched_at=$(date +%s)
instance_id="$(awsr ec2 run-instances "${run_args[@]}")"
[[ "$instance_id" == i-* ]] || die "unexpected run-instances output: '$instance_id'"
log "launched $instance_id, waiting for it to be running"

awsr ec2 wait instance-running --instance-ids "$instance_id"
log "$instance_id is running"

remaining=$(( launched_at + LIFETIME_SECONDS - $(date +%s) ))
if (( remaining > 0 )); then
  log "keeping $instance_id for ${remaining}s"
  # Sleep in the background so INT/TERM interrupt the wait immediately.
  sleep "$remaining" & wait $!
fi

terminate
echo "$instance_id"
