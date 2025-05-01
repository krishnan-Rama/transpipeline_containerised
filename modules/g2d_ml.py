import pandas as pd
import argparse
import matplotlib.pyplot as plt
import seaborn as sns
from tabulate import tabulate
import networkx as nx
import warnings
from pyvis.network import Network  # Interactive HTML network

# Suppress warnings
warnings.filterwarnings("ignore", category=UserWarning)

# Load the CSV files
drug_targets_file = "Drug_targets_tool.csv"
mamestra_file = "Mamestra_b_160124_combined_final.csv"

# Read CSV files
drug_targets_df = pd.read_csv(drug_targets_file)
mamestra_df = pd.read_csv(mamestra_file)

# Extract relevant information from the first column of drug_targets_df
drug_targets_df[['Entry', 'Human Target']] = drug_targets_df.iloc[:, 0].str.split('|', expand=True)

# Merge on the Entry column to find matches
merged_df = drug_targets_df.merge(mamestra_df, left_on='Entry', right_on='Entry', how='inner')

# Select relevant columns for visualization
final_df = merged_df[['Entry', 'Human Target', 'Drug(s)', 'GeneID', 'Tissue', 'E_value', 'Isoform_Count', 'Gene_Count', 'Gene.Ontology..GO.']]

# Rank sensitivity based on Gene_Count (lower count -> more sensitive)
final_df['Sensitivity_Rank'] = final_df['Gene_Count'].rank(method='dense', ascending=True)

# Set up argument parsing
parser = argparse.ArgumentParser(description="Search and display drug targets with multiple analysis options")
parser.add_argument("-drug", type=str, help="Filter results by drug name (case insensitive)", default=None)
parser.add_argument("-tissue", type=str, help="Filter results by tissue type", default=None)
parser.add_argument("-network", action="store_true", help="Construct drug-target interaction network and visualize metrics")
parser.add_argument("-rank", action="store_true", help="Rank most sensitive drug targets")
args = parser.parse_args()

# Apply filtering based on user input
if args.drug:
    final_df = final_df[final_df['Drug(s)'].str.contains(args.drug, case=False, na=False)]
if args.tissue:
    final_df = final_df[final_df['Tissue'].str.contains(args.tissue, case=False, na=False)]

# Save the results to a CSV and TSV file
output_csv = "Mapped_Drug_Targets_in_Mamestra.csv"
output_tsv = "Mapped_Drug_Targets_in_Mamestra.tsv"
final_df.to_csv(output_csv, index=False)
final_df.to_csv(output_tsv, index=False, sep='\t')

# Rank most sensitive drug targets if requested
if args.rank:
    print("\nRanking most sensitive drug targets...")
    ranked_df = final_df.sort_values(by='Sensitivity_Rank')
    ranked_df.to_csv("Ranked_Sensitive_Drug_Targets.csv", index=False)
    print("Ranked sensitive drug targets saved to 'Ranked_Sensitive_Drug_Targets.csv'")
    print(tabulate(ranked_df, headers='keys', tablefmt='fancy_grid'))

# Display results in an elegant tabular format
print(tabulate(final_df, headers='keys', tablefmt='fancy_grid'))

# Optional: Create a summary report
print(f"\nTotal matched drug targets: {len(final_df)}")
print(f"Results saved to {output_csv} and {output_tsv}")

# === Tissue Distribution Boxplot ===
plt.figure(figsize=(12, 6))
sns.boxplot(data=final_df, x='Tissue', y='Gene_Count')
plt.xticks(rotation=30)
plt.title("Gene Count Distribution Across Different Tissues")
plt.xlabel("Tissue Type")
plt.ylabel("Gene Count")
plt.savefig("Gene_Count_Tissue_Distribution.png", bbox_inches='tight')
print("Tissue distribution plot saved as 'Gene_Count_Tissue_Distribution.png'")


# === NETWORK ANALYSIS WITH INTERACTIVE HTML GRAPH ===
if args.network:
    print("\nConstructing Drug-Target Interaction Network...")

    # Initialize Pyvis Network
    net = Network(height="800px", width="100%", notebook=False, bgcolor="#ffffff", font_color="black")

    # Create nodes and edges
    primary_targets = set()
    drug_nodes = set()
    existing_edges = set()  # Track added edges
    target_name_mapping = {}  # Store full target names for legend

    for _, row in final_df.iterrows():
        drugs = row['Drug(s)'].split(', ')
        entry = row['Entry']
        target_name = row['Human Target'] if pd.notna(row['Human Target']) else "Unknown Target"

        # Store the full target name for legend display
        target_name_mapping[entry] = target_name

        # Ensure the target node is added before edges
        if entry not in primary_targets:
            net.add_node(entry, label=entry, color="green", shape="dot", size=15)  # Only Entry in the plot
            primary_targets.add(entry)

        # Add drug and target nodes
        for drug in drugs:
            if drug not in drug_nodes:
                net.add_node(drug, label=drug, color="red", shape="ellipse", size=20)  # Drug nodes
                drug_nodes.add(drug)

            # Now add the drug-target edge
            net.add_edge(drug, entry, color="black", title="Drug-Target Interaction")

    # Add target-to-target interactions
    for target1 in primary_targets:
        for target2 in primary_targets:
            if target1 != target2 and (target1, target2) not in existing_edges and (target2, target1) not in existing_edges:
                net.add_edge(target1, target2, color="gray", dashes=True, title="Target-Target Interaction")
                existing_edges.add((target1, target2))

    # Improve layout dynamically
    net.repulsion(node_distance=120, central_gravity=0.3, damping=0.9)

    # Generate target name list for legend
    target_names_html = "<b>Target Name:</b><br>"
    target_names_html += "<br>".join([f"<b>{entry}</b>: {name}" for entry, name in target_name_mapping.items()])

    # Add custom legend as an HTML overlay
    legend_html = f"""
    <div style="position: fixed; top: 10px; left: 10px; background-color: white; padding: 10px;
                border-radius: 5px; border: 1px solid black; box-shadow: 2px 2px 5px rgba(0,0,0,0.2);
                font-family: Arial, sans-serif; font-size: 12px; max-height: 400px; overflow-y: auto;">
        <b>Legend:</b><br>
        <span style="color: red;">&#9679;</span> Drug Node (Red)<br>
        <span style="color: green;">&#9679;</span> Target Node (Green)<br>
        <span style="color: black;">&#8212;</span> Drug-Target Interaction (Black Edge)<br>
        <span style="color: gray; text-decoration: dashed;">&#8212;</span> Target-Target Interaction (Gray Dashed Edge)<br>
        <hr>
        {target_names_html}
    </div>
    """

    # Save network to an HTML file manually with legend
    network_html = "Drug_Target_Network.html"
    net.save_graph(network_html)

    # Append legend manually to the saved HTML
    with open(network_html, "r") as file:
        html_content = file.read()

    html_content = html_content.replace("</body>", legend_html + "</body>")

    with open(network_html, "w") as file:
        file.write(html_content)

    print(f"Interactive network graph saved as '{network_html}' with clean labels and detailed legend.")
