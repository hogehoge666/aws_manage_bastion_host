#!/bin/sh

# 2024/05/08
# AWS上の資格試験練習環境上の生きているインスタンスの数を返す
# Macが前提だがLinuxでも動作するはず
# 以下の環境変数が必要
#  REGION, BASTION_HOST_ID, WORKSTATION_ID

if [ -z "${REGION}" ] || [ -z "${BASTION_HOST_ID}" ] || [ -z "${WORKSTATION_ID}" ]; then
    echo "ERROR: Need following environement variables"
    echo "  REGION: region name.  eg) ap-northeast-1, etc"
    echo "  BASTION_HOST_ID: instance id.  eg) i-XXXXXXXXXXXXX"
    echo "  WORKSTATION_ID: instance id.  eg) i-YYYYYYYYYYYYY"
    exit 0
fi

# On Mac, you need to invoke /bin/echo for the "-n" option to work
/bin/echo -n "Verifying number of running instances... "
NUM_OF_RUNNING_INSTANCES=$(aws --region ${REGION} ec2 describe-instance-status --instance-ids ${BASTION_HOST_ID} ${WORKSTATION_ID} \
| jq ".InstanceStatuses | length")
echo "$NUM_OF_RUNNING_INSTANCES"
