import pandas as pd
import argparse
import matplotlib.pyplot as plt
import seaborn as sns
from tabulate import tabulate
import networkx as nx
import warnings
from pyvis.network import Network

warnings.filterwarnings("ignore", category=UserWarning)

# Load CSVs
drug_targets_file = "Drug_targets_tool.csv"
mamestra_file = "Mamestra_b_160124_combined_final.csv"

drug_targets_df = pd.read_csv(drug_targets_file)
mamestra_df = pd.read_csv(mamestra_file)

# Extract Entry & Human Target
drug_targets_df[['Entry', 'Human Target']] = drug_targets_df.iloc[:, 0].str.split('|', expand=True)

# Keep a backup copy of raw annotation info (for --entry fallback)
mamestra_entry_df = mamestra_df[['Entry', 'GeneID', 'Tissue', 'Gene_Count']].copy()

# Merge only matching targets for drug-target analysis
merged_df = drug_targets_df.merge(mamestra_df, on='Entry', how='inner')

# Select core columns
final_df = merged_df[['Entry', 'Human Target', 'Drug(s)', 'GeneID', 'Tissue', 'E_value',
                      'Isoform_Count', 'Gene_Count', 'Gene.Ontology..GO.']].copy()

# CLI arguments
parser = argparse.ArgumentParser(description="Search and display drug targets with multiple analysis options")
parser.add_argument("-drug", type=str, help="Filter results by drug name", default=None)
parser.add_argument("-tissue", type=str, help="Filter results by tissue type", default=None)
parser.add_argument("-entry", type=str, help="Filter results by Uniprot Entry ID", default=None)
parser.add_argument("-network", action="store_true", help="Construct drug-target interaction network")
parser.add_argument("-rank", action="store_true", help="Rank most sensitive targets")
args = parser.parse_args()

# Apply filters
if args.drug:
    final_df = final_df[final_df['Drug(s)'].str.contains(args.drug, case=False, na=False)]
if args.tissue:
    final_df = final_df[final_df['Tissue'].str.contains(args.tissue, case=False, na=False)]
if args.entry:
    final_df = final_df[final_df['Entry'].str.contains(args.entry, case=False, na=False)]

# Fallback to annotation file for entry plot
if args.entry and final_df.empty:
    print(f"Entry '{args.entry}' not found in drug-target merged dataset. Trying annotation file directly...")
    final_df = mamestra_entry_df[mamestra_entry_df['Entry'].str.contains(args.entry, case=False, na=False)].copy()
    if final_df.empty:
        print(f"Entry '{args.entry}' not found in annotation data either. Please double-check the ID.")
        exit()
    final_df['Sensitivity_Rank'] = final_df['Gene_Count'].rank(method='dense', ascending=False)
    print("Proceeding with entry-specific plot using annotation data only (no drug mapping).")

# Only proceed if data exists
if final_df.empty:
    print("No data available after filtering. Skipping plots and exports.")
    exit()

# Ensure clean ranking
final_df = final_df.copy()
if 'Sensitivity_Rank' not in final_df.columns:
    final_df['Sensitivity_Rank'] = final_df['Gene_Count'].rank(method='dense', ascending=True)

# Save outputs
final_df.to_csv("Mapped_Drug_Targets_in_Mamestra.csv", index=False)
final_df.to_csv("Mapped_Drug_Targets_in_Mamestra.tsv", sep="\t", index=False)

# Optional ranking output
if args.rank:
    ranked_df = final_df.sort_values(by='Sensitivity_Rank')
    ranked_df.to_csv("Ranked_Sensitive_Drug_Targets.csv", index=False)
    print("Ranked sensitive targets saved to 'Ranked_Sensitive_Drug_Targets.csv'")
    print(tabulate(ranked_df, headers='keys', tablefmt='fancy_grid'))

# Print result
print(tabulate(final_df, headers='keys', tablefmt='fancy_grid'))
print(f"\nTotal matched entries: {len(final_df)}")
print("Results saved to 'Mapped_Drug_Targets_in_Mamestra.csv' and '.tsv'")

# === Boxplot: Tissue vs Gene Count ===
plt.figure(figsize=(12, 6))
sns.boxplot(data=final_df, x='Tissue', y='Gene_Count')
plt.xticks(rotation=30)
plt.title("Gene Count Distribution Across Tissues")
plt.xlabel("Tissue Type")
plt.ylabel("Gene Count")
plt.tight_layout()
plt.savefig("Gene_Count_Tissue_Distribution.png")
print("Tissue distribution plot saved as 'Gene_Count_Tissue_Distribution.png'")

# === Entry-specific Plot ===
if args.entry:
    plt.figure(figsize=(12, 6))
    sns.boxplot(data=final_df, x='Tissue', y='Gene_Count')
    plt.xticks(rotation=30)
    plt.title(f"Gene Count Distribution for Entry {args.entry}")
    plt.xlabel("Tissue Type")
    plt.ylabel("Gene Count")
    plt.tight_layout()
    entry_plot_name = f"Gene_Count_Entry_{args.entry}_Distribution.png"
    plt.savefig(entry_plot_name)
    print(f"Entry-specific plot saved as '{entry_plot_name}'")

# === Interactive Network Plot ===
if args.network and 'Drug(s)' in final_df.columns:
    print("Constructing interactive drug-target network...")
    net = Network(height="800px", width="100%", notebook=False, bgcolor="#fff", font_color="black")

    drug_nodes = set()
    entry_nodes = set()
    edge_memory = set()
    target_map = dict(zip(final_df['Entry'], final_df.get('Human Target', ['Unknown']*len(final_df))))

    for _, row in final_df.iterrows():
        entry = row['Entry']
        if entry not in entry_nodes:
            net.add_node(entry, label=entry, color="green", shape="dot", size=15)
            entry_nodes.add(entry)

        for drug in str(row['Drug(s)']).split(','):
            drug = drug.strip()
            if drug and drug not in drug_nodes:
                net.add_node(drug, label=drug, color="red", shape="ellipse", size=20)
                drug_nodes.add(drug)
            net.add_edge(drug, entry, color="black")

    # Add target-target edges
    for t1 in entry_nodes:
        for t2 in entry_nodes:
            if t1 != t2 and (t1, t2) not in edge_memory and (t2, t1) not in edge_memory:
                net.add_edge(t1, t2, color="gray", dashes=True)
                edge_memory.add((t1, t2))

    net.repulsion(node_distance=120, central_gravity=0.3, damping=0.9)

    legend = "<br>".join([f"<b>{k}</b>: {v}" for k, v in target_map.items()])
    html_legend = f"""
<div style="position: fixed; top: 10px; left: 10px; background: #fff; border: 1px solid black;
                padding: 10px; font-size: 12px; font-family: Arial; max-height: 400px; overflow-y: auto;">
<b>Legend</b><br>
<span style='color:red'>&#9679;</span> Drug<br>
<span style='color:green'>&#9679;</span> Entry<br>
<hr>{legend}
</div>
    """

    output_html = "Drug_Target_Network.html"
    net.save_graph(output_html)

    with open(output_html, "r") as f:
        html = f.read().replace("</body>", html_legend + "</body>")

    with open(output_html, "w") as f:
        f.write(html)

    print(f"Interactive network saved as '{output_html}'")
