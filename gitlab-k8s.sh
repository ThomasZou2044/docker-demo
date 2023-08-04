helm install gitlab gitlab/gitlab \
  --namespace gitlab \
  --set global.hosts.domain=localhost \
  --set global.hosts.externalIP= 127.0.0.1 \
  --set certmanager-issuer.email= jackzouyan@gmail.com \
  --set gitlab-runner.runners.privileged=true \
  --set gitlab-runner.runners.cache.type=s3 \
  --set gitlab-runner.runners.cache.s3ServerAddress=<S3_SERVER_ADDRESS> \
  --set gitlab-runner.runners.cache.s3BucketName=<S3_BUCKET_NAME> \
  --set gitlab-runner.runners.cache.s3BucketLocation=<S3_BUCKET_LOCATION>
