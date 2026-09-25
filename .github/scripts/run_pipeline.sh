#!/bin/bash

set -eo pipefail

sed -i 's/cpus = 8/cpus = 4/g' nextflow.config 

nextflow run main.nf \
	 -profile "${PROFILE}" \
     -c tests/test.config \
	 --outdir .github/data/test_output \
	 -with-report .github/data/test_output/nextflow_report.html \
 	 -with-trace .github/data/test_output/nextflow_trace.tsv \
     -with-timeline .github/data/test_output/nextflow_timeline.html

