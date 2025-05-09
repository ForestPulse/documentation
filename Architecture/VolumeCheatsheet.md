
# Volume Maintenance Cheatsheet

## Expand Volume
tl;dr of [this](https://knowledgebase.code-de.org/en/latest/datavolume/How-to-extend-the-volume-in-Linux-on-CODE-DE.html)

> ⚠️ Security backups may be recommended for volumes other than `/workdir`

0. Unmount devices from every potential autofs/nfs client. Note that there should not be any activity, process or workflow running during the course of these operations.
```bash
# on every node:
sudo umount -l /folder #/userInput /input /workdir /output
sudo umount -f /folder #/userInput /input /workdir /output
```

> ⚠️ From this point onwards, assume `/dev/sdc1` is the device location. Replace with another path, if applicable ⚠️

1. unmount properly from nfs server (i.e. `internal-file-system`)

```bash
sudo umount /dev/sdc1
```

2. Using the OpenStack dashboard interface:
    * Detach from `internal-file-system` (Volume overview > Manage Attachments). 
    * Only then, the option to expand the volume will appear. Set the new volume size.

3. Re-attach to `internal-file-system` and access it via command line:
``` bash
lsblk # as a sanity check for block data and volume size
```

``` bash
sudo growpart /dev/sdc 1 #note that the number is separated
sudo e2fsck -f /dev/sdc1/
sudo resize2fs /dev/sdc1/

# and finally mount it back and set it to export again
sudo mount /dev/sdc1
sudo exportfs -ra
```
Previous `autofs` configuration will ensure that the device gets aligned to their respective folder (hopefully)

4. Finally, to re-mount on each client:
```bash
sudo systemctl restart autofs
```
Virtual Machines should automatically catch up based on a previous autofs configuration.  
Kubernetes may use a different method to detect volumes, namely Volume and VolumeClaim definition files already set up in the cluster. Given the ephemeral nature of pods, it should not cause an impact.

## Potential issues:
* check `sudo systemctl status autofs` in the client if the nfs is not recognized, an usual error is a not properly assigned host