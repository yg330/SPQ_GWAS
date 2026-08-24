# slurm_scheduler.R
library(glue)

submit_slurm = function(
    account,
    job_name, 
    command, 
    time       = "1:00:00",     # HH:MM:SS, max 12:00:00 for SL3 or 36:00:00 for SL2
    mem        = "3G",       
    cpus       = 1, 
    home_dir   = ".",
    log_dir = ".",
    partition  = "sapphire",    # on sapphire partition
    array      = NULL,          # e.g. "1-22" for chromosome array job
    conda_env  = NULL,          # e.g. "FLAMES"
    conda_type = "conda",       # "conda", "microconda", or "micromamba"
    conda_path = NULL           # override default conda/micromamba install path
) {
  
  # -------------------------------------------------------
  # 1. Build conda/micromamba activation block
  # -------------------------------------------------------
  if (!is.null(conda_env)) {
    
    if (conda_type == "micromamba") {
      if (is.null(conda_path)) conda_path = "~/hpc-work/software_environments"
      
      # Warn if micromamba not found at given path
      mamba_exe = file.path(conda_path, "bin/micromamba")
      if (!file.exists(mamba_exe)) {
        warning(glue("micromamba not found at {mamba_exe}. Please specify the correct path using conda_path = '...'"))
      }
      
      conda_block = glue('
source /etc/profile.d/modules.sh
export MAMBA_EXE="{conda_path}/bin/micromamba"
export MAMBA_ROOT_PREFIX="{conda_path}/micromamba"
eval "$($MAMBA_EXE shell hook --shell bash)"
micromamba activate {conda_env}')
      
    } else if (conda_type == "microconda") {
      if (is.null(conda_path)) conda_path = "~/miniconda3"
      conda_block = glue('
source /etc/profile.d/modules.sh
source {conda_path}/etc/profile.d/conda.sh
conda activate {conda_env}')
      
    } else if (conda_type == "conda") {
      conda_block = glue('
source /etc/profile.d/modules.sh
eval "$(conda shell.bash hook)"
conda activate {conda_env}')
    }
    
  } else {
    conda_block = ""
  }
  
  # -------------------------------------------------------
  # 2. Build SLURM array and log directives
  #    - array jobs: log named as jobname_JOBID_ARRAYID.log
  #    - normal jobs: log named as jobname_JOBID.log
  # -------------------------------------------------------
  if (!is.null(array)) {
    array_line  = glue("#SBATCH -a {array}")
    output_line = glue("#SBATCH -o {log_dir}/{job_name}_%A_%a.log")
  } else {
    array_line  = ""
    output_line = glue("#SBATCH -o {log_dir}/{job_name}_%j.log")
  }
  
  # -------------------------------------------------------
  # 3. Assemble full SLURM script
  # -------------------------------------------------------
  slurm_script = glue('#!/bin/bash
#SBATCH -A {account}
#SBATCH -J {job_name}
#SBATCH -D {home_dir}
{output_line}
#SBATCH -t {time}
#SBATCH -p {partition}
#SBATCH --mem={mem}
#SBATCH --cpus-per-task={cpus}
#SBATCH --mail-type=ALL
{array_line}
{conda_block}

{command}
')
  
  # -------------------------------------------------------
  # 4. Write script to file and print submission command
  # -------------------------------------------------------
  script_path = file.path(log_dir, paste0(job_name, ".sh"))
  writeLines(slurm_script, script_path)
  cat("Script written to:", script_path, "\n")
  cat("To submit, run:\n")
  cat("  sbatch", script_path, "\n")
}