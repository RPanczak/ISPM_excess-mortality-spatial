#!/bin/bash
#SBATCH --job-name="gr-deaths"
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=16G
#SBATCH --time=24:00:00
#SBATCH --mail-user=radoslaw.panczak@ispm.unibe.ch
#SBATCH --mail-type=end,fail

ml R

Rscript ~/ISPM_excess-mortality-spatial/analyses/04-02_grid-deaths.R