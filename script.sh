#!/bin/bash
if [ -z "$AWS_S3_BUCKET" ]; then
  echo "AWS_S3_BUCKET is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "AWS_ACCESS_KEY_ID is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "AWS_SECRET_ACCESS_KEY is not set. Quitting."
  exit 1
fi


if [ -z "$AWS_SECRET_REGION" ]; then
  echo "AWS_SECRET_REGION is not set. Falling back to us-west-1."
  AWS_SECRET_REGION='us-west-1'
fi

BUCKET=$AWS_S3_BUCKET
POLICY="policy${BUCKET}"
USER="${BUCKET}"
REGION=us-west-1

aws configure --profile s3-actions <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF
create_user () {
    `cp /home/install/resources/bucket_policy.json .` && sed -i "s/SOME_USER/$BUCKET/g" 'bucket_policy.json'
    aws iam create-policy --policy-name $POLICY --policy-document file:///home/install/bucket_policy.json && \
    aws iam create-user --user-name $USER --region $REGION  && \
    ARN=$(aws iam list-policies --query 'Policies[?PolicyName==`'"$POLICY"'`]'.Arn --output text) && aws iam attach-user-policy --policy-arn $ARN --user-name $USER && \
    generate_keys || empty_keys
}
generate_keys () {
    RSP=$(aws iam create-access-key --user-name $USER);
    BUCKET_ACCESS_ID=$(echo $RSP | jq -r '.AccessKey.AccessKeyId');
    BUCKET_ACCESS_KEY=$(echo $RSP | jq -r '.AccessKey.SecretAccessKey');
    echo "::set-output name=BUCKET_ACCESS_KEY::$BUCKET_ACCESS_KEY"
    echo "::set-output name=BUCKET_ACCESS_ID::$BUCKET_ACCESS_ID"
}
empty_keys () {
    echo "::set-output name=BUCKET_ACCESS_KEY::NONE"
    echo "::set-output name=BUCKET_ACCESS_ID::NONE"
}
#temporarily copying local dirs TODO
populate_bucket () {
    DIREXISTS=`aws s3 ls s3://$BUCKET/app/seeds/`
    if [[ $DIREXISTS == 'NONE' ]] ; then
        echo 'wating for drive'
    fi 
    echo 'coPied dirs to bucket'   
}
start_proc () {
`aws s3api head-bucket --bucket $BUCKET`
if [[ $? -eq 0 ]] ; then
    echo 'bucket exists';
else    
    `aws s3api create-bucket --bucket $BUCKET --create-bucket-configuration LocationConstraint=$REGION --region $REGION` &&  aws iam get-user --user-name $USER && echo 'User exists' || create_user
fi
populate_bucket
}
start_proc

aws configure --profile s3-actions <<-EOF > /dev/null 2>&1
null
null
null
text
EOF