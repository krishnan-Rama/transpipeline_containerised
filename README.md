# 🧬 transFlow 👩🏻‍💻
A SLURM pipeline designed for comprehensive transcriptome analysis, including quality assessment, pre-processing, _de novo_ assembly, and functional annotation. This pipeline is optimised explicitly for deployment on high-performance computing (HPC) clusters and executed _via_ Slurm Workload Manager.

The **NextFlow version** of this pipeline is available at https://github.com/krishnan-Rama/transFlow, which offers improved system compatibility and efficiency (although limited features).

---
## Key Features

- **Transcriptome Quality Assessment**: Ensures high-quality data processing with integrated quality checks.
- **Pre-processing**: Streamlines the handling of RNA-seq data to prepare for assembly.
- **De Novo Assembly**: Assembles transcripts from RNA-seq data without the need for a reference genome.
- **Functional Annotation**: Annotates assembled transcripts to provide insights into gene function and expression.
- **HPC Optimization**: Designed to efficiently utilize HPC resources for scalable and fast transcriptome analysis.


## Installation

1. Install the transpipeline resources into your HPC cluster directory in which you will be performing the assembly:  

```bash
git clone https://github.com/krishnan-Rama/transpipeline_containerised.git
```

2. Put the raw reads in `raw_data` folder.  

3. Run the pipeline using `./deploy.sh`  

4. The prompt will ask you to (1) enter your preferred HPC partition name to submit the job and (2) the species/project identifier (e.g. Hsap or Hsap_200524 for _Homo sapiens_), simply type the name and return (it doesn't really matter).

> **Note:** 
>- You can run the pipeline multiple times simultaneously with different raw reads, simply repeat the installation process in a different directory and `./deploy` with a different species/project identifier name.
>- You can manually reconfigure Slurm parameters as per your HPC system (e.g memory, CPUs) by going through indivudal scripts in `modules` directory.  
>- All the relevent outputs will be stored in `outdir` folder, and outputs for every individual steps in the pipeline can be found in `workdir`.
---

## Differential gene expression analysis and visualisation
- To generate **PCR/heatmap plots** for differential gene expression data, modify the `metadata.txt` (example provided) file in the current directory as per the processed trimmed reads names `(workdir/trim_files/)`.

## Using blobtools to analyse and visualize transcriptome assemblies
- Run `./deploy_blobtools.sh`
- The prompt will ask you to type HPC partition name, Project identifier, and Taxonomic Id of the organism.
- Open the log file in `workdir/log/blobviewer.out` and follow the instructions to view assembly analysis and quality on your browser. 


## 🧬 MIExplorer

MIExplorer is a lightweight Python-based tool for exploring and visualizing drug-target interactions based on transcriptomic annotation data. It supports filtering by drug, tissue, or UniProt entry, and generates ranked sensitivity metrics and interactive network plots.

>### Key Features
>
>- Filter by drug, tissue, or UniProt entry ID
>- Rank tissue-specific gene expressions (sensitivity)
>- Visualize drug-target networks interactively
>- Works directly with merged annotation CSVs

---

### Execution

```bash
cd ./modules/MIExplorer
python g2mie.py --help
````

### Example

```bash
python g2mie.py -entry Q9Y6M5 -rank -network
```

### Inputs

* `Drug_targets_tool.csv`: Drug-target mapping file
* `*_combined_final.csv`: Final annotation + expression file (from `outdir/merged_data/`)

> 📦 Copy the final annotation file from:
>
> ```bash
> ./outdir/merged_data/*.csv
> ```
>
> into `MIExplorer` directory before running.

### Outputs

* Ranked and filtered CSV files
* Gene count distribution plots (`.png`)
* Interactive network (`Drug_Target_Network.html`)

---
## 🖧 Database query `query_gene_data.py` (All results compiled)
The transpipeline finishes with- gene id, transcript id, blast and annotations with expression data compiled into a database `final_data.db` for a more user-friendly and efficient querying the RNA-seq data analysis and avoiding large spreadsheets. 

The program **`query_gene_data.py`** in `modules` directory can be used to query data. Simply execute below code to display querying arguments available:
```bash
python modules/query_gene_data.py --db ../workdir/database/final_data.db --help
```
Available displayed arguments:

usage: 
```bash
python ./modules/query_gene_data.py --db ./workdir/database/final_data.db [-h] [--csv CSV] [--species SPECIES] [--geneid GENEID] [--transcriptid TRANSCRIPTID] [--entry ENTRY] [--e_value E_VALUE] [--interpro INTERPRO] [--entry.name ENTRY.NAME]
                          [--gene.names GENE.NAMES] [--panther PANTHER] [--taxonomic.lineage..species. TAXONOMIC.LINEAGE..SPECIES.] [--tissue TISSUE] [--isoform_count ISOFORM_COUNT]
                          [--gene_count GENE_COUNT]
```

| **Argument**                | **Description**                                                                                     |
|-----------------------------|-----------------------------------------------------------------------------------------------------|
| `-h`                | Show the `help` message and exit.                                                                    |
| `--csv`                 | Path to the CSV file to create the database (if the database doesn't exist).                        |
| `--db`                   | Path to the SQLite database file (default: `final_data.db`).                                        |
| `--species`         | Filter by species (e.g., `Hsap`, `Mmus`, `Dmel`, `Cele`, `Scer`, `sprot`, or `all`).               |
| `--geneid`           | Filter by `GeneID`.                                                                                |
| `--transcriptid` | Filter by `TranscriptID`.                                                                         |
| `--entry`             | Filter by `Entry`.                                                                                 |
| `--e_value`         | Filter by `E_value`.                                                                               |
| `--interpro`       | Filter by `InterPro`.                                                                              |
| `--entry.name`   | Filter by `Entry.Name`.                                                                            |
| `--gene.names`   | Filter by `Gene.Names`.                                                                            |
| `--panther`         | Filter by `PANTHER`.                                                                               |
| `--tissue`           | Filter by `Tissue`.                                                                                |
| `--isoform_count` | Filter by `Isoform_Count`.                                                                     |
| `--gene_count`   | Filter by `Gene_Count`.                                                                            |

---
## Final results spreadsheet (Results in a .csv file)
The gene id, transcript id, blast and annotations with expression data compiled into a spreadsheet is also available in the locations:
`transpipeline_containerised/workdir/mergedir/*_combined_final.csv` or `transpipeline_containerised/outdir/merged_data/*_combined_final.csv`

---  
### Workflow Diagram
![workflow](https://github.com/krishnan-Rama/transpipeline_containerised/assets/104147619/892ae381-69b3-45e8-a485-ccd50cf1794a)


### Concluding Note

To successfully run this pipeline, ensure that SLURM parameters in the scripts in `${module}` directory are properly configured for your system. Refer to individual bash scripts and the configuration file for more detailed information or to modify specific behaviours of the pipeline.

### Author Information

Rama Krishnan - krishnanr1@cardiff.ac.uk
