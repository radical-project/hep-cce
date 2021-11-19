#!/usr/bin/env python3

__author__    = 'RADICAL-Cybertools Team'
__email__     = 'info@radical-cybertools.org'
__copyright__ = 'Copyright 2021, The RADICAL-Cybertools Team'
__license__   = 'MIT'

"""
RP application to run HEPscore20POC Benchmark on Theta@ALCF
https://gitlab.cern.ch/hep-benchmarks/hep-score
"""

import argparse
import os

import radical.pilot as rp

PILOT_DESCRIPTION = {
    'resource'     : 'anl.theta',
    'project'      : 'CVD_Research',
    'queue'        : 'debug-flat-quad',
    'cores'        : 64,
    'runtime'      : 60,  # max time for debug queue
    'access_schema': 'local'
}


def main():

    # input arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--config', type=str,
                        help='Custom YAML config', required=False)
    parser.add_argument('-o', '--output_dir', type=str,
                        help='Base output directory', required=False)
    opts = parser.parse_args()

    task_args   = ['-v', '-c']
    task_inputs = []
    if opts.config:
        cfg_name = os.path.basename(opts.config)
        task_args.extend(['-f', cfg_name])
        task_inputs.append({'source': 'pilot:///%s' % cfg_name,
                            'target': 'task:///%s' % cfg_name,
                            'action': rp.LINK})
    if opts.output_dir:
        task_args.extend([opts.output_dir])

    # pilot settings definition
    pd = {'input_staging': [opts.config]}
    pd.update(**PILOT_DESCRIPTION)

    # run RP
    session = rp.Session()
    try:
        pmgr = rp.PilotManager(session=session)
        tmgr = rp.TaskManager(session=session)
        tmgr.add_pilots(pmgr.submit_pilots(rp.PilotDescription(pd)))
        tmgr.submit_tasks(rp.TaskDescription({'cpu_processes': 1,
                                              'cpu_threads'  : 64,
                                              'executable'   : 'hep-score',
                                              'arguments'    : task_args,
                                              'input_staging': task_inputs}))
        tmgr.wait_tasks()
    finally:
        session.close(download=True)


if __name__ == '__main__':
    main()
