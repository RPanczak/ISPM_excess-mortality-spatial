#!/bin/bash
#SBATCH --job-name="lme4 1"
#SBATCH --cpus-per-task=32
#SBATCH --mem-per-cpu=2G
#SBATCH --time=48:00:00
#SBATCH --mail-user=radoslaw.panczak@ispm.unibe.ch
#SBATCH --mail-type=end,fail

ml R

Rscript ~/ISPM_excess-mortality-spatial/analyses/.R
