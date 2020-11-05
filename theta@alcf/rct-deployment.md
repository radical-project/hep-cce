RADICAL-Cybertools (RCT) for Theta
===
- Deployment of [RCT](https://github.com/radical-cybertools) and its 
environment at [Theta](https://www.alcf.anl.gov/support-center/theta)

# 1. Virtual environment deployment

## 1.1 Conda environment (basic)
```shell script
export PYTHONNOUSERSITE=True
export RCT_CONDA_ENV=rct

module load miniconda-3
conda create -y -p $HOME/$RCT_CONDA_ENV --clone $CONDA_PREFIX
conda activate $HOME/$RCT_CONDA_ENV
conda update -y --all
```

## 1.2. RCT installation
RCT packages are published on [PyPI](https://pypi.org) and are available 
through `pip` as well as on [conda-forge](https://anaconda.org/conda-forge) 
for conda package management system. Here are core packages of RCT stack: 
`radical.utils`, `radical.saga`, `radical.pilot`, `radical.entk` and 
`radical.analytics`.
```shell script
$ radical-stack

  python               : 3.7.8
  virtualenv           : rct

  radical.analytics    : 1.5.0
  radical.entk         : 1.5.1
  radical.gtod         : 1.5.0
  radical.pilot        : 1.5.4
  radical.saga         : 1.5.4
  radical.utils        : 1.5.4
```
Some dependencies could be pre-installed, and a particular branch being used. 
RADICAL-Pilot (RP) branch, which is related to Theta, is `project/cobalt` 
(NOTE: this branch is kept as a special case).
```shell script
conda install -y apache-libcloud chardet colorama future idna msgpack-python \
                 netifaces ntplib parse pymongo python-hostlist pyzmq regex \
                 requests setproctitle urllib3

pip install radical.utils radical.saga
pip install git+https://github.com/radical-cybertools/radical.pilot.git@project/cobalt
```

# 2. RCT related services

## 2.1. MongoDB installation (locally)
If MongoDB was already setup and initialized then just run the instance 
(see "Run MongoDB instance" subsection).
```shell script
cd $HOME
wget https://downloads.mongodb.com/linux/mongodb-linux-x86_64-enterprise-suse15-4.4.0.tgz
tar -zxf mongodb-linux-x86_64-enterprise-suse15-4.4.0.tgz
mv mongodb-linux-x86_64-enterprise-suse15-4.4.0 mongo
mkdir -p mongo/data mongo/etc mongo/var/log mongo/var/run
touch mongo/var/log/mongodb.log
```

### Config setup
As [user guide](https://www.alcf.anl.gov/support-center/theta/mongodb) states 
_"Each server instance of MongoDB should have a unique port number, and this 
should be changed to a sensible number"_, then assigned port is
`59361`, which is a random number.
```shell script
cat > mongo/etc/mongodb.theta.conf <<EOT

processManagement:
  fork: true
  pidFilePath: $HOME/mongo/var/run/mongod.pid

storage:
  dbPath: $HOME/mongo/data

systemLog:
  destination: file
  path: $HOME/mongo/var/log/mongodb.log
  logAppend: true

net:
  bindIp: 0.0.0.0
  port: 59361
EOT
```

## 2.2. Run MongoDB instance
```shell script
# Launch the server
$HOME/mongo/bin/mongod -f $HOME/mongo/etc/mongodb.theta.conf
# Shutdown the server
$HOME/mongo/bin/mongod -f $HOME/mongo/etc/mongodb.theta.conf --shutdown  
```

## 2.3. MongoDB initialization
Initialize MongoDB (should be done ONLY once; if MongoDB instance was already 
running, then this step was completed)
```shell script
$HOME/mongo/bin/mongo --host `hostname -f` --port 59361
 > use rct_db
 > db.createUser({user: "rct", pwd: "jdWeRT634k", roles: ["readWrite"]})
 > exit
```

# 3. RP resource config for Theta
Use one of the following locations to keep the configuration data:
`$HOME/.radical/pilot/configs/resource_anl.json` (user space) OR
`$HOME/rct/lib/python3.7/site-packages/radical/pilot/configs/resource_anl.json` 
(virtenv space)

NOTE: default queue for tests is `debug-flat-quad`, production queue is 
`default` (with minimum 128 nodes).
```json
{
    "theta": {
        "description"                 : "",
        "notes"                       : "",
        "schemas"                     : ["local"],
        "local"                       : 
	    {
            "job_manager_hop"         : "cobalt://localhost/",
            "job_manager_endpoint"    : "cobalt://localhost/",
            "filesystem_endpoint"     : "file://localhost/"
        },
        "default_queue"               : "debug-flat-quad",
        "resource_manager"            : "COBALT",
        "lfs_per_node"                : "/tmp",
        "agent_config"                : "default",
        "agent_scheduler"             : "CONTINUOUS",
        "agent_spawner"               : "POPEN",
        "agent_launch_method"         : "APRUN",
        "task_launch_method"          : "APRUN",
        "mpi_launch_method"           : "APRUN",
        "pre_bootstrap_0"             : [
            "module load miniconda-3"
        ],
        "valid_roots"                 : ["$HOME"],
        "default_remote_workdir"      : "$HOME",
        "python_dist"                 : "anaconda",
        "virtenv_mode"                : "use",
        "virtenv"                     : "$HOME/rct",
        "rp_version"                  : "installed",
        "stage_cacerts"               : true,
        "cores_per_node"              : 64
    }
}
```

# 4. Run RCT-based workflows
Virtual environment activation
```shell script
module load miniconda-3
conda activate $HOME/rct
```

Database URL
```shell script
export RADICAL_PILOT_DBURL="mongodb://rct:jdWeRT634k@`hostname -f`:59361/rct_db"
```

# 4.1. Launch script
Corresponding workflow script could be wrapped with pre-/post-execution actions
(`rct_launcher.sh`).
```shell script
#!/bin/sh

# - pre exec -
module load miniconda-3
conda activate $HOME/rct

$HOME/mongo/bin/mongod -f $HOME/mongo/etc/mongodb.theta.conf

export RADICAL_PILOT_DBURL="mongodb://rct:jdWeRT634k@`hostname -f`:59361/rct_db"
export RADICAL_LOG_LVL=DEBUG
export RADICAL_PROFILE=TRUE

# - exec -
<workflow_launcher_script>

# - post exec -
$HOME/mongo/bin/mongod -f $HOME/mongo/etc/mongodb.theta.conf --shutdown
```

```shell script
./rct_launcher.sh

### OR run it in background
# nohup ./rct_launcher.sh > OUTPUT 2>&1 </dev/null &
### check the status of the script running
# jobs -l
```
