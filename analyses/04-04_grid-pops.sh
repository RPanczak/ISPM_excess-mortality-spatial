#!/bin/bash
#SBATCH --job-name="gr-pop"
#SBATCH --cpus-per-task=128
#SBATCH --mem-per-cpu=256M
#SBATCH --time=24:00:00
#SBATCH --mail-user=radoslaw.panczak@ispm.unibe.ch
#SBATCH --mail-type=end,fail

ml vital-it
ml R/3.6.1

Rscript ~/ISPM_excess-mortality-spatial/analyses/04-04_grid-pops.R