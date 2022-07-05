#!/bin/bash
#SBATCH --job-name="gr-pop"
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=512M
#SBATCH --time=24:00:00
#SBATCH --mail-user=radoslaw.panczak@ispm.unibe.ch
#SBATCH --mail-type=end,fail

ml R

Rscript ~/ISPM_excess-mortality-spatial/analyses/04-03_grid-pops.R