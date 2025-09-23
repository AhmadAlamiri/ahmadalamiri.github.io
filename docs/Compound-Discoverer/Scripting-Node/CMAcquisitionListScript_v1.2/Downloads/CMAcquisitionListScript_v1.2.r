#===============================================================================
# Name      : CMAcquisitionListScript
# Author    : Ahmad Alamiri
# Date      : 2025-05-12
# Modified  : 2025-05-15
# Version   : v1.2 (for Compound Discoverer 3.3 SP3, CD3.3.3, 3.4, CD3.4; and Chromeleon 7.3.2; and Orbitrap Exploris GC Method Editor v4.1.3)
# Aim       : Compound Discoverer Scripting Node R script used in GC EI Workflows to export data from Compound Discoverer as an "Acquisition List" ('Exploris Orbitrap LCMS and GCMS Family' format) 
#             that can be used in a Chromeleon CDS Processing Method using the "Import Compound Data" feature. 
#             The script also exports 'SIM Scan List' for Orbitrap Exploris GC Method Editor v4.1.3.
#             Both files are exported to the 'Download' directory.
#             The file names are as follows:
#             1. 'Exploris Acquisition List.csv'
#             2. 'Exploris SIM Scan List.csv'
#             This script selects up to the top 3 m/z ions (ranked by decreasing order of ion area counts) for each compound.
#             --- Using (mostly) Base R ---
#===============================================================================


#===============================================================================
# Revison History
# Previous Version      : v1.0
# Previous Version Date : 2025-05-06
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
library(rjson)
#==============================


# Read Command Line Arguments
# Read the Command Line arguments passed by Compound Discoverer upon initiation of the scripting node feature.
# This file contains essential information about the exported data, including location(s) of the exported text files as well as the row IDs, columns, and column attributes of the exported tables.
args <- commandArgs()

# We are only interested in the 6th ([6]) argument, which contains the location of the would be newly-created 'node_args.json' file. 
# Define 'input_file' ('node_args.json' file) - located in the 6th ([6]) argument of the variable 'args'.
input_file <- args[6]
#==============================


# Read 'node_args.json' file.
node_args <- fromJSON(file = input_file)
#==============================


# Verify Tables export.
# Parse 'node_args.json' file from Compound Discoverer and verify that the necessary tables have been exported.
# Define function to retrieve table names and indexes from the list of tables ('node_args$Tables').
get_table <- function(table_list) {
  #
  # Retrieves table names and indexes from the list of tables ('node_args$Tables').
  #
  # Parameters
  # ----------
  # table_list : list
  #     A list of tables and their respective indexes.
  #
  # Returns
  # -------
  # table_indexes : list
  #     A list of integers representing the indexes of the tables in the input list.
  # table_names : list
  #     A list of strings representing the names of the tables in the input list.
  
  table_indexes <- c()
  table_names <- c()
  for (index in seq_along(table_list)) {
    table_index <- index
    table_name <- table_list[[index]]$TableName
    table_indexes <- c(table_indexes, table_index)
    table_names <- c(table_names, table_name)
    CD_tables <- list(table_indexes, table_names)
  }
  return(list(CD_tables))
}

# Define required tables
required_tables <- c("GC EI Compounds", "GC EI Compounds per File", "Features per File")

# Retrieve table names from the list of tables ('node_args$Tables')
CD_tables <- get_table(node_args$Tables)

# Create a list of exported tables.
exported_tables <- CD_tables[[1]][[2]]

# Create a list of requested tables.
requested_tables <- exported_tables[1:3]

# Check for missing tables.
missing_tables <- required_tables[!(required_tables %in% exported_tables)]
if (length(missing_tables) > 0) {
  cat(paste("Error: The following required tables are missing: ", paste(missing_tables, collapse = ", ")))
  cat("\n")
  quit(status = 1)
} else {
  cat("All required tables are found.\n")
}

# Check for correct order of tables.
if (!identical(requested_tables, required_tables)) {
  cat("Error: The order of requested tables is incorrect.\n")
  cat(paste("Expected tables order: ", paste(required_tables, collapse = ", ")))
  cat("\n")
  cat(paste("Requested tables order: ", paste(requested_tables, collapse = ", ")))
  cat("\n")
  quit(status = 1)
} else {
  cat("All requested tables are in the correct order.\n")
}
#==============================


# Load Table(s)
# Read table(s) exported from Compound Discoverer. 
# Tables are exported as tab-separated text files. 
# Define new variable 'GCEI_Compounds_table' and read the 'GC EI Compounds' data into it.
GCEI_Compounds_table <- read.table(node_args$Tables[[1]]$DataFile, header = TRUE, check.names = FALSE, stringsAsFactors = FALSE)

# Define new variable 'GCEI_Compounds_per_File_table' and read the 'GC EI Compounds per File' data into it.
GCEI_Compounds_per_File_table <- read.table(node_args$Tables[[2]]$DataFile, header = TRUE, check.names = FALSE, stringsAsFactors = FALSE)

# Define new variable 'Features_per_File_table' and read the 'Features per File' data into it.
Features_per_File_table <- read.table(node_args$Tables[[3]]$DataFile, header = TRUE, check.names = FALSE, stringsAsFactors = FALSE)

# Define new variable 'Connection_Table_1' and read the 'ConsolidatedGCEICompoundItem-GCEICompoundInstanceItem' data into it.
Connection_Table_1 <- read.table(node_args$Tables[[4]]$DataFile, header = TRUE, check.names = FALSE, stringsAsFactors = FALSE)

# Define new variable 'Connection_Table_2' and read the 'GCEICompoundInstanceItem-GCCompoundIonInstanceItem' data into it.
Connection_Table_2 <- read.table(node_args$Tables[[5]]$DataFile, header = TRUE, check.names = FALSE, stringsAsFactors = FALSE)
#==============================


# Modify 'GCEI_Compounds_table' table.
# Rename columns: 'Checked' to 'Checked_1'.
names(GCEI_Compounds_table)[names(GCEI_Compounds_table) == "Checked"] <- "Checked_1"
#==============================


# Modify 'GCEI_Compounds_per_File_table' table.
# Rename columns: 'Checked' to 'Checked_2'.
names(GCEI_Compounds_per_File_table)[names(GCEI_Compounds_per_File_table) == "Checked"] <- "Checked_2"
#==============================


# Modify 'Features_per_File_table' table.
# Rename columns: 'Checked' to 'Checked_3', 'Measured mz' to 'm/z', 'Area' to 'Area [m/z]'.
names(Features_per_File_table)[names(Features_per_File_table) == "Checked"] <- "Checked_3"
names(Features_per_File_table)[names(Features_per_File_table) == "Measured mz"] <- "m/z"
names(Features_per_File_table)[names(Features_per_File_table) == "Area"] <- "Area [m/z]"
#==============================


# Create 'All_Tables' table by merging 'GCEI_Compounds_table' and 'Connection_Table_1' tables.
# Merge 'GCEI_Compounds_table' table with 'Connection_Table_1' table (based on the occurrence/matching of 'GC EI Compounds ID' in both tables).
All_Tables <- merge(GCEI_Compounds_table, Connection_Table_1, by = "GC EI Compounds ID", all = TRUE)
#==============================


# Modify 'All_Tables' table.
# Merge 'GCEI_Compounds_table' table with 'GCEI_Compounds_per_File_table' table (based on the occurrence/matching of 'GC EI Compounds per File ID' in both tables).
All_Tables <- merge(All_Tables, GCEI_Compounds_per_File_table, by = "GC EI Compounds per File ID", all = TRUE)

# Merge 'All_Tables' table with 'Connection_Table_2' table (based on the occurrence/matching of 'GC EI Compounds per File ID' in both tables).
All_Tables <- merge(All_Tables, Connection_Table_2, by = "GC EI Compounds per File ID", all = TRUE)

# Merge 'All_Tables' table with 'Features_per_File_table' table (based on the occurrence/matching of 'Features per File ID' in both tables).
All_Tables <- merge(All_Tables, Features_per_File_table, by = "Features per File ID", all = TRUE)
#==============================


# Clean 'All_Tables' table.
# Drop duplicate/any columns (those that have suffixes '.x' and '.y').
All_Tables <- All_Tables[, !grepl("\\.x$|\\.y$", names(All_Tables))]

# Replace all NA entries with empty strings ("").
All_Tables[is.na(All_Tables)] <- ""
#==============================


# Create 'Acquisition List' table.
# Create 'Acquisition List' table by filtering 'All_Tables' table based on 'Checked' column.
# If 'Checked' column contains any 'True' values and whose 'Base Compound' column value is also set to 'True', filter only the 'All_Tables' entries that meet this condition.
# If 'Checked' column does not contain any 'True' values or whose 'Base Compound' column value is not set to 'True', return a copy of 'All_Tables' table.
if (any(All_Tables$Checked_1 == "True") & any(All_Tables$Checked_2 == "True") & any(All_Tables$Checked_3 == "True") & any(All_Tables$'Base Compound' == "True")) {
  Acquisition_List <- All_Tables[(All_Tables$Checked_1 == "True") & (All_Tables$Checked_2 == "True") & (All_Tables$Checked_3 == "True") & (All_Tables$'Base Compound' == "True"), ]
  if (nrow(Acquisition_List) > 0) {
    Acquisition_List <- Acquisition_List
    cat("Creating 'Acquisition List' table using 'Checked' entries only.\n")
  } else {
    Acquisition_List <- All_Tables
    cat("Creating 'Acquisition List' table using all entries.\n")
  }
} else {
  Acquisition_List <- All_Tables
  cat("Creating 'Acquisition List' table using all entries.\n")
}
#==============================


# Filter 'Acquisition List' table.
# Filter 'Acquisition List' table by selecting only the table entries whose 'Base Compound' column value is set to 'True'.
# Note: This step will remove any entries that do not have a base compound value set to true - even if the 'Checked' column is set to 'True'.
Acquisition_List <- Acquisition_List[Acquisition_List$`Base Compound` == "True", ]

# Sort 'Acquisition List' table based on 'Area [m/z]' in descending order and retrieve the top 3 entries for each compound (grouped by 'GC EI Compounds ID').
Acquisition_List <- Acquisition_List[order(Acquisition_List$`GC EI Compounds ID`, Acquisition_List$'GC EI Compounds ID', -Acquisition_List$'Area [m/z]'), ]

# Filter 'Acquisition List' table while retrieving the top 3 entries for each compound based on the highest area of the compound's mass ions.
# Define a function that would return the top 3 entries for each compound based on the highest area of the compound's mass ions.
top_3_entries <- function(group) {
  # 
  # Returns the top 3 entries for each compound based on the highest area of the compound's mass ions.
  #
  # Parameters:
  #   group: A data frame containing the entries for a single compound.
  #
  # Returns:
  # -------
  #   A data frame containing the top 3 entries for the compound based on the highest area of the compound's mass ions.
  #
  return(group[order(group$'Area [m/z]', decreasing = TRUE)[1:3], ])
}

# Apply the function to the 'Acquisition List' table.
Acquisition_List <- do.call(rbind, lapply(split(Acquisition_List, Acquisition_List$`GC EI Compounds ID`), top_3_entries))

# Remove any NA entries that may have been introduced by the 'top_3_entries' function (in case fewer than 3 entries were retrieved for a compound).
Acquisition_List <- Acquisition_List[complete.cases(Acquisition_List), ]

# Subset the desired columns from the 'Acquisition List' table.
Acquisition_List <- Acquisition_List[, c('Name', 'NIST Lib Hit Formula', 'Reference RT in min', 'm/z')]
#==============================


# Modify 'Acquisition List' table.
# Rename 'Acquisition List' table columns.
names(Acquisition_List)[names(Acquisition_List) == "Name"] <- "Compound"
names(Acquisition_List)[names(Acquisition_List) == "NIST Lib Hit Formula"] <- "Formula"
names(Acquisition_List)[names(Acquisition_List) == "Reference RT in min"] <- "RT [min]"

# Create additional columns and assign values as needed.
# Create columns: 'Adduct', 'z', 'Polarity', 't start (min)', and 't stop (min)'.
Acquisition_List$`Adduct` <- ""
Acquisition_List$`z` <- ""
Acquisition_List$`Polarity` <- "Positive"
Acquisition_List$`t start (min)` <- "0"
Acquisition_List$`t stop (min)` <- "0"

# Assign values for the 't start (min)' and 't stop (min)' columns.
# Use a value of '0.2' for the half peak width.
Acquisition_List$`t start (min)` <- Acquisition_List$`RT [min]` - 0.2
Acquisition_List$`t stop (min)` <- Acquisition_List$`RT [min]` + 0.2

# Modify columns 'Compound' and 'Formula'.
# If the 'Compound' or 'Formula' value is only nan, the column will alter how the 'Acquisition List' file is read by 
# Chromeleon. This may cause an undesired outcome. In R, typically, nan values are not generated and, instead, empty ("") values are generated. 
# Though it is not necessary to overwrite empty values, it will be done for consistency. Therefore, empty values will be changed to 'Unknown'.
# Change empty values to 'Unknown'.
Acquisition_List$`Compound` <- ifelse(Acquisition_List$'Compound' == "", "Unknown", Acquisition_List$`Compound`)
Acquisition_List$`Formula` <- ifelse(Acquisition_List$`Formula` == "", "Unknown", Acquisition_List$`Formula`)

# Add a suffix to 'Compound' column values to ensure that repeated identical triplicate entries are identifiable and unique.
# Each group of triplicate entries will be assigned a suffix number starting from 1.
# Note: this is necessary to differentiate between repeated identical triplicate entries, such as 'Peak@2.019' and 'Peak@2.019'.
# Without this command, Chromeleon will treat these entries as one compound and it would create additional MS Confirmation Peak values (instead of having multiple entries with the same number of MS ions, 3) 
# Function to add suffix if values are repeated in groups of 3
add_suffix <- function(compound) {
  # 
  # Returns the updated 'Compound' column values with suffixes added to repeated triplicate entries.
  #
  # Parameters:
  #   compound: A vector of 'Compound' column values.
  #
  # Returns:
  # -------
  # updated_compound: vector
  #   A vector of updated 'Compound' column values with suffixes added to repeated triplicate entries.
  #
  #
  # Identify which values are repeated triplicate entries (more than and multiples of 3).
  value_counts <- table(compound)
  repeated_triplicate_entries <- value_counts[value_counts > 3]
  
  # Initialize a new vector to store updated values
  updated_compound <- compound
  
  # Loop through each value in 'repeated_triplicate_entries'.
  for (value in names(repeated_triplicate_entries)) {
    if (value_counts[value] > 3) {  # Check if the count is greater than 3
      # Get the indexes of the value in the original vector
      indexes <- which(compound == value)
      # Calculate the number of triplicate groups
      num_groups <- length(indexes) / 3
      # Create suffix 1 (and so on) for each triplicate group
      suffixes <- rep(1:num_groups, each = 3)
      # Update the values with suffixes
      updated_compound[indexes] <- paste0(value, " (", suffixes, ")")
    }
  }
  
  return(updated_compound)
}

# Add suffix to 'Compound' column values.
Acquisition_List$`Compound` <- add_suffix(Acquisition_List$`Compound`)

# Rearrange 'Acquisition List' table columns.
Acquisition_List <- Acquisition_List[, c('Compound', 'Formula', 'Adduct', 'm/z', 'z', 't start (min)', 't stop (min)', 'Polarity')]

# Note: the Orbitrap Exploris GC Method Editor (v4.1.3) is unable to correctly read csv files with column headers between quotation marks (double quotes, ""), which R may generate. 
# Since the 'Acquisition List' data file may contain entries that include commas, a function will be created to 'quote' entries that include commas.
# The function will be applied to the 'Compound' column.
# Function to quote entries that include commas.
quote_commas <- function(compound) {
  # 
  # Returns the quoted 'Compound' column values that include commas.
  #
  # Parameters:
  #   compound: A vector of 'Compound' column values.
  #
  # Returns:
  # -------
  #   A vector of quoted 'Compound' column values that include commas.
  #
  
  # Quote entries that contain commas.
  compound <- ifelse(grepl(",", compound), paste0('"', compound, '"'), compound)  
  
  return(compound)
}

# Apply the function to the 'Compound' column.
Acquisition_List$`Compound` <- quote_commas(Acquisition_List$`Compound`)

# Index row numbers.
rownames(Acquisition_List) <- seq_len(nrow(Acquisition_List))
#==============================


# Create 'Exploris Acquisition List' table.
Exploris_Acquisition_List <- Acquisition_List

# Create 'Exploris SIM Scan' table.
# Replace all 'Formula' column entries with empty string ('').
Exploris_SIM_Scan_List <- Acquisition_List
Exploris_SIM_Scan_List$`Formula` <- ""
#==============================


# Write files to 'Downloads' directory.
workdir <- file.path(Sys.getenv("USERPROFILE"), "Downloads")  # This file will be written to the 'Downloads' directory ("C:\Users\[user.name]\Downloads").

# Write 'Exploris Acquisition List' data file.
outfilename_AL <- 'Exploris Acquisition List.csv'
outfile_path_AL <- file.path(workdir, outfilename_AL)

# Export 'Exploris Acquisition List' data file.
write.csv(Exploris_Acquisition_List, file = outfile_path_AL, row.names = FALSE, quote = FALSE)

# Print export completion message.
cat(paste("'Exploris Acquisition List' data file saved to location: ", outfile_path_AL))
cat("\n")

# Write 'Exploris SIM Scan' data file.
outfilename_SSL <- 'Exploris SIM Scan List.csv'
outfile_path_SSL <- file.path(workdir, outfilename_SSL)

# Export 'Exploris SIM Scan' data file.
write.csv(Exploris_SIM_Scan_List, file = outfile_path_SSL, row.names = FALSE, quote = FALSE)

# Print export completion message.
cat(paste("'Exploris SIM Scan' data file saved to location: ", outfile_path_SSL))
cat("\n")
#==============================


# Print script completion message.
cat(paste("Successfully exported 'Exploris Acquisition List' and 'Exploris SIM Scan List' data files!"))
cat("\n")
#==============================
