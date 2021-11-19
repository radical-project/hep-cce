#!/bin/sh

# - pre exec -
. $HOME/.miniconda3/bin/activate
conda activate hepscore

$HOME/mongo/bin/mongod -f $HOME/mongo/etc/mongodb.theta.conf

RADICAL_PILOT_DBURL="mongodb://rct:jdWeRT634k@`hostname -f`:59361/rct_db"
RADICAL_LOG_LVL=DEBUG
RADICAL_PROFILE=TRUE

export RADICAL_PILOT_DBURL RADICAL_LOG_LVL RADICAL_PROFILE

# - exec -
python run_rp_hepscore.py -c hepscore_config.yaml -o results

# - post exec -
$HOME/mongo/bin/mongod -f $HOME/mongo/etc/mongodb.theta.conf --shutdown
