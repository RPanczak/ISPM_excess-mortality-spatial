#!/bin/bash
#SBATCH --job-name="lme4 1"
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=2G
#SBATCH --time=00:10:00
#SBATCH --mail-user=radoslaw.panczak@ispm.unibe.ch
#SBATCH --mail-type=end,fail

ml R

Rscript ~/ISPM_excess-mortality-spatial/ubelix/test_lme4.R
