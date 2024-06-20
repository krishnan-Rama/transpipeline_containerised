import pandas as pd

# Load the data from the uploaded files
gene_expr_matrix = pd.read_csv('/mnt/scratch15/c23048124/transpipeline_containerised/workdir/rsem/Dreti_RSEM.gene.TMM.EXPR.matrix', sep='\t', index_col=0)
isoform_expr_matrix = pd.read_csv('/mnt/scratch15/c23048124/transpipeline_containerised/workdir/rsem/Dreti_RSEM.isoform.TMM.EXPR.matrix', sep='\t', index_col=0)
gene_trans_map = pd.read_csv('/mnt/scratch15/c23048124/transpipeline_containerised/workdir/assembly/trinity_assemby/Dreti_okay.gene_trans_map', sep='\t', header=None, names=["gene_id", "transcript_id"])

# Merge isoform expression data with gene-to-transcript map
merged_data = pd.merge(gene_trans_map, isoform_expr_matrix, left_on='transcript_id', right_index=True)

# Aggregate isoform expression data to the gene level, including transcript IDs
aggregated_data = merged_data.groupby('gene_id').agg({'transcript_id': 'first', **{col: 'sum' for col in isoform_expr_matrix.columns}})

# Merge the aggregated isoform data with the gene expression matrix
final_merged_data = pd.merge(gene_expr_matrix, aggregated_data, left_index=True, right_index=True, suffixes=('_gene', '_isoform'))

# Save the result to a new file
output_file = '/mnt/scratch15/c23048124/transpipeline_containerised/workdir/upimapi/final_merged_expression_matrix_with_transcripts.csv'
final_merged_data.to_csv(output_file, sep='\t')

print(f"Final merged expression matrix with transcript IDs saved to {output_file}")

