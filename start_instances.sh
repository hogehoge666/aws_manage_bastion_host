#!/bin/sh

# 2024/05/08
# AWS上の資格試験練習環境のインスタンスを起動する
#  1. 生きているインスタンスが０個であることを確認
#  2. Bastion HostとWorkstationをStart
#  3. okになるまで待つ
#  4. okになったことを確認
#  5. アクセスに必要なアドレス情報を取得して表示
#
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
/bin/echo -n "Verifying there are no running instances... "
NUM_OF_RUNNING_INSTANCES=$(aws --region ${REGION} ec2 describe-instance-status --instance-ids ${BASTION_HOST_ID} ${WORKSTATION_ID} \
| jq ".InstanceStatuses | length")
if [ ${NUM_OF_RUNNING_INSTANCES} -ne 0 ]; then
    echo "FAIL($NUM_OF_RUNNING_INSTANCES)"
    echo "ERROR: There are already running instances."
    exit 0
fi
echo "OK($NUM_OF_RUNNING_INSTANCES)"


echo "Starting instances..."
aws --region ${REGION} ec2 start-instances --instance-ids ${BASTION_HOST_ID} ${WORKSTATION_ID}


echo "Waiting for the instances to become ok..."
aws --region ${REGION} ec2 wait instance-status-ok --include-all-instances --instance-ids ${BASTION_HOST_ID} ${WORKSTATION_ID}


/bin/echo -n "Verifying if Bastion Host is ok...   "
BASTION_HOST_STATUS=$(aws --region ${REGION} ec2 describe-instance-status --instance-ids ${BASTION_HOST_ID} \
| jq ".InstanceStatuses[].SystemStatus.Status" | tr -d '"')
# BASTION_HOST_STATUS=$(cat describe_instace_status.txt | jq ".InstanceStatuses[].SystemStatus.Status" | tr -d '"')
echo $BASTION_HOST_STATUS
if [ ${BASTION_HOST_STATUS} != "ok" ]; then
    echo "ERROR: Bastion Host system status is not ok"
    exit 0
fi
/bin/echo -n "Verifying if Workstation is ok ...  "
WORKSTATION_STATUS=$(aws --region ${REGION} ec2 describe-instance-status --instance-ids ${WORKSTATION_ID} \
| jq ".InstanceStatuses[].SystemStatus.Status" | tr -d '"')
# WORKSTATION_STATUS=$(cat describe_instace_status.txt | jq ".InstanceStatuses[].SystemStatus.Status" | tr -d '"')
echo $WORKSTATION_STATUS
if [ ${WORKSTATION_STATUS} != "ok" ]; then
    echo "ERROR: Workstation system status is not ok"
    exit 0
fi


/bin/echo -n "Fetching public IP address of Bastion Host...   "
BASTION_HOST_ADDRESS=$(aws --region ${REGION} ec2 describe-instances --instance-ids ${BASTION_HOST_ID} \
| jq ".Reservations[].Instances[].PublicIpAddress" | tr -d '"')
# BASTION_HOST_ADDRESS=$(cat describe-instances.txt | jq ".Reservations[].Instances[].PublicIpAddress" | tr -d '"')
echo $BASTION_HOST_ADDRESS
if [ "$(uname)" == 'Darwin' ]; then
    echo $BASTION_HOST_ADDRESS | pbcopy
fi
/bin/echo -n "Fetching private IP address of Workstation...   "
WORKSTATION_ADDRESS=$(aws --region ${REGION} ec2 describe-instances --instance-ids ${WORKSTATION_ID} \
| jq ".Reservations[].Instances[].PrivateIpAddress" | tr -d '"')
# WORKSTATION_ADDRESS=$(cat describe-instances.txt | jq ".Reservations[].Instances[].PrivateIpAddress" | tr -d '"')
echo $WORKSTATION_ADDRESS
echo ""


echo "*** How To Access New Environment *** "
echo ""
echo "Step1: Use Remote Desktop Client to connect to Bastion Host"
echo "  For Mac users, the public IP address of the Bastion Host has been copied to your clipboard."
echo ""
echo "Step2: Use freerdp on the Bastion Host to access the Workstation."
echo "  eg) xfreerdp /u:expert /size:1400x1000 /v:${WORKSTATION_ADDRESS}"
echo ""
echo ""
