#!/usr/bin/env python

# TODO nf-core: Update the script to check the samplesheet
# This script is based on the example at: https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/samplesheet/samplesheet_test_illumina_amplicon.csv

import os
import sys
import errno
import argparse


def parse_args(args=None):
    Description = "Reformat nf-core/egatransfer samplesheet file and check its contents."
    Epilog = "Example usage: python check_samplesheet.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_IN", help="Input samplesheet file.")
    parser.add_argument("FILE_OUT", help="Output file.")
    return parser.parse_args(args)


def make_dir(path):
    if len(path) > 0:
        try:
            os.makedirs(path)
        except OSError as exception:
            if exception.errno != errno.EEXIST:
                raise exception


def print_error(error, context="Line", context_str=""):
    error_str = "ERROR: Please check samplesheet -> {}".format(error)
    if context != "" and context_str != "":
        error_str = "ERROR: Please check samplesheet -> {}\n{}: '{}'".format(
            error, context.strip(), context_str.strip()
        )
    print(error_str)
    sys.exit(1)


# TODO nf-core: Update the check_samplesheet function
def check_samplesheet(file_in, file_out):
    """
    This function checks that the samplesheet follows the following structure:

    sample,file
    SAMPLE,SAMPLE.ext

    For an example see:
    https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/samplesheet/samplesheet_test_illumina_amplicon.csv
    """

    sample_mapping_dict = {}
    with open(file_in, "r") as fin:

        ## Check header
        MIN_COLS = 2
        # TODO nf-core: Update the column names for the input samplesheet
        HEADER = ["sample","type","file" ]
        header = [x.strip('"') for x in fin.readline().strip().split(",")]
        if header[: len(HEADER)] != HEADER:
            print("ERROR: Please check samplesheet header -> {} != {}".format(",".join(header), ",".join(HEADER)))
            sys.exit(1)

        ## Check sample entries
        for line in fin:
            lspl = [x.strip().strip('"') for x in line.strip().split(",")]
            # print(lspl)
            # Check valid number of columns per row
            # print("Header length: " + str(len(HEADER)))
            if len(lspl) < len(HEADER):
                print_error(
                    "Invalid number of columns (minimum = {})!".format(len(HEADER)),
                    "Line",
                    line,
                )
            num_cols = len([x for x in lspl if x])
            if num_cols < MIN_COLS:
                print_error(
                    "Invalid number of populated columns (minimum = {})!".format(MIN_COLS),
                    "Line",
                    line,
                )

            ## Check sample name entries
            sample, _type, _files = lspl[: len(HEADER)]
            sample = sample.replace(" ", "_")
            # print("SAMPLE: " + sample)
            if not sample:
                print_error("Sample entry has not been specified!", "Line", line)

            ## Check file name
            for _file in [_files]:
                if _file.find(" ") != -1:
                    print_error("file contains spaces!", "Line", line)

            ## Auto-detect
            if sample and _type and _file : 
                sample_info = _type + "," + _file
                # print(sample_info)
            else:
                print_error("Invalid combination of columns provided!", "Line", line)

            if sample not in sample_mapping_dict:
                sample_mapping_dict[sample] = []
                sample_mapping_dict[sample].append(sample_info)
                # print(sample_mapping_dict[sample])
            else:
                if sample_info in sample_mapping_dict[sample]:
                    print_error("Samplesheet contains duplicate rows!", "Line", line)
                else:
                    sample_mapping_dict[sample].append(sample_info)

    ## Write validated samplesheet with appropriate columns
    if len(sample_mapping_dict) > 0:
        out_dir = os.path.dirname(file_out)
        make_dir(out_dir)
        with open(file_out, "w") as fout:
            fout.write(",".join(["sample","type","file"]) + "\n")
            for sample in sorted(sample_mapping_dict.keys()):
                # print("SAMPLE: " + sample)
                for _file in sample_mapping_dict[sample]:
                    # print("FILE: " + _file)
                    print(sample + "," + _file)
                    fout.write(sample + "," + _file + "\n")

    else:
        print_error("No entries to process!", "Samplesheet: {}".format(file_in))


def main(args=None):
    args = parse_args(args)
    check_samplesheet(args.FILE_IN, args.FILE_OUT)


if __name__ == "__main__":
    sys.exit(main())
