# IBM Cloud Databases for Redis Migration Guide

This script will allow you to migrate your Compose for Redis database to IBM Cloud Databases for Redis. The script will copy the keys in your Compose for Redis database one-by-one to your Databases for Redis deployment. If you have time sensitive keys, those keys will be copied over as well with their TTL values. 

We recommend setting a maintenance window when you decide to migrate so that you stop writes to your Redis deployment. That way you don't need to run the script again to copy new keys, and you can then use your new database connection strings from Databases for Redis.

## Variables used in the migration script
You will need the following credentials when running the migration script:

- Compose hostname
- Compose port
- Compose database password
- IBM Cloud Databases for Redis hostname
- IBM Cloud Databases for Redis port
- IBM Cloud Databases for Redis password 
- Path to IBM Cloud Databases for Redis CA certificate

These can be gathered using the `ibmcloud cdb` command.

## Running the script

Once you've got the credentials to your IBM Cloud Databases for Redis database, you can run the script using Python 3 from the terminal.

```shell
python3 redis_migration.py <source host> <source password> <source port> <destination host> <destination password> <destination port>  <destination ca certificate path> --sslsrc --ssldst
```

For example:

```shell
python3 redis_migration.py database.composedb.com mypassword123 99999 redis.test.databases.appdomain.cloud mypassword456 88888  ~/path/to/cert --sslsrc --ssldst
```
