#!/bin/bash
#SBATCH --job-name="INLA test"
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --time=00:30:00
#SBATCH --mail-user=radoslaw.panczak@ispm.unibe.ch
#SBATCH --mail-type=end,fail

ml vital-it
ml R/3.6.1
 
Rscript ~/ISPM_geo-mortality/ubelix/test.R
