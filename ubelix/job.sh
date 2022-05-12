#!/bin/bash
#SBATCH --job-name="INLA AR iid"
#SBATCH --cpus-per-task=32
#SBATCH --mem-per-cpu=2G
#SBATCH --time=48:00:00
#SBATCH --mail-user=r.panczak@gmail.com
#SBATCH --mail-type=end,fail

module load R 
Rscript ~/ISPM_geo-mortality/analyses/06-01_model-ar.R
