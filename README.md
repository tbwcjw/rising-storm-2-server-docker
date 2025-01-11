## Rising Storm 2 Server Docker Container ##

### Lockfiles ###
When the server is started using ./runServer.sh run|debug, two lockfiles are created in the root directory:

* server.container.id
* proxy.container.id

These files store the container IDs of the running containers to ensure that only one instance of the server is active. This prevents conflicts like multiple containers attempting to use the same ports. Lockfiles are not automatically deleted in cases of unsafe shutdowns (e.g., Docker commands, crashes, power loss). They must be manually removed after verifying that no data loss or corruption has occurred. Always stop the server properly using ./runServer.sh stop.

### Troubleshooting ###

#### Failure to Launch ####
If ./runServer.sh run fails but succeeds after subsequent attempts, the issue may stem from changes to rs2server.yaml since the last ./runServer.sh build.

##### Steps to Resolve: #####
* Delete the problematic container: ``` docker rm <container_id> ```
If the issue persists, rebuild the server. This process does not cause data loss.

##### Static Content and Proxy Configuration #####
Static content such as banner images is served via the Nginx proxy through non-SSL port 80. This is due to limitations in the server's ability to retrieve resources from SSL sources.
For custom maps or mutators not available on the Steam Workshop:
* Add a location block in nginx.conf.
* Mount a volume in rs2server.yaml.
* Update runServer.sh to include the location in its mkdir commands and set appropriate permissions.

#### Backup and Restore ####

### Backup ###
The ./runServer.sh backup command creates a zip file containing specific directories. The filename includes a datetime string for reference. The following directories are included:
```
./proxy/*
./steamcmd/*
./server/server/ROGame/Config/*
```

Note: Game binaries are excluded to avoid excessively large zip files (>22GB).

### Restore ###
The ./runServer.sh restore command provides a CLI menu for restoring backups. This process stops the server and lists zip files in the ./backups/ directory. Select the desired backup by entering its corresponding number.
Warning: There is no confirmation prompt before restoration begins. Use with caution.

### Known Issues ###

1. WebAdmin Disabled
    Description: The value of bEnabled in ROWeb.ini is sometimes set to false unexpectedly, disabling the WebAdmin panel.
    Workaround: Manually reset the value to true in ROWeb.ini.
    Cause: This issue occurs most often when taking a backup from a running server.

2. SHA1 Credentials
    Description: ``` WebAdmin credentials are hashed using SHA1, which is vulnerable to collision attacks and not cryptographically secure. ```
    Mitigation: ``` Avoid exposing WebAdmin to WAN. A forum post has been created requesting a drop-in replacement. ```

3. Workshop Item Warning
    Description: VNGame logs warnings like: ``` Warning, Workshop: Unable to download workshop item <id> ```
    Despite this, the item is often downloaded and functioning.

4. Global Ban List Warning
    Description: VNGame logs: ``` Global Ban List: Failed to download. No global ban enforcements will take place. ```
    The existence of a global ban list is unclear.

