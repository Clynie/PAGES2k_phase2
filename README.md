
# PAGES2k SD code
Matlab code for the PAGES2k synthesis of temperature-sensitive proxies, version 2.0.0.
Citation: PAGES2K Consortium (2017), A global multiproxy database for tempera- ture reconstructions of the Common Era, *Scientific Data*, 4, 170,088 EP, doi:10.1038/sdata.2017.88

The code and data herein allow to reproduce all PAGES2k-related figures from the main text and supplementary online material.
The code is provided "as is" and without warranty of running on your system. We welcome any and all feedback to make it run more smoothly.
To cite this code, use:
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.545815.svg)](https://doi.org/10.5281/zenodo.545815)

*Julien Emile-Geay, Nick McKay, Jianghao Wang & Kevin Anchukaitis (2017). CommonClimate/PAGES2k_phase2: First Public Release. Zenodo. http://doi.org/10.5281/zenodo.545815*

## Input data
the code needs the files [`PAGES2k_v2.0.0.mat`](https://ndownloader.figshare.com/files/8120039?private_link=d327a0367bb908a4c4f2) and [`had4med_graphem_sp70.mat`](https://ndownloader.figshare.com/files/8120138?private_link=d327a0367bb908a4c4f2) from the [FigShare repository](https://figshare.com/s/d327a0367bb908a4c4f2) in the **data/** directory. (or at least, an alias pointing to such files).

Some figures also require a few definitions from [JEG_graphics.mat](https://github.com/CommonClimate/common-climate/blob/master/JEG_graphics.mat)

## code_db directory

The code in this directory takes  `PAGES2k_v2.0.0.mat`, and `had4med_graphem_sp70.mat` and produces several synopsis plots, including all the quality control plots (Figs 4 and 5 of the main paper, as well as components of all the "QCfig_bundles" PDF files).
In most cases, additional visualizations are made if certain flags (visual, export) are set to 1 (TRUE).

The master code, **pages2k_db_workflow.m** calls the following components:

- **pages2k_db_unpack.m** unpacks the database, annualizes subannual data (mostly corals) and forms data matrices. if visual ==1, plots the visualizations in figs/annualize/

- **pages2k_db_synopsis.m** defines graphical attributes and makes a few synopsis plots (under figs)

- **pages2k_db_process.m** tests data for normality, applies inverse transform sampling to the data matrix `proxy`, so each column of `proxy_n` is distributed as a standard normal). If the flag InterpSuperAnn is set, the code also interpolates super-annual proxies to annual resolution. (proxy -> proxy_a, and proxy_n -> proxy_na)

- **pages2k_db_screen.m** carries out the record-based correlation analysis used in QC figures, as well as Fig 6a-c.
(NB: if nsim is large, this part of the code may take many hours to run, even on a decent computer. If its output file already exists in the data directory, this step will be skipped).

- **pages2k_grid_analysis.m** carries out the grid-based correlation analysis shown in Fig 6d.

- **pages2k_db_qc_plots.m** produces the QC figures, based on the saved output of **pages2k_db_screen.m**.

- **pages2k_db_prep** % exports all necessary matrices for subsequent analyses.

## Directory code_HadCRUT

- **HadCRUT4_prep.m** annualizes monthly HadCRUT4 data and generates Fig 3
- **HadCRUT4_seasonal.m** generates Fig S6

## Directory code_validation
This code assumes that **pages2k_db_workflow.m** has run to completion and produced a file called `pages2k_hadcrut4_(detrendFlag)_(normalizationFlag)_2.0.0.mat`, placed in the /data/ folder.

The master code, **pages2k_SD_workflow.m** is made up of the following pieces:

- **pages2k_SD_prep.m** prepares the data for analysis.
- **pages2k_SDmakeFig01** makes the components of Fig 01 (it needs to be assembled in Illustrator or a similar software to be publication-quality).
- **pages2k_SDmakeFig02_parts** maps the PASGES2k phase 2, M08 and PAGES2k phase 1 databases. The latter 2 form Fig 2.
- **pages2k_SDmakeFig06** assembles Fig 6 based on the parts computed in **pages2k_db_screen.m** and **pages2k_grid_analysis.m**
- **pages2k_composite_globalBins** creates global binned composites, makes Fig 7
- **pages2k_compositeByArchive**  stratification by archive type, makes Fig 8

In addition, a plain composite (see e.g. [this one](http://futureearth.org/blog/2017-jul-11/new-dataset-provides-most-complete-look-yet-climate-last-2000-years)) can be produced using  **pages2k_compositeSimple.m**

All the data are in "/data". All figures are exported to "/figs" (sometimes in subfolders thereof).
Code dependencies needed to run the above codes are included in "utilities". If you are missing anything, we will be happy to add it. To comply with the license, some third-party packages may need to be installed separately, and be visible in your path:

- [m_map](http://www.eos.ubc.ca/~rich/map.html)
- [export_fig](http://github.com/altmany/export_fig)
- [Brewermap](https://github.com/DrosteEffect/BrewerMap)
- [Perceptually Improved Colormaps](https://www.mathworks.com/matlabcentral/fileexchange/28982-perceptually-improved-colormaps)
- [CommonClimate](https://github.com/CommonClimate/common-climate)
- in current form, requires the "Statistics and Machine Learning" toolbox. We're happy to accept contributions that would make the code independent of this (expensive) toolboox. 
