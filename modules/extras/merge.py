import os
import pandas as pd

# Define the base directory
base_dir = '/mnt/scratch15/c23048124/transpipeline_containerised/workdir/upimapi'

# Define the subdirectories
sub_dirs = ['Cele', 'Dmel', 'Hsap', 'Mmus', 'Scer', 'sprot']

# Initialize an empty dataframe to store the merged data
merged_df = pd.DataFrame()

# Loop through each subdirectory and read the corresponding file
for sub_dir in sub_dirs:
    file_path = os.path.join(base_dir, sub_dir, f'Dreti_{sub_dir}_upimapi.tsv')
    
    # Read the file
    df = pd.read_csv(file_path, sep='\t')
    
    # Add a prefix to each column to differentiate between species
    df_prefixed = df.add_prefix(f'{sub_dir}_')
    
    # Merge the dataframes column-wise
    if merged_df.empty:
        merged_df = df_prefixed
    else:
        merged_df = pd.concat([merged_df, df_prefixed], axis=1)

# Define the output path
output_path = os.path.join(base_dir, 'merged_upimapi.tsv')

# Save the merged dataframe to the specified location
merged_df.to_csv(output_path, sep='\t', index=False)

print(f'Merged file saved to {output_path}')

