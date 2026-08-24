#!/bin/bash
#SBATCH -A INPUT_USER_ACCOUNT_NAME
#SBATCH -J YG_SPQ_GWAS
#SBATCH -D /rds/user/yg330/rds-genetics_hpc-Nl99R8pHODQ/UKB/SPQ/SPQ_pre_GWAS
#SBATCH -o /rds/user/yg330/rds-genetics_hpc-Nl99R8pHODQ/UKB/SPQ/SPQ_GWAS/YG_SPQ_GWAS_%A_%a.log
#SBATCH -t 8:00:00
#SBATCH -p sapphire
#SBATCH --mem=100G
#SBATCH --cpus-per-task=1
#SBATCH --mail-type=ALL
#SBATCH -a 1-12


COLNAME=$(awk -v col="$SLURM_ARRAY_TASK_ID" 'NR==1{print $(col+2)}' UKB_SPQ_pheno.txt)
/rds/user/yg330/rds-genetics_hpc-Nl99R8pHODQ/toolbox/gcta/gcta64 --fastGWA-mlm --mbfile UKB_SPQ_GWAS_mbfile.txt --grm-sparse /rds/user/yg330/rds-genetics_hpc-Nl99R8pHODQ/UKB/GRM/UKB_AQ_GRM_SPARSE --pheno UKB_SPQ_pheno.txt --mpheno $SLURM_ARRAY_TASK_ID --qcovar UKB_SPQ_qCOVAR.txt --covar UKB_SPQ_COVAR.txt --out /rds/user/yg330/rds-genetics_hpc-Nl99R8pHODQ/UKB/SPQ/SPQ_GWAS/GWAS_$COLNAME
