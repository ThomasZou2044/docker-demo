docker run \
  --detach \
  --restart unless-stopped \
  --name gitlab-ce \
  --privileged \
  --memory 4G \
  --publish 22:22 \
  --publish 8082:80 \
  --publish 443:443 \
  --publish 127.0.0.1:8181:8181 \
  --hostname localhost \
  --env GITLAB_ROOT_PASSWORD="5545125@kp" \
  --env GITLAB_OMNIBUS_CONFIG=" \
    registry['enable'] = false; "\
  --volume /Users/yanzou/gitlab/conf:/etc/gitlab:z \
  --volume /Users/yanzou/gitlab/logs:/var/log/gitlab:z \
  --volume /Users/yanzou/gitlab/data:/var/opt/gitlab:z \
  yrzr/gitlab-ce-arm64v8:latest