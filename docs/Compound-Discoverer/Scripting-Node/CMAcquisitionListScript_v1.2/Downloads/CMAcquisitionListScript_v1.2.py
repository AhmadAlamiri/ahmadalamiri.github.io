#===============================================================================
# Name      : CMAcquisitionListScript_v1.2.py
# Author    : Ahmad Alamiri
# Date      : 2025-05-12
# Modified  : 2025-05-15
# Version   : v1.2 (for Compound Discoverer 3.3 SP3, CD3.3.3, 3.4, CD3.4; Chromeleon 7.3.2; and Orbitrap Exploris GC Method Editor v4.1.3).
# Aim       : Compound Discoverer Scripting Node Python script used in GC EI Workflows to export data from Compound Discoverer as an "Acquisition List" ('Exploris Orbitrap LCMS and GCMS Family' format)
#             that can be used in a Chromeleon CDS Processing Method using the "Import Compound Data" feature.
#             The script also exports 'SIM Scan List' for Orbitrap Exploris GC Method Editor.
#             Both files are exported to the 'Download' directory.
#             The file names are as follows:
#             1. 'Exploris Acquisition List.csv'
#             2. 'Exploris SIM Scan List.csv'
#===============================================================================


#===============================================================================
# Revison History
# Previous Version      : v1.0
# Previous Version Date : 2025-04-25
# Current Version       : v1.1
# Current Version Date  : 2025-05-08
# Revision Notes        : Modified 'Checked' and 'Base Compound' entry values behavior.
#                         If 'Checked' columns contains any 'True' values and whose 'Base Compound' column value is also set to 'True', the 'Acquisition List' will only contain entries that meet this condition.
#                         If 'Checked' column does not contain any 'True' values or whose 'Base Compound' column value is not set to 'True', the 'Acquisition List' will contain all ('GC EI Compounds' table) entries.
#===============================================================================


#===============================================================================
# Revison History
# Previous Version      : v1.1
# Previous Version Date : 2025-05-08
# Current Version       : v1.2
# Current Version Date  : 2025-05-15
# Revision Notes        : Corrected Format 'Exploris Orbitrap LCMS and GCMS Family'. 
#                         Now, this script exports 'Acquisition List' to 'Exploris Orbitrap LCMS and GCMS Family' format (previous version formats were 'Exactive Orbitrap LCMS and GCMS Family').
#                         The script also exports 'SIM Scan List' for Orbitrap Exploris GC Method Editor v4.1.3.
#                         Both files are exported to the 'Download' directory.
#                         The file names are as follows:
#                         1. 'Exploris Acquisition List.csv'
#                         2. 'Exploris SIM Scan List.csv'
#===============================================================================


# DISCLAIMER
#==============================================================================
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
# IN THE SOFTWARE.
#
# For Research Use Only. Not for use in diagnostic procedures.
#
# BY DOWNLOADING OR USING ANY SOFTWARE, SCRIPTS, TEMPLATES, DOCUMENTATION AND/OR OTHER MATERIALS (COLLECTIVELY “MATERIALS”), YOU AND ANY COMPANY OR 
# INSTITUTION YOU REPRESENT (COLLECTIVELY “YOU”) ACKNOWLEDGE AND AGREE AS FOLLOWS: (1) THE MATERIALS ARE PROVIDED “AS IS” WITHOUT WARRANTY OF ANY KIND, 
# EXPRESS OR IMPLIED, AND (2) THERMO FISHER SCIENTIFIC INC., ITS AFFILIATES AND EMPLOYEES WILL NOT BE RESPONSIBLE FOR ANY DAMAGES ARISING FROM YOUR USE 
# OF THE MATERIALS, INCLUDING BUT NOT LIMITED TO DAMAGES ASSOCIATED WITH LOSS OR CORRUPTION OF DATA, INACCURATE RESULTS, AND/OR DIMINISHED INSTRUMENT PERFORMANCE.
#==============================================================================


# Load Libraries, Modules, and Packages.
import json    # JSON encoder and decoder.
import os    # Miscellaneous operating system interfaces.
import pandas as pd  # Pandas is a Python library for data analysis and manipulation.
import sys    # System-specific parameters and functions.
import csv # CSV reader and writer
from pathlib import Path # Object-oriented path class
import traceback    # Print or retrieve a stack traceback.
#==============================


# Define error and error handling function.
def print_error(*args, **kwargs):
    """
    Print an error message to the standard error stream.

    Parameters
    ----------
    *args : tuple
        The error message to print.
    **kwargs : dict
        Additional keyword arguments to pass to the print function.

    Returns
    -------
    None
    """
    print(*args, file = sys.stderr, **kwargs)
#==============================


# Define Main            
def main():
   print('CD Scripting Node - CM Acquisition List Script')
#==============================


# Read Command Line Arguments
# Read the Command Line arguments passed by Compound Discoverer upon initiation of the scripting node feature.
# We are only interested in the 2nd ([1]) argument, which contains the location of the would be newly-created 'node_args.json' file. 
# This file contains essential information about the exported data, including location(s) of the exported text files as well as the row IDs, columns, and column attributes of the exported tables.
# Define 'input_file' ('node_args.json' file) - located in the 2nd ([1]) argument of the variable 'argv'.
input_file = sys.argv[1]
#==============================


# Read 'node_args.json' file.
try:
    with open(input_file, mode='r') as f:
        node_args = json.load(f)
    print("Successfully read Compound Discoverer 'node_args.json' file!")

except Exception as e:
    print("Failed to read Compound Discoverer 'node_args.json' file: " + str(e))
    print(traceback.format_exc())
    exit(1)      
#==============================


# Verify Tables export.
# Parse 'node_args.json' file from Compound Discoverer and verify that the necessary tables have been exported.
# Define function to retrieve table names from the list of tables ('node_args['Tables']')
def get_table(table_list):
    """
    Retrieves table names and indexes from the list of tables ('node_args['Tables']').

    Parameters
    ----------
    table_list : list
        A list of dictionaries, where each dictionary represents a table and contains the keys 'TableName'
        and possibly other keys.

    Returns
    -------
    table_indexes : list
        A list of integers representing the indexes of the tables in the input list.
    table_names : list
        A list of strings representing the names of the tables in the input list.
    """
    table_indexes = []
    table_names = []
    for index in range(len(table_list)):
        table_index = index
        table_name = table_list[index]['TableName']
        table_indexes.append(table_index)
        table_names.append(table_name)
    return table_indexes, table_names

# Define required tables
required_tables = {0:"GC EI Compounds", 1:"GC EI Compounds per File", 2:"Features per File"}

# Retrieve table names from the list of tables ('node_args['Tables']')
try:
    table_indexes, table_names = get_table(node_args['Tables'])

    # Create a dictionary of exported tables.
    exported_tables = dict(zip(table_indexes, table_names))

    # Create a dictionary of requested tables.
    requested_tables = dict(list(exported_tables.items())[0:3])

    # Check for missing tables.
    missing_tables = [table for table in required_tables.values() if table not in table_names]
    if missing_tables:
        print(f"Error: The following required tables are missing: {', '.join(missing_tables)}")
        exit(1)
    else:
        print("All required tables are found.")

    # Check for correct order of tables.
    if list(requested_tables.items()) != list(required_tables.items()):
        print("Error: The order of requested tables is incorrect.")
        print(f"Expected tables order: {'; '.join(required_tables.values())}")
        print(f"Requested tables order: {'; '.join(requested_tables.values())}")
        exit(1)
    else:
        print("All requested tables are in the correct order.")

except Exception as e:
    print("Failed to verify tables: " + str(e))
    print(traceback.format_exc())
    exit(1)
#==============================


# Load Table(s)
# Read table(s) exported from Compound Discoverer. 
# Tables are exported as tab-separated text files. 

try:
    # Define new variable 'GCEI_Compounds_table' and read the 'GC EI Compounds' data into it.
    GCEI_Compounds_table = pd.read_table(node_args['Tables'][0]['DataFile'], header=0)

    # Define new variable 'GCEI_Compounds_per_File_table' and read the 'GC EI Compounds per File' data into it.
    GCEI_Compounds_per_File_table = pd.read_table(node_args['Tables'][1]['DataFile'], header=0)

    # Define new variable 'Features_per_File_table' and read the 'Features per File' data into it.
    Features_per_File_table = pd.read_table(node_args['Tables'][2]['DataFile'], header=0)

    # Define new variable 'Connection_Table_1' and read the 'ConsolidatedGCEICompoundItem-GCEICompoundInstanceItem' data into it.
    Connection_Table_1 = pd.read_table(node_args['Tables'][3]['DataFile'], header=0)

    # Define new variable 'Connection_Table_2' and read the 'GCEICompoundInstanceItem-GCCompoundIonInstanceItem' data into it.
    Connection_Table_2 = pd.read_table(node_args['Tables'][4]['DataFile'], header=0)
    #==============================

    # Modify 'GCEI_Compounds_table' table.
    # Rename columns: 'Checked' to 'Checked_1'.
    GCEI_Compounds_table.rename(columns={'Checked': 'Checked_1'}, inplace=True)
    #==============================


    # Modify 'GCEI_Compounds_per_File_table' table.
    # Rename columns: 'Checked' to 'Checked_2'.
    GCEI_Compounds_per_File_table.rename(columns={'Checked': 'Checked_2'}, inplace=True)
    #==============================


    # Modify 'Features_per_File_table' table.
    # Rename columns: 'Checked' to 'Checked_3', 'Measured mz' to 'm/z', 'Area' to 'Area [m/z]'.
    Features_per_File_table.rename(columns={'Checked': 'Checked_3', 'Measured mz': 'm/z', 'Area': 'Area [m/z]'}, inplace=True)
    #==============================


    # Create 'All_Tables' table by merging 'GCEI_Compounds_table' and 'Connection_Table_1' tables.
    # Merge 'GCEI_Compounds_table' table with 'Connection_Table_1' table (based on the occurrence/matching of 'GC EI Compounds ID' in both tables).
    All_Tables = pd.merge(GCEI_Compounds_table, Connection_Table_1, left_on='GC EI Compounds ID', right_on='GC EI Compounds ID', how='inner')
    #==============================


    # Modify 'All_Tables' table.
    # Merge 'GCEI_Compounds_table' table with 'GCEI_Compounds_per_File_table' table (based on the occurrence/matching of 'GC EI Compounds per File ID' in both tables).
    All_Tables = pd.merge(All_Tables, GCEI_Compounds_per_File_table, left_on='GC EI Compounds per File ID', right_on='GC EI Compounds per File ID', how='inner')

    # Merge 'All_Tables' table with 'Connection_Table_2' table (based on the occurrence/matching of 'GC EI Compounds per File ID' in both tables).
    All_Tables = pd.merge(All_Tables, Connection_Table_2, left_on='GC EI Compounds per File ID', right_on='GC EI Compounds per File ID', how='inner')

    # Merge 'All_Tables' table with 'Features_per_File_table' table (based on the occurrence/matching of 'Features per File ID' in both tables).
    All_Tables = pd.merge(All_Tables, Features_per_File_table, left_on='Features per File ID', right_on='Features per File ID', how='inner')
    #==============================


    # Clean 'All_Tables' table.
    # Drop duplicate/any columns (those that have suffixes '_x' and '_y').
    All_Tables = All_Tables.drop(columns=[col for col in All_Tables if col.endswith('_x') or col.endswith('_y')])
    #==============================


    # Create 'Acquisition List' table.
    # Create 'Acquisition List' table by filtering 'All_Tables' table based on 'Checked' column.
    # If 'Checked' column contains any 'True' values and whose 'Base Compound' column value is also set to 'True', filter only the 'All_Tables' entries that meet this condition.
    # If 'Checked' column does not contain any 'True' values or whose 'Base Compound' column value is not set to 'True', return a copy of 'All_Tables' table.
    try:
        if All_Tables['Checked_1'].any() & All_Tables['Checked_2'].any() & All_Tables['Checked_3'].any() & All_Tables['Base Compound'].any():
            Acquisition_List = All_Tables[(All_Tables['Checked_1'] == True) & (All_Tables['Checked_2'] == True) & (All_Tables['Checked_3'] == True) & (All_Tables['Base Compound'] == True)]
            if len(Acquisition_List) > 0:
                print("Creating 'Acquisition List' table using 'Checked' entries only.")
            else:
                Acquisition_List = All_Tables.copy()
                print("Creating 'Acquisition List' table using all entries.")
        else:
            Acquisition_List = All_Tables.copy()
            print("Creating 'Acquisition List' table using all entries.")
    except Exception as e:
        print_error(f"Failed to create 'Acquisition List' table: {str(e)}")
        print_error(traceback.format_exc())        
        exit(1)
    #==============================


    # Filter 'Acquisition List' table.
    # Filter 'Acquisition List' table by selecting only the table entries whose 'Base Compound' column value is set to 'True'.
    # Note: This step will remove any entries that do not have a base compound value set to true - even if the 'Checked' column is set to 'True'.
    Acquisition_List = Acquisition_List[Acquisition_List['Base Compound'] == True]

    # Filter 'Acquisition List' table while retrieving the top 3 entries for each compound based on the highest area of the compound's mass ions.
    # Sort 'Acquisition List' table based on 'Area [m/z]' in descending order and retrieve the top 3 entries for each compound.
    Acquisition_List = Acquisition_List.sort_values(by=['GC EI Compounds ID', 'Area [m/z]'], ascending=[True, False]).groupby('GC EI Compounds ID').head(3)

    # Subset the desired columns from the 'Acquisition List' table.
    Acquisition_List = Acquisition_List[['Name', 'NIST Lib Hit Formula', 'Reference RT in min', 'm/z']]
    #==============================


    # Modify 'Acquisition List' table.
    # Rename 'Acquisition List' table columns.
    Acquisition_List.rename(columns={'Name': 'Compound', 'NIST Lib Hit Formula': 'Formula', 'Reference RT in min': 'RT [min]'}, inplace=True)

    # Create additional columns and assign values as needed.
    # Create columns: 'Adduct', 'z', 'Polarity', 't start (min)', and 't stop (min)'.
    Acquisition_List = Acquisition_List.assign(**{'Adduct':'','z':'','t start (min)':'0','t stop (min)':'0','Polarity':'Positive'})

    # Assign values for the 't start (min)' and 't stop (min)' columns.
    # Use a value of '0.2' for the half peak width.
    for row in Acquisition_List:
        Acquisition_List['t start (min)'] = (Acquisition_List.get('RT [min]') - 0.2).round(3)
        Acquisition_List['t stop (min)'] = (Acquisition_List.get('RT [min]') + 0.2).round(3)

    # Modify columns 'Compound' and 'Formula'.
    # If the 'Compound' or 'Formula' value is only nan, the column will alter how the 'Acquisition List' file is read by 
    # Chromeleon. This may cause an undesired outcome. Therefore, nan values will be changed to 'Unknown'.
    # Change 'nan' values to 'Unknown'.
    Acquisition_List['Compound'] = Acquisition_List['Compound'].fillna('Unknown')
    Acquisition_List['Formula'] = Acquisition_List['Formula'].fillna('Unknown')

    # Modify 'Compound' column.
    # Identify triplicate entries that are repeated (e.g., entries such as 'Peak@2.019' and 'Peak@2.019').
    value_counts = Acquisition_List['Compound'].value_counts()
    repeated_triplicate_entries = value_counts[value_counts > 3].index

    # Add a suffix to 'Compound' column values to ensure that repeated identical triplicate entries are identifiable and unique.
    # Note: this is necessary to differentiate between repeated identical triplicate entries, such as 'Peak@2.019' and 'Peak@2.019'.
    # Without this command, Chromeleon will treat these entries as one compound and it would create additional MS Confirmation Peak values (instead of having multiple entries with the same number of MS ions, 3) 
    def add_suffix(group):        
        if len(group) > 3:
            suffix_number = 1
            for i in range(0, len(group), 3):
                group.iloc[i:i+3, group.columns.get_loc('Compound')] += f' ({suffix_number})'
                suffix_number += 1
        return group

    Acquisition_List = Acquisition_List.groupby('Compound', group_keys=False)[['Compound','Formula','Adduct', 'm/z', 'z','t start (min)','t stop (min)', 'Polarity']].apply(add_suffix)

    # Create 'Exploris Acquisition List' table.
    Exploris_Acquisition_List = Acquisition_List.copy()

    # Create 'Exploris SIM Scan' table.
    # Replace all 'Formula' column entries with empty string ('').
    Exploris_SIM_Scan_List = Acquisition_List.copy()
    Exploris_SIM_Scan_List['Formula'] = ''

except Exception as e:
    print_error('Could not process data.')
    print_error(e)
    print(traceback.format_exc())        
    exit(1)
#==============================


# Write files to 'Downloads' directory.
workdir = str(Path.home() / "Downloads")    # This file will be written to the 'Downloads' directory ("C:\Users\[user.name]\Downloads").

# Write 'Exploris Acquisition List' data file.
outfilename_AL = 'Exploris Acquisition List.csv'
outfile_path_AL = os.path.join(workdir, outfilename_AL)

try:
    with open(outfile_path_AL, mode = 'w', newline = '', encoding = "utf-8") as AL:
        fieldnames = Exploris_Acquisition_List.columns.tolist()  
        writer = csv.DictWriter(AL, fieldnames = fieldnames)
        writer.writeheader()
        
        for index, column in Exploris_Acquisition_List.iterrows():
            writer.writerow({'Compound': column.iloc[0], 'Formula': column.iloc[1], 'Adduct': column.iloc[2], 'm/z': column.iloc[3], 'z': column.iloc[4], 't start (min)': column.iloc[5], 't stop (min)': column.iloc[6], 'Polarity': column.iloc[7]})
    print("'Exploris Acquisition List' data file saved to location: " + outfile_path_AL)

except Exception as e:
    print_error(f"Failed to write 'Exploris Acquisition List' data file: {str(e)}")
    print_error(traceback.format_exc())        
    exit(1)

# Write 'Exploris SIM Scan List' data file.
outfilename_SSL = 'Exploris SIM Scan List.csv'
outfile_path_SSL = os.path.join(workdir, outfilename_SSL)

try:
    with open(outfile_path_SSL, mode = 'w', newline = '', encoding = "utf-8") as SSL:
        fieldnames = Exploris_SIM_Scan_List.columns.tolist()  
        writer = csv.DictWriter(SSL, fieldnames = fieldnames)
        writer.writeheader()
        
        for index, column in Exploris_SIM_Scan_List.iterrows():
            writer.writerow({'Compound': column.iloc[0], 'Formula': column.iloc[1], 'Adduct': column.iloc[2], 'm/z': column.iloc[3], 'z': column.iloc[4], 't start (min)': column.iloc[5], 't stop (min)': column.iloc[6], 'Polarity': column.iloc[7]})
    print("'Exploris SIM Scan List' data file saved to location: " + outfile_path_SSL)

except Exception as e:
    print_error(f"Failed to write 'Exploris SIM Scan List' data file: {str(e)}")
    print_error(traceback.format_exc())        
    exit(1)
#==============================


# Print completion message.
print("Successfully exported 'Exploris Acquisition List' and 'Exploris SIM Scan List' data files!")
#==============================


# Exit script.
if __name__== "__main__" :
    main()
#==============================