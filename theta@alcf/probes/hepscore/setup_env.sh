#!/bin/sh

# shellcheck disable=SC1090,SC2164

. $HOME/.miniconda3/etc/profile.d/conda.sh
conda create -y -n hepscore python=3.7
conda activate hepscore

conda install -y apache-libcloud chardet colorama future idna msgpack-python \
                 netifaces ntplib parse pymongo<4 pyzmq regex requests \
                 setproctitle urllib3

pip install git+https://github.com/radical-cybertools/radical.pilot.git@devel
pip install git+https://gitlab.cern.ch/hep-benchmarks/hep-score.git

pip install -U setuptools

# branch with updated version of APRun LM is out-of-date (TBD to be merged)
# wget https://raw.githubusercontent.com/radical-cybertools/radical.pilot/95cb607f31ddb58e8646a5772bf79c704d894e18/src/radical/pilot/agent/launch_method/aprun.py
# mv aprun.py $HOME/.miniconda3/envs/hepscore/lib/python3.7/site-packages/radical/pilot/agent/launch_method/aprun.py

mkdir -p $HOME/hepscore/containers && cd $HOME/hepscore/containers
singularity pull atlas-gen-bmk-v2.1.sif docker://gitlab-registry.cern.ch/hep-benchmarks/hep-workloads/atlas-gen-bmk:v2.1
ln -s atlas-gen-bmk-v2.1.sif atlas-gen-bmk:v2.1

cd ..
cat > ./hepscore_config.yaml <<EOT
hepscore_benchmark:
  benchmarks:
    atlas-gen-bmk:
      results_file: atlas-gen_summary.json
      ref_scores:
        gen: 384
      weight: 1.0
      version: v2.1
      args:
        threads: 1
        events: 10
  settings:
    name: HEPscore20POC
    reference_machine: "CPU Intel(R) Xeon(R) CPU E5-2630 v3 @ 2.40GHz"
    registry: dir://$HOME/hepscore/containers
    method: geometric_mean
    repetitions: 1
    retries: 0
    scaling: 355
    container_exec: singularity
EOT
