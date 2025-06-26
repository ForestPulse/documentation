# Nextflow installation for each Node

Personal notes just to check what things to pay attention to when installing nextflow on a node/instance

* Check if java is installed
```bash
java -version
sudo apt install default-jdk
java -version
```

* Then install nextflow and modify its permits
```bash
curl -s https://get.nextflow.io | sudo bash
sudo chmod +x nextflow
# nextflow will be installed at current directory
```

* Move Nextflow to a $PATH location
```bash
mkdir -p $HOME/.local/bin/
# restart bash so that this location gets added to $PATH (as seen in ~/.profiles)
```

```bash
mv nextflow $HOME/.local/bin/

# instructions below can be done earlier too
cd $HOME/.local/bin
sudo chown eouser:eouser nextflow
```

* Finally, to check that everything is working correctly:
```bash
nextflow info
```