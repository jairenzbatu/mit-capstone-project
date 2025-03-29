docker rm -f snipeit
docker run -d -p 80:80 --name="snipeit" --env-file=/opt/my_env_file --mount source=snipe-vol,dst=/var/lib/snipeit snipe/snipe-it