#!/bin/sh
set -e
echo "INFO: Checking container configuration..."
if [ -z "${GRAFANA_CONFIG_S3_BUCKET}" -o -z "${GRAFANA_CONFIG_S3_PREFIX}" ]; then
    echo "ERROR: GRAFANA_CONFIG_S3_BUCKET and GRAFANA_CONFIG_S3_PREFIX environment variables must be provided"
    exit 1
fi

S3_URI="s3://${GRAFANA_CONFIG_S3_BUCKET}/${GRAFANA_CONFIG_S3_PREFIX}"

# If either of the AWS credentials variables were provided, validate them
if [ -n "${AWS_ACCESS_KEY_ID}${AWS_SECRET_ACCESS_KEY}" ]; then
    if [ -z "${AWS_ACCESS_KEY_ID}" -o -z "${AWS_SECRET_ACCESS_KEY}" ]; then
        echo "ERROR: You must provide both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY variables if you want to use access key based authentication"
        exit 1
    else
        echo "INFO: Using supplied access key for authentication"
    fi
    
    # If either of the ASSUMEROLE variables were provided, validate them and configure a shared credentials fie
    if [ -n "${AWS_ASSUMEROLE_ACCOUNT}${AWS_ASSUMEROLE_ROLE}" ]; then
        if [ -z "${AWS_ASSUMEROLE_ACCOUNT}" -o -z "${AWS_ASSUMEROLE_ROLE}" ]; then
            echo "ERROR: You must provide both the AWS_ASSUMEROLE_ACCOUNT and AWS_ASSUMEROLE_ROLE variables if you want to assume role"
            exit 1
        else
            ASSUME_ROLE="arn:aws:iam::${AWS_ASSUMEROLE_ACCOUNT}:role/${AWS_ASSUMEROLE_ROLE}"
            echo "INFO: Configuring AWS credentials for assuming role to ${ASSUME_ROLE}..."
            mkdir ~/.aws
      cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}

[${AWS_ASSUMEROLE_ROLE}]
role_arn=${ASSUME_ROLE}
source_profile=default
EOF
            PROFILE_OPTION="--profile ${AWS_ASSUMEROLE_ROLE}"
        fi
    fi
    if [ -n "${AWS_SESSION_TOKEN}" ]; then
        sed -i -e "/aws_secret_access_key/a aws_session_token=${AWS_SESSION_TOKEN}" ~/.aws/credentials
    fi
else
    echo "INFO: Using attached IAM roles/instance profiles to authenticate with S3 as no AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY have been provided"
fi

echo "INFO: Fetching grafana credentials from $SECRET_ID"
GRAFANA_CREDENTIALS=$(aws secretsmanager get-secret-value --secret-id $SECRET_ID --query SecretString --output text | jq .grafana)
GRAFANA_USERNAME=$(echo $GRAFANA_CREDENTIALS | jq -r .username)
GRAFANA_PASSWORD=$(echo $GRAFANA_CREDENTIALS | jq -r .password)

echo "INFO: Copying grafana configuration file(s) from ${S3_URI} to /etc/grafana..."
aws ${PROFILE_OPTION} s3 cp ${S3_URI}/grafana.ini /etc/grafana/grafana.ini
aws ${PROFILE_OPTION} s3 sync ${S3_URI}/provisioning/ /etc/grafana/provisioning/

sed -i "s/GRAFANA_USERNAME/$GRAFANA_USERNAME/g" /etc/grafana/grafana.ini
sed -i "s/GRAFANA_PASSWORD/$GRAFANA_PASSWORD/g" /etc/grafana/grafana.ini

echo "INFO: Starting grafana..."
exec /run.sh

# change permissions on the private folder
API_KEY=curl -X POST -H "Content-Type: application/json" -d '{"name":"apikeycurl", "role": "Admin"}' http://${GRAFANA_USERNAME}:${GRAFANA_PASSWORD}@localhost:3000/api/auth/keys | jq '.key'
echo "INFO: Api key for default org $API_KEY"

FOLDER_UID=curl -H "Authorization: Bearer $API_KEY" "Accept: application/json" -H "Content-Type: application/json" http://localhost:3000/api/folders?limit=5