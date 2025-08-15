On your host machine (not inside the container), run:

sudo chown root:docker /var/run/docker.sock
sudo chmod 660 /var/run/docker.sock

This will set the group to docker and allow group read/write access.

