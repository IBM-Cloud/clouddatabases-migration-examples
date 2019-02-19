# IBM Cloud Databases for Elasticsearch Migration Guide

## Variables used in the migration script

#### Compose Credentials

- `compose_username` - tthe username combination used to authenticate against the Compose deployment
- `compose_password` - the password combination used to authenticate against the Compose deployment
- `compose_endpoint` - the hostname used to talk to the Compose deployment
- `compose_port` - the port used to talk to the Compose deployment

#### Databases for Elasticsearch Credentials

- `icd_username` - the hostname used to talk to the Databases for Elasticsearch deployment
- `icd_password` - the password combination used to authenticate against the Databases for Elasticsearch deployment
- `icd_endpoint` - the hostname used to talk to the Databases for Elasticsearch deployment
- `icd_port` - the port used to talk to the Databases for Elasticsearch deployment
- `export CURL_CA_BUNDLE` - path to a file containing the SSL client certificate used to connect to your Databases for Elasticsearch

#### IBM Cloud Object Storage / S3 Credentials

- `storage_service_endpoint` - the IBM Cloud Object Storage/S3 endpoint hostname
- `bucket_name` - the name of the IBM Cloud Object Storage/S3 bucket you're going to use
- `access_key` - the IBM Cloud Object Storage/S3 bucket HMAC access key
- `secret_key` - the IBM Cloud Object Storage/S3 bucket HMAC secret key
- `path_to_snapshot_folder` - the base path inside the bucket where we want to write all snapshot data. Make sure there's no leading slash (e.g: folder1/folder2, not /folder1/folder2)

## Running the script

Once you've downloaded and added your credentials to the script, you'll need to make it executable in the terminal. 

For macOS or Linux:

```shell
chmod a+x elasticsearch_migration.sh
```

Then run the script in your terminal, e.g.:

```shell
./elasticsearch_migrate.sh
```