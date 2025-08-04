# infra-docker
HomeLab Infrastructure with Docker Swarm

## To deploy apps with sops:
```bash
sops -d secrets.enc.yaml > docker-compose.secrets.yml && \
docker stack deploy -c docker-compose.yml -c docker-compose.secrets.yml <stack-name> && \
rm docker-compose.secrets.yml
```
