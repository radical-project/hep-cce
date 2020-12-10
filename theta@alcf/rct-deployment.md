RADICAL-Cybertools (RCT) for Theta[GPU]
===
- Deployment of [RCT](https://github.com/radical-cybertools) and its 
environment at [Theta](https://www.alcf.anl.gov/support-center/theta)

# 1. Virtual environment deployment

## 1.1 Conda environment (basic)
There are two options to setup conda environment, but the choice of which 
approach to pick depends on the system to run the workload: **Theta** or 
**ThetaGPU**.

(A) Use predefined module (for Theta only)
```shell
export PYTHONNOUSERSITE=True
export RCT_CONDA_ENV=rct

module load miniconda-3
conda create -y -p $HOME/$RCT_CONDA_ENV --clone $CONDA_PREFIX
conda activate $HOME/$RCT_CONDA_ENV
conda config --add channels conda-forge
conda update -y --all
```
NOTE: the list of installed packages is provided 
[here](https://www.alcf.anl.gov/support-center/theta/conda-theta) 
(`packages in environment at /soft/datascience/conda/miniconda3/latest`)

(B) Create conda from scratch (for Theta and ThetaGPU)
```shell
export PYTHONNOUSERSITE=True
export RCT_CONDA_ENV=rct

wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O $HOME/miniconda.sh
chmod +x $HOME/miniconda.sh
$HOME/miniconda.sh -b -p $HOME/.miniconda3
source $HOME/.miniconda3/bin/activate
conda update -y -n base -c defaults conda
conda create -y -n $RCT_CONDA_ENV python=3.7
conda activate $RCT_CONDA_ENV
conda config --add channels conda-forge
conda update -y --all
```

## 1.2. RCT installation
RCT packages are published on [PyPI](https://pypi.org) and are available 
through `pip` as well as on [conda-forge](https://anaconda.org/conda-forge) 
for conda package management system. Here are core packages of RCT stack: 
`radical.utils`, `radical.saga`, `radical.pilot`, `radical.entk` and 
`radical.analytics`.
```shell
$ radical-stack

  python               : 3.7.9
  virtualenv           : rct

  radical.analytics    : 1.5.0
  radical.entk         : 1.5.7
  radical.gtod         : 1.5.0
  radical.pilot        : 1.5.7
  radical.saga         : 1.5.7
  radical.utils        : 1.5.8
```
Some dependencies could be pre-installed, and a particular branch being used. 
RADICAL-Pilot (RP) branch, which is related to Theta, is `project/cobalt` 
(NOTE: this branch is kept as a special case).
```shell
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
```shell
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
```shell
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
```shell
# Launch the server
$HOME/mongo/bin/mongod -f $HOME/mongo/etc/mongodb.theta.conf
# Shutdown the server
$HOME/mongo/bin/mongod -f $HOME/mongo/etc/mongodb.theta.conf --shutdown  
```

## 2.3. MongoDB initialization
Initialize MongoDB (should be done ONLY once; if MongoDB instance was already 
running, then this step was completed)
```shell
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

NOTE (1): default queue for tests is `debug-flat-quad`, production queue is 
`default` (with minimum 128 nodes).

NOTE (2): queue for ThetaGPU is `full-node` 
([user guide](https://www.alcf.anl.gov/support-center/theta/gpu-node-queue-and-policy))
```json
{
    "theta": {
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
        "virtenv"                     : "/home/$USER/rct",
        "rp_version"                  : "installed",
        "stage_cacerts"               : true,
        "cores_per_node"              : 64
    },
    "theta_gpu": {
        "schemas"                     : ["local"],
        "local"                       :
        {
            "job_manager_hop"         : "cobalt://localhost/",
            "job_manager_endpoint"    : "cobalt://localhost/",
            "filesystem_endpoint"     : "file://localhost/"
        },
        "default_queue"               : "full-node",
        "resource_manager"            : "COBALT",
        "lfs_per_node"                : "/tmp",
        "agent_config"                : "default",
        "agent_scheduler"             : "CONTINUOUS",
        "agent_spawner"               : "POPEN",
        "agent_launch_method"         : "MPIEXEC",
        "task_launch_method"          : "MPIEXEC",
        "mpi_launch_method"           : "MPIEXEC",
        "pre_bootstrap_0"             : [
            "source /home/$USER/.miniconda3/etc/profile.d/conda.sh"
        ],
        "valid_roots"                 : ["$HOME"],
        "default_remote_workdir"      : "$HOME",
        "python_dist"                 : "anaconda",
        "virtenv_mode"                : "use",
        "virtenv"                     : "rct",
        "rp_version"                  : "installed",
        "stage_cacerts"               : true,
        "cores_per_node"              : 128,
        "gpus_per_node"               : 8
    }
}
```

# 4. Run RCT-based workflows
Virtual environment activation
```shell
module load miniconda-3
conda activate /home/$USER/rct
### OR
# source $HOME/.miniconda3/bin/activate
# conda activate rct
```

Database URL
```shell
export RADICAL_PILOT_DBURL="mongodb://rct:jdWeRT634k@`hostname -f`:59361/rct_db"
```

# 4.1. Launch script
Corresponding workflow script could be wrapped with pre-/post-execution actions
(`rct_launcher.sh`).
```shell
#!/bin/sh

# - pre exec -
module load miniconda-3
conda activate /home/$USER/rct
### OR
# source $HOME/.miniconda3/bin/activate
# conda activate rct

$HOME/mongo/bin/mongod -f $HOME/mongo/etc/mongodb.theta.conf

export RADICAL_PILOT_DBURL="mongodb://rct:jdWeRT634k@`hostname -f`:59361/rct_db"
export RADICAL_LOG_LVL=DEBUG
export RADICAL_PROFILE=TRUE

# - exec -
<workflow_launcher_script>

# - post exec -
$HOME/mongo/bin/mongod -f $HOME/mongo/etc/mongodb.theta.conf --shutdown
```

```shell
./rct_launcher.sh

### OR run it in background
# nohup ./rct_launcher.sh > OUTPUT 2>&1 </dev/null &
### check the status of the script running
# jobs -l
```

# 4.2. Run jobs on GPU nodes ([ThetaGPU](https://www.alcf.anl.gov/support-center/theta/theta-thetagpu-overview))
Launch script above could be transformed into the following (**service nodes** 
for ThetaGPU are: `thetagpusn1` or `thetagpusn2` - _"Cobalt jobs cannot be 
submitted from the Theta login nodes to run on the GPU nodes; until that is 
supported, users will need to login in to the ThetaGPU service nodes from the 
Theta login nodes, and from there Cobalt jobs can be submitted to run on the 
GPU nodes"_)
```shell
#!/bin/sh

$HOME/mongo/bin/mongod -f $HOME/mongo/etc/mongodb.theta.conf

export RADICAL_PILOT_DBURL="mongodb://rct:jdWeRT634k@`hostname -f`:59361/rct_db"
ssh <service_node> "export RADICAL_PILOT_DBURL=$RADICAL_PILOT_DBURL; \
                    export RADICAL_LOG_LVL=DEBUG; \
                    export RADICAL_PROFILE=TRUE; \
                    source $HOME/.miniconda3/bin/activate; \
                    conda activate rct; \
                    cd <work_dir>; \
                    python <work_dir>/<executor>"

$HOME/mongo/bin/mongod -f $HOME/mongo/etc/mongodb.theta.conf --shutdown
```
