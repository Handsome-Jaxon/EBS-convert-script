#!/bin/bash

function usage {
    echo "Usage: $(basename $0) [-r AWS_REGION] [-o ORIGIN_EBS_TYPE] [-n NEW_EBS_TYPE]"
    echo "This script is used for change EBS type in one AWS region."
    echo "   -r AWS_REGION   Specify the EC2 region that the node is hosted. Defaults to $AWS_REGION."
    echo "   -o ORIGIN_EBS_TYPE   Specify original EBS type. Defaults to $ORIGIN_EBS_TYPE"
    echo "   -n NEW_EBS_TYPE   Specify new EBS type, need to different from the original type. Defaults to $NEW_EBS_TYPE"

    exit 1
}

AWS_REGION="us-east-2"
ORIGIN_EBS_TYPE="gp2"
NEW_EBS_TYPE="gp3"

while getopts "r:o:n:" arg; do
    case ${arg} in
        r)
            AWS_REGION="${OPTARG}"
            ;;
        o)
            ORIGIN_EBS_TYPE="${OPTARG}"
            ;;
        n)
            NEW_EBS_TYPE="${OPTARG}"
            ;;
        ?)
            usage
            ;;
    esac
done
shift "$(($OPTIND -1))"

# check EBS type input is valid or not
case $ORIGIN_EBS_TYPE in
    gp2|gp3|io1|io2|standard|sc1|st1)
        ;;
    *)
        echo "Invalid origin EBS type, please check."
        exit 1
        ;;
esac

# check EBS type input is valid or not
case $NEW_EBS_TYPE in
    gp2|gp3|io1|io2|standard|sc1|st1)
        ;;
    *)
        echo "Invalid new EBS type, please check."
        exit 1
        ;;
esac

# check original/new EBS type is dfference
if [[ "$ORIGIN_EBS_TYPE" == "$NEW_EBS_TYPE" ]]; then
    echo "Original EBS type & new EBS type should be different, please check."
    exit 1
fi

echo "AWS region:           ${AWS_REGION}"
echo "Original EBS type:    ${ORIGIN_EBS_TYPE}"
echo "New EBS type:         ${NEW_EBS_TYPE}"
echo


echo "start fetching EBS type ${ORIGIN_EBS_TYPE} in ${AWS_REGION}"
# get all EBS ID with origin type
volume_id=$(aws ec2 describe-volumes --region ${AWS_REGION} --filters Name=volume-type,Values=${ORIGIN_EBS_TYPE} --query "Volumes[].VolumeId" --output text)

# print all ebs Id
echo "Below is the EBS Id list with type $ORIGIN_EBS_TYPE in AWS region $AWS_REGION"
for vol in ${volume_id[@]}; do
    echo $vol
done
echo

echo "Please confirm if going to convert.(y/n)"
read -r confirm

# read the confirmation, only accept "y" or "yes"
if ! [[ $confirm =~ ^(y|yes)$ ]]; then
    echo "Convert canceled."
    exit 1
fi

# convert ebs type 
for vol in ${volume_id[@]}; do
    echo "Convert $vol to $NEW_EBS_TYPE."
    aws ec2 modify-volume --volume-type $NEW_EBS_TYPE --volume-id $vol --region $AWS_REGION --no-cli-pager
    echo
done