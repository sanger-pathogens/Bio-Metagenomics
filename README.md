# Bio-Metagenomics
Runs metagenomics pipeline

[![Build Status](https://travis-ci.org/sanger-pathogens/Bio-Metagenomics.svg?branch=master)](https://travis-ci.org/sanger-pathogens/Bio-Metagenomics)   
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-brightgreen.svg)](https://github.com/sanger-pathogens/Bio-Metagenomics/blob/master/GPL-LICENCE)   

## Contents
  * [Introduction](#introduction)
  * [Installation](#installation)
    * [Required dependencies](#required-dependencies)
    * [From Source](#from-source)
    * [Running the tests](#running-the-tests)
  * [Usage](#usage)
    * [metagm\_build\_kraken\_db](#metagm_build_kraken_db)
    * [metagm\_convert\_fasta\_to\_kraken\_format \-\-help](#metagm_convert_fasta_to_kraken_format---help)
    * [metagm\_genbank\_downloader](#metagm_genbank_downloader)
    * [metagm\_make\_metaphlan\_heatmap](#metagm_make_metaphlan_heatmap)
    * [metagm\_run\_kraken](#metagm_run_kraken)
    * [metagm\_summarise\_kraken\_reports](#metagm_summarise_kraken_reports)
  * [License](#license)
  * [Feedback/Issues](#feedbackissues)

## Introduction
The following scripts are included:
* **metagm_build_kraken_db**    Create a new Kraken database in a new directory of the given name
* **metagm_convert_fasta_to_kraken_format**    Take in a FASTA file and convert it to a Kraken formated file
* **metagm_genbank_downloader**    Download FASTA files from genbank
* **metagm_make_metaphlan_heatmap**    Make a heatmap using Metaphlan scripts from kraken report files
* **metagm_run_kraken**    Run Kraken, a program for assigning taxonomic labels to metagenomic DNA sequences
* **metagm_summarise_kraken_reports**    Produce a summary from many kraken report files

## Installation
Bio-Metagenomics has the following dependencies:

### Required dependencies
* kraken
* kraken-build
* kraken-report
* merge_metaphlan_tables.py
* metaphlan_hclust_heatmap.py

Details for installing Bio-Metagenomics are provided below. If you encounter an issue when installing Bio-Metagenomics please contact your local system administrator. If you encounter a bug please log it [here](https://github.com/sanger-pathogens/Bio-Metagenomics/issues) or email us at path-help@sanger.ac.uk.

### From Source
Clone the repository:   
   
`git clone https://github.com/sanger-pathogens/Bio-Metagenomics.git`   
   
Move into the directory and install all dependencies using [DistZilla](http://dzil.org/):   
  
```
cd Bio-Metagenomics
dzil authordeps --missing | cpanm
dzil listdeps --missing | cpanm
```
  
Run the tests:   
  
`dzil test`   
If the tests pass, install Bio-Metagenomics:   
  
`dzil install`   

### Running the tests
The test can be run with dzil from the top level directory:  
  
`dzil test`  

## Usage
The following scripts are included in Bio-Metagenomics

### metagm_build_kraken_db 
```
metagm_build_kraken_db [options] <Output directory name>

Creates a new Kraken database in a new directory of the given name.

Options:

-h, -help
    Show this help and exit

-c, -csv_to_add
    Comma-separated file of genomes in FASTA files to add to the database.
    Each genome is added as a child of a user-specified NCBI taxon ID.
    File needs one line per genome with these three columns:
        1. Absolute path to FASTA file, can be gizpped (with .gz extension)
        2. Name of organism to appear in Kraken report file
        3. NCBI taxon ID that will be the parent of this genome

-csv_to_add_out
    If -c is used, then write a new csv file that is the same
    is the input csv, but with two new columns:
        4. Taxon ID given to sample
        5. GI number given to sample

-d, -dbs_to_download
    Kraken databases to download and add to the database. Must be one of:
        bacteria, viruses, human.
    This option can be used more than once if you want to
    download more than one. Default is to use all three.
    use -d NONE to not download any of these.

-downloaded
    Directory of gzipped FASTA files to use, that have already been
    downloaded using the script metagm_genbank_downloader. If you use
    this option, you must use at least one of -add_id or -ids_file.

-a, -add_id ID
    Add genbank record with ID to the database.  ID can be a genbank ID or a
    GI number.  This option can be used more than once to add as many
    genomes as you like.  See also -ids_file and -downloaded

-ids_file FILENAME
    Add IDs from file to the database.  Format is one line per ID.
    ID can be a genbank ID or a GI number.

-kraken_build FILENAME
    kraken-build executable [kraken-build]

-max_db_size INT
    Value used --max-db-size when running kraken-build [4]

-minimizer_len INT
    Value used --minimizer-len when running kraken-build [13]

-n, -noclean
    Do not clean up database afterwards. Default is to clean by running:
    kraken-build --clean

-t, -threads INT
    Number of threads [1]
```
### metagm_convert_fasta_to_kraken_format
```
metagm_convert_fasta_to_kraken_format [options] input_file.fa

Take in a FASTA file and convert it to a Kraken formated file.

Options:

-t, --taxon
    Taxon ID for the sequences. Defaults to 32630 (synthetic construct).

-o, --output_filename
    Output filename. Defaults to output_file.fa

-h, -help
    Show this help and exit
```
### metagm_genbank_downloader
```
metagm_genbank_downloader [options] <file of IDs to download> <Output directory name>

Downloads FASTA files from genbank.

The IDs file must have one ID per line.
Each ID must be a GenBank ID or a GI number.
If the ID starts with 'GCA_', then it is assumed to be an assembly ID and all
the corresponding contigs are downloaded and put into a single file.

Each FASTA file is gzipped and called ID.fasta.gz.
If that file already exists in the output
directory, then nothing new is downloaded for that ID.

Options:

-c, -cat_fastas
    For each assembly file, cat the sequences together, separated
    by a string Ns. Number of Ns specified by -cat_Ns. The result
    is a single sequence in the output FASTA file for each assembly.

-cat_Ns
    Number of Ns separating each sequence in an assembly
    FASTA, when -c/-cat_fastas is used [20]

-h, -help
    Show this help and exit
```
### metagm_make_metaphlan_heatmap
```
metagm_make_metaphlan_heatmap [options] <output_heatmap.png>

Makes a heatmap using Metaphlan scripts. Input is kraken report files.

Options:

-h,help
    Show this help and exit

-a,add_file FILENAME
    Use kraken report with FILENAME.
    This option can be used more than once to add as many files as you like.
    See also -names_file.

-f|names_file FILENAME
    Add filenames from file.  Format is one filename per line.

-hclust_heatmap_exec FILENAME
    metaphlan_hclust_heatmap.py executable [metaphlan_hclust_heatmap.py]

-hclust_heatmap_options "Options in quotes"
    Options to pass to metaphlan_hclust_heatmap.py. These are NOT sanity
    checked [-c bbcry --top 25 --minv 0.1 -s log]

-merge_metaphlan_tables_exec FILENAME
    merge_metaphlan_tables.py executable [merge_metaphlan_tables.py]
```
### metagm_run_kraken
```
metagm_run_kraken [options] <database dir> <out.report> <reads_1.fastq> [reads_2.fastq]

Runs Kraken, making report file. If a second file of reads is given, then they
are assumed to be mates of the first file and Kraken is run in --paired mode.

Options:

-h,help
    Show this help and exit

-keep_readnames
    Do not rename the sequences in input fastq file(s)
    (saves run time, but may break kraken)

-kraken_exec FILENAME
    kraken executable [kraken]

-kraken_report FILENAME
    kraken-report executable [kraken-report]

-n,-noclean
    Do not delete intermediate file made by Kraken

-preload
    Use the --preload option when running Kraken.

-t,-threads INT
    Number of threads [1]

-u,-tmp_file FILENAME
    Name of temporary file made when running kraken.
    (It's the output of kraken/input of kraken-report).
    This file is 1 line per read, so can be quite large.
    Default: <name_of_ouptput_report>.kraken_out
```
### metagm_summarise_kraken_reports
```
metagm_summarise_kraken_reports [options] <outfile> [list of kraken report filenames]

Produces a sumary from many kraken report files.

Report filenames must be given to this script, which can be done using
one or both of:
    1. list them after the name of the output file
    2. use the option -f to give a file of filenames.


Options:

-h,help
    Show this help and exit

-f,reports_fofn
    File of kraken report filenames

-l,level D|K|P|C|O|F|G|S|T
    Taxonomic level to output. Choose from:
      D (Domain), K (Kingdom) P (Phylum), C (Class), O (Order),
      F (Family), G (Genus), S (Species), T (Strain)
    Default: P

-c,counts
    Report counts of reads instead of percentages of the total reads in each
    file.

-a,assigned_directly
    Report reads assigned directly to this taxon, instead of the
    default of reporting reads covered by the clade rooted at this taxon.

-m,min_cutoff
    Cutoff minimum value in at least one report to include in output.
    Default: no cutoff.

-t,transpose
    Transpose output to have files in rows and matches in columns.
    Default is to have matches in rows and files in columns
```
## License
Bio-Metagenomics is free software, licensed under [GPLv3](https://github.com/sanger-pathogens/Bio-Metagenomics/blob/master/GPL-LICENCE).

## Feedback/Issues
Please report any issues to the [issues page](https://github.com/sanger-pathogens/Bio-Metagenomics/issues) or email path-help@sanger.ac.uk.