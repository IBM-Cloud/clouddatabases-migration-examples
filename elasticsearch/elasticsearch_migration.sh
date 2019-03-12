compose_username=composetestuser
compose_password=composetestpassword
compose_endpoint=test.composedb.com
compose_port=33999
icd_username=icdtestuser
icd_password=icdtestpassword
icd_endpoint=my-es.test.databases.appdomain.cloud
icd_port=24000
export CURL_CA_BUNDLE=/path/to/icd/ssl/certificate
storage_service_endpoint=s3-api.us-geo.objectstorage.service.networklayer.com
bucket_name=myawesomebucket
access_key=n9dh89h2189hd12hd
secret_key=nd0nd021nd012n0dn102nd01n20dn120d
path_to_snapshot_folder=elastic_search/deployment-1/migration

# Mount S3/COS bucket on Compose deployment
curl -H 'Content-Type: application/json' -sS -XPOST \
"https://${compose_username}:${compose_password}@${compose_endpoint}:${compose_port}/_snapshot/migration" \
-d '{
  "type": "s3",
  "settings": {
    "endpoint": "'"${storage_service_endpoint}"'",
    "bucket": "'"${bucket_name}"'",
    "base_path": "'"${path_to_snapshot_folder}"'",
    "access_key": "'"${access_key}"'",
    "secret_key": "'"${secret_key}"'"
  }
}'

# Mount S3/COS bucket on Databases for Elasticsearch
curl -H 'Content-Type: application/json' -sS -XPOST \
"https://${icd_username}:${icd_password}@${icd_endpoint}:${icd_port}/_snapshot/migration" \
-d '{
  "type": "s3",
  "settings": {
    "readonly": true,
    "endpoint": "'"${storage_service_endpoint}"'",
    "bucket": "'"${bucket_name}"'",
    "base_path": "'"${path_to_snapshot_folder}"'",
    "access_key": "'"${access_key}"'",
    "secret_key": "'"${secret_key}"'"
  }
}'

# Perform 1st snapshot on Compose deployment
curl -sS -XPUT \
"https://${compose_username}:${compose_password}@${compose_endpoint}:${compose_port}/_snapshot/migration/snapshot-1?wait_for_completion=true"

# Perform 1st restore on Databases for Elasticsearch
curl -H 'Content-Type: application/json' -sS -XPOST \
"https://${icd_username}:${icd_password}@${icd_endpoint}:${icd_port}/_snapshot/migration/snapshot-1/_restore?wait_for_completion=true" \
-d '{"include_global_state": false}'

# In the mean time, we continued writing to the Compose deployment.
# We're going to perform another snapshot/restore to get the new data to Databases for Elasticsearch

# Close all indices on ICD so we can perform the next restore on top of it, without touching the searchguard index
curl -sS "https://${icd_username}:${icd_password}@${icd_endpoint}:${icd_port}/_cat/indices/?h=index" | \
grep -v -e '^searchguard$' | \
while read index; do
  curl -sS -XPOST "https://${icd_username}:${icd_password}@${icd_endpoint}:${icd_port}/$index/_close"
done

# Perform 2nd snapshot on Compose deployment
curl -sS -XPUT \
"https://${compose_username}:${compose_password}@${compose_endpoint}:${compose_port}/_snapshot/migration/snapshot-2?wait_for_completion=true"

# Perform 2nd restore on Databases for Elasticsearch
curl -H 'Content-Type: application/json' -sS -XPOST \
"https://${icd_username}:${icd_password}@${icd_endpoint}:${icd_port}/_snapshot/migration/snapshot-2/_restore?wait_for_completion=true" \
-d '{"include_global_state": false}'

# In the mean time, we continued writing to the Compose deployment.
# We're going to perform another snapshot/restore to get the new data to Databases for Elasticsearch

# Close all indices on ICD so we can perform the next restore on top of it, without touching the searchguard index
curl -sS "https://${icd_username}:${icd_password}@${icd_endpoint}:${icd_port}/_cat/indices/?h=index" | \
grep -v -e '^searchguard$' | \
while read index; do
  curl -sS -XPOST "https://${icd_username}:${icd_password}@${icd_endpoint}:${icd_port}/$index/_close"
done

# Perform 3rd snapshot on Compose deployment
curl -sS -XPUT \
"https://${compose_username}:${compose_password}@${compose_endpoint}:${compose_port}/_snapshot/migration/snapshot-3?wait_for_completion=true"

# Perform 3rd restore on Databases for Elasticsearch
curl -H 'Content-Type: application/json' -sS -XPOST \
"https://${icd_username}:${icd_password}@${icd_endpoint}:${icd_port}/_snapshot/migration/snapshot-3/_restore?wait_for_completion=true" \
-d '{"include_global_state": false}'

# We can afford stopping writes for a minute.
# So at this point we stop writing to the Compose deployment. 
# We then proceed with a final snapshot/restore cycle to get all the remaining changes to Databases for Elasticsearch.

# Close all indices on Databases for Elasticsearch so we can perform the next restore on top of it, without touching the searchguard index
curl -sS "https://${icd_username}:${icd_password}@${icd_endpoint}:${icd_port}/_cat/indices/?h=index" | \
grep -v -e '^searchguard$' | \
while read index; do
  curl -sS -XPOST "https://${icd_username}:${icd_password}@${icd_endpoint}:${icd_port}/$index/_close"
done

# Perform 4th snapshot on Compose deployment
curl -sS -XPUT \
"https://${compose_username}:${compose_password}@${compose_endpoint}:${compose_port}/_snapshot/migration/snapshot-4?wait_for_completion=true"

# Perform 4th restore on Databases for Elasticsearch
curl -H 'Content-Type: application/json' -sS -XPOST \
"https://${icd_username}:${icd_password}@${icd_endpoint}:${icd_port}/_snapshot/migration/snapshot-4/_restore?wait_for_completion=true" \
-d '{"include_global_state": false}'

# Re-open all indices in Databases for Elasticsearch just in case some were not re-opened during the latest restore
curl -sS -XPOST "https://${icd_username}:${icd_password}@${icd_endpoint}:${icd_port}/_all/_open"

# At this point we start writing to the Databases for Elasticsearch
# All done.
