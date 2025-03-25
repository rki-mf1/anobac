import pandas as pd
import os
import argparse

def parseTSVs(inPath, outFile):
    all_filenames=[]
    for file in os.listdir(inPath):
        if file.endswith(".tsv") or file.endswith(".tab") or file.endswith(".txt"):
            all_filenames.append(inPath+"/"+file)

    combined_file = pd.concat([pd.read_csv(f,  sep='\t') for f in all_filenames])

    combined_file.to_csv(outFile+".csv")


def parseCSVs(inPath, outFile):
    all_filenames=[]
    for file in os.listdir(inPath):
        if file.endswith(".csv"):
            all_filenames.append(inPath+"/"+file)

    combined_file = pd.concat([pd.read_csv(f,  sep=',') for f in all_filenames])

    combined_file.to_csv(outFile+".csv")

######################################################################################

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Combine tsv files")
    parser.add_argument("--t", "-tsvPath", type=str, help="")
    parser.add_argument("--o", "-outfile", type=str, help="")
    parser.add_argument("--c", "-csv", type=str, help="enable if csv inputs", action='store_true')
    args = parser.parse_args()

    if args.c:
        parseCSVs(args.t, args.o)
    else:
        parseTSVs(args.t, args.o)