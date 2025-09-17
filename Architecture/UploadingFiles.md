# Uploading and Downloading files

As mentioned before, the server will be accessible via `ssh` over `compute-node-1`. This node will have visibility over the volumes and will be our internal method of file access, both for inputs to be submitted and workflow outputs.

For security reasons, a `ssh` key needs to be provided. We suggest to use `id_25519`. There are several sources online to generate these keys. In order to have access, the public part of that key (i.e. contents of `id_ed25519.pub` file) is the one relevant for the server. **Please contact jara@uni-trier.de with said key to get server access.**

The keys should look like:
```bash
$ cat id_ed25519.pub
ssh-ed25519 (long hash string) (comment, most likely an username)
```


Once access has been given:

### To upload files

Volume for inputs has been mounted in the folder `/input/fp-nfs/`. Thus a simple `rsync` can be invoked to transfer data here. The folder has been organized as follows:

```
📂input/fp-nfs/
┗ 📂defaults
	┣ 📂AOI
  	┣ 📂tree-mask
	┣ 📂disturbances
	┣ 📂tree-species
	┗ [other work packages...]
```

Please make sure to place the required input files in a proper location. As an example, this has been done in tree-mask:
```
📂input/fp-nfs/defaults/tree-mask/
┣ 📂legal_forest_mask
┃	┗ 📦[tile folders, i.e. X0066_Y0053]
┣ 📂mask_samples
┃	┗ 📜forest_mask_samples_LCC.csv
┣ 📂national_mask
┃	┗ 📦[tile folders...]
┗ 📂training_point_mask
	┗ 📦[tile folders...]
```

Files can be uploaded via `rsync`.  Server ip will be provided when the key is sent.
```bash
$ rsync -avz (file_or_folder_to_be_uploaded) eouser@$ip:$destination # destination being /input/fp-nfs/...
```
where:
* `-a` is "archive mode" (short form for `-rlptgoD`: to make it `r`ecursive; and to preserve `l`inks, `p`ermissions, modification `t`imes, `g`roups, `o`wnership, and some things regarding `D`evices that we will not be using)
* `-v` is display results in a verbose form
* `-z` is to compress file data for transfers

As an example, I used a command like this one to transfer files into the server. Note that to transfer contents from a folder, the destination should be written without `/`.  
```bash
$ rsync -avz legal_forest_mask/ eouser@$ip:/input/fp-nfs/defaults/tree-mask/legal_forest_mask
```
Else, it would copy the folder inside the path (e.g. it would be transferred as `/input/.../tree-mask/legal_forest_mask/legal_forest_mask` on the case above).  
Do add a `/` to the destination when adding files
```bash
rsync -avz forest_mask_samples_LCC.csv eouser@$ip:/input/fp-nfs/defaults/tree-mask/mask_samples/
```
### To retrieve files

Volume for outputs has been mounted in the folder `/output/fp-nfs/`. Unlike inputs, they are classified by project
```
📂output/fp-nfs/
┣ 📂ForestPulse-base (default project name)
┃	┣ 📂Product A
┃  	┣ 📂Product B
┃	┣ 📂Product C
┃	┗ [other products...]
┗ [other projects...]
```

We use `rsync` to retrieve elements in a similar fashion:
```bash
$ rsync -avz eouser@$ip:/output/fp-nfs/$project_name/(file_or_folder) $local_folder
```

[examples pending]
[other visibility options pending]