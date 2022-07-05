#!/bin/bash
#SBATCH --job-name="INLA AR iid"
#SBATCH --cpus-per-task=32
#SBATCH --mem-per-cpu=2G
#SBATCH --time=48:00:00
#SBATCH --mail-user=radoslaw.panczak@ispm.unibe.ch
#SBATCH --mail-type=end,fail

ml vital-it
ml R/3.6.1

Rscript ~/ISPM_geo-mortality/analyses/06-01_model-ar.R
