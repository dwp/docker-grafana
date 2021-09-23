# docker-grafana
This repository contains code to create an image based on the Grafana image to be used within AWS

## Local Running

This image pulls a [Grafana configuration file](https://grafana.com/docs/grafana/latest/administration/configuration/) from S3 using the S3 environment variables provided.
It also acesses a secretmanager secret that needs to contain the following JSON
```
{
    "grafana": {
        "username": "grafana_admin_username",
        "password: "grafana_admin_password"
    }
}
```

#### Required Environment Variables

|             Key            |                                Description               |
|----------------------------|----------------------------------------------------------|
| GRAFANA_CONFIG_S3_BUCKET   | The ID of the config S3 bucket                           |
| GRAFANA_CONFIG_S3_PREFIX   | The directory path of the config files within the bucket |
| AWS_ACCESS_KEY_ID          | AWS access key                           |
| AWS_SECRET_ACCESS_KEY      | AWS secret access key |
| SECRET_ID                  | The id of the aws secretmanager secret that contains the grafana username and password


