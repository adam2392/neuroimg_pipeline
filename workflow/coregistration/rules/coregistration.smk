"""
======================================================
03. Coregistration (FSL-Flirt) from CT to T1 MRI
======================================================

This pipeline depends on the following functions:

    * flirt
    * mri_convert

from FreeSurfer6+, FSL.
"""

import os
import sys
from pathlib import Path

from mne_bids import BIDSPath

sys.path.append("../../../")
from seek.utils.fileutils import (BidsRoot, BIDS_ROOT, _get_seek_config,
                                  _get_bids_basename, _get_ct_bids_dir,
                                  _get_anat_bids_dir)

configfile: _get_seek_config()

freesurfer_dockerurl = config['freesurfer_docker']
fsl_dockerurl = config['fsl_docker']
seek_dockerurl = config['seek_docker']

# get the freesurfer patient directory
subject_wildcard = "{subject}"
bids_root = BidsRoot(subject_wildcard,BIDS_ROOT(config['bids_root']),
    site_id=config['site_id'],subject_wildcard=subject_wildcard)

# initialize directories that we access in this snakemake
FS_DIR = bids_root.freesurfer_dir
FSPATIENT_SUBJECT_DIR = bids_root.get_freesurfer_patient_dir()
FSOUT_MRI_FOLDER = Path(FSPATIENT_SUBJECT_DIR) / "mri"
FSOUT_CT_FOLDER = Path(FSPATIENT_SUBJECT_DIR) / "CT"

BIDS_PRESURG_ANAT_DIR = _get_anat_bids_dir(bids_root.bids_root,subject_wildcard,session='presurgery')
BIDS_PRESURG_CT_DIR = _get_ct_bids_dir(bids_root.bids_root,subject_wildcard,session='presurgery')
ct_bids_fname = _get_bids_basename(subject_wildcard,session='presurgery',
    imgtype='CT',space='orig',ext='nii')

# MRI that FS uses
premri_fs_bids_fname = _get_bids_basename(subject_wildcard,session='presurgery',
    space='fs',imgtype='T1w',ext='nii')
t1_fs_fpath = os.path.join(BIDS_PRESURG_ANAT_DIR,premri_fs_bids_fname)

# CT mapped to FS in BIDs folders
ctint1_fs_bids_fname = _get_bids_basename(subject_wildcard,
    session='presurgery',
    space='fs',
    imgtype='CT',ext='nii')

from_id = 'CT'  # post implant CT
to_id = 'fs'  # freesurfer's T1w
kind = 'xfm'
ct_to_t1wfs_transform_fname = BIDSPath(subject=subject_wildcard,
    session='presurgery',
    space='fs').basename + \
                              f"_from-{from_id}_to-{to_id}_mode-image_{kind}.mat"
ct_tot1_fs_output = os.path.join(BIDS_PRESURG_CT_DIR,ctint1_fs_bids_fname)
ct_tot1_fs_map = os.path.join(BIDS_PRESURG_CT_DIR,ct_to_t1wfs_transform_fname)

logger.debug('In coregistration workflow.')

subworkflow prep_localization_workflow:
    workdir:
        "../prep_localization/"
    snakefile:
        "../prep_localization/Snakefile"
    configfile:
        _get_seek_config()

subworkflow reconstruction_workflow:
    workdir:
        "../recon/"
    snakefile:
        "../recon/Snakefile"
    configfile:
        _get_seek_config()

# First rule
rule coregister_ct_and_T1w_images:
    input:
        # FLIRT FSL OUTPUT COREGISTRATION
        CT_IN_T1_NIFTI_IMG_ORIG=expand(os.path.join(FSOUT_CT_FOLDER,ctint1_fs_bids_fname),subject=subjects),
        # mapping matrix for CT to T1
        MAPPING_FILE=expand(os.path.join(FSOUT_CT_FOLDER,ct_to_t1wfs_transform_fname),
            subject=subjects),
        # MAPPED BRAIN MASK TO CT SPACE
        brainmask_inct_file=expand(os.path.join(FSOUT_CT_FOLDER,"brainmask_inct.nii.gz"),
            subject=subjects),
        ct_in_fs_img=expand(ct_tot1_fs_output,subject=subjects),
        ct_in_fs_map=expand(ct_tot1_fs_map,subject=subjects),
    container:
        seek_dockerurl
    log:
        expand("logs/coregistration.{subject}.log",subject=subjects)
    output:
        report=report('figct.png',caption='report/figprep.rst',category='Coregistration')
    shell:
        "echo 'done';"
        "touch figct.png {output};"

rule prep_ct_for_coregistration:
    input:
        CT_NIFTI_IMG=prep_localization_workflow(os.path.join(BIDS_PRESURG_CT_DIR,ct_bids_fname)),
    log: "logs/coregistration.{subject}.log"
    container:
        freesurfer_dockerurl
    output:
        CT_NIFTI_IMG=os.path.join(FSOUT_CT_FOLDER,ct_bids_fname),
    shell:
        "mri_convert {input.CT_NIFTI_IMG} {output.CT_NIFTI_IMG};"

"""
Rule for coregistering .nifit images -> .nifti for T1 space using Flirt in FSL.

E.g. useful for CT, and DTI images to be coregistered
"""

rule coregister_ct_to_t1wfs:
    input:
        PREMRI_NIFTI_IMG_MGZ=reconstruction_workflow(t1_fs_fpath),
        CT_NIFTI_IMG_MGZ=os.path.join(FSOUT_CT_FOLDER,ct_bids_fname),
    log: "logs/coregistration.{subject}.log"
    container:
        fsl_dockerurl
    output:
        # mapped image from CT -> MRI
        CT_IN_PRE_NIFTI_IMG_ORIGgz=(FSOUT_CT_FOLDER / ctint1_fs_bids_fname).with_suffix(".gz").as_posix(),
        # mapping matrix for post to pre in T1
        MAPPING_FILE_ORIG=os.path.join(FSOUT_CT_FOLDER,ct_to_t1wfs_transform_fname),
        ct_tot1_fs_map=ct_tot1_fs_map,
    shell:
        "flirt -in {input.CT_NIFTI_IMG_MGZ} \
                            -ref {input.PREMRI_NIFTI_IMG_MGZ} \
                            -omat {output.MAPPING_FILE_ORIG} \
                            -out {output.CT_IN_PRE_NIFTI_IMG_ORIGgz};"
        "cp {output.MAPPING_FILE_ORIG} {output.ct_tot1_fs_map};"

rule convert_ctgz_to_nifti:
    input:
        CT_IN_PRE_NIFTI_IMG_ORIGgz=(FSOUT_CT_FOLDER / ctint1_fs_bids_fname).with_suffix(".gz").as_posix(),
    log: "logs/coregistration.{subject}.log"
    container:
        freesurfer_dockerurl
    output:
        CT_IN_PRE_NIFTI_IMG=os.path.join(FSOUT_CT_FOLDER,ctint1_fs_bids_fname),
        ct_tot1_fs_output=ct_tot1_fs_output,
    shell:
        "mrconvert {input.CT_IN_PRE_NIFTI_IMG_ORIGgz} {output.CT_IN_PRE_NIFTI_IMG};"
        "cp {output.CT_IN_PRE_NIFTI_IMG} {output.ct_tot1_fs_output};"

"""
Rule to map the brain mask over to the CT space.
"""

rule map_brainmask_to_ct:
    input:
        brainmask_file=os.path.join(FSOUT_MRI_FOLDER,"brainmask.nii.gz"),
        CT_NIFTI_IMG=os.path.join(FSOUT_CT_FOLDER,ct_bids_fname),
        # mapping matrix for post to pre in T1
        MAPPING_FILE_ORIG=os.path.join(FSOUT_CT_FOLDER,ct_to_t1wfs_transform_fname),
    log: "logs/coregistration.{subject}.log"
    container:
        fsl_dockerurl
    output:
        # mapping matrix for post to pre in T1
        brainmask_inct_file=os.path.join(FSOUT_CT_FOLDER,"brainmask_inct.nii.gz"),
    shell:
        "flirt -in {input.brainmask_file} \
                            -ref {input.CT_NIFTI_IMG} \
                            -applyxfm -init {input.MAPPING_FILE_ORIG} \
                            -out {output.brainmask_inct_file};"
