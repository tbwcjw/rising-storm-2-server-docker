when the server is started using ./runServer.sh run|debug, two files are created in the root directory. these are our lockfiles, named "server.container.id" and "proxy.container.id". They store only the container ID of the running containers. These files ensure that two servers can't be created atop one another, creating a 
singleton environment. This is important as a duplicate container will try to use the same port as the original, failing to start.
should the server experience an unsafe shutdown; using a docker command, a crash, a power loss event, etc. these lock files will not be deleted, they will need to be
deleted manually after a investigation to prove no data-loss or corruption occurred. this is purely a means of preventing a corrupt server from starting and failing
integrity checks with steamcmd. the server should always be stopped with ./runServer.sh stop.

in the event of a failure to launch with ./runServer.sh run, but a success with ./runServer.sh run it is likely that the rs2server.yaml file has been modified since the
last time the last ./runServer.sh build. this can usually be fixed by deleting the container by id, with docker rm <container_id>. if this doesn't fix it, you can rebuild
without any data loss. 

static content such as banner images are run through the nginx proxy in the non-ssl port 80 section. this is purely because the server doesn't or can't retrieve from SSL sources. should we require a custom map or mutator that isn't available on the steam workshop we will need to create another location block in nginx.conf, as well as mounting a volume in rs2server.yaml. runServer.sh will also need to have the location added to mkdir commands and have its permissions set.
    
./runServer.sh backup clones these directories into a zip file with a datetime string for a filename:
    - ./proxy/*
    - ./steamcmd/*
    - ./server/server/ROGame/Config/*
backup does not store game binaries. 22gb+ zips are not practical.

./runServer.sh restore launches a user inputable cli menu (after the server stops) where zip files in ./backups/ are listed in numerical order. pick the number you wish to restore from and press enter.
there is no warning before the server restores itself, use this with caution.


known issues:
    - ROWeb.ini gets the value of bEnabled set to false, seemingly at random. This will disable the WebAdmin panel. The workaround is to enter the ROWeb.ini and reset the value. This problems seems to occur mostly when we take a backup from a running server.
    - SHA1: Credentials are hashed with SHA1. We know SHA1 is succeptible to collision attacks and isn't considered cryptographically secure. I created a TWI forum post with the hopes there is a drop-in replacement. We should not expose WebAdmin to WAN. Tried asking on the forum, got no response.
    - VNGame logs `Warning, Workshop: Unable to download workshop item <id>`, even though the workshop item has been downloaded and is working.
    - VNGame logs `Global Ban List: Failed to download. No global ban enforcements will take place.`. I'm not sure a global ban list has ever existed, even.
    


