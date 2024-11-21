import argparse
import sqlite3
import os
import pandas as pd
from tabulate import tabulate

# Function to convert CSV to SQLite database
def csv_to_database(csv_path, db_path):
    print(f"CSV Path: {csv_path}")
    print(f"Database Path: {db_path}")
    
    if not os.path.exists(csv_path):
        raise FileNotFoundError(f"CSV file not found at {csv_path}")

    # Load CSV
    print(f"Loading CSV file...")
    data = pd.read_csv(csv_path)

    # Create SQLite database
    print(f"Creating database...")
    conn = sqlite3.connect(db_path)
    data.to_sql("gene_data", conn, if_exists="replace", index=False)
    conn.close()
    print("Database created successfully!")

# Function to get database column names
def get_columns(db_path):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("PRAGMA table_info(gene_data)")
    columns = [col[1] for col in cursor.fetchall()]
    conn.close()
    return columns

# Function to query the database
def query_database(db_path, filters):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Build the query dynamically based on filters
    query = "SELECT * FROM gene_data WHERE 1=1"
    params = []

    for column, value in filters.items():
        if value:  # Only add non-empty filters
            query += f" AND {column} = ?"
            params.append(value)

    # Execute the query
    cursor.execute(query, params)
    results = cursor.fetchall()
    headers = [description[0] for description in cursor.description]  # Get column headers

    conn.close()
    return headers, results

# Main function
def main():
    # Initial parser to check database and CSV
    parser = argparse.ArgumentParser(
        description="Query the gene data database or create it from a CSV file.",
        add_help=False  # Disable default help to manage it dynamically later
    )
    parser.add_argument(
        "--csv",
        type=str,
        help="Path to the CSV file to create the database (if the database doesn't exist).",
    )
    parser.add_argument(
        "--db",
        type=str,
        default="final_data.db",
        help="Path to the SQLite database file (default: final_data.db).",
    )
    parser.add_argument(
        "--species",
        type=str,
        default="all",
        help="Filter by species (e.g., Hsap, Mmus, Dmel, Cele, Scer, sprot, or all)",
    )
    parser.add_argument("-h", "--help", action="store_true", help="Show this help message and exit")

    # Parse initial arguments
    args, unknown = parser.parse_known_args()

    # If help is requested, defer to dynamic parser later
    if args.help:
        pass

    # Check if database exists
    if not os.path.exists(args.db):
        if args.csv:
            csv_to_database(args.csv, args.db)
        else:
            print("Database not found! Please provide a CSV file to create it using --csv.")
            return

    # Get dynamic columns from the database
    columns = get_columns(args.db)

    # Create a new parser to dynamically add arguments
    dynamic_parser = argparse.ArgumentParser(
        description="Query the gene data database or create it from a CSV file."
    )
    dynamic_parser.add_argument(
        "--csv",
        type=str,
        help="Path to the CSV file to create the database (if the database doesn't exist).",
    )
    dynamic_parser.add_argument(
        "--db",
        type=str,
        default="final_data.db",
        help="Path to the SQLite database file (default: final_data.db).",
    )
    dynamic_parser.add_argument(
        "--species",
        type=str,
        default="all",
        help="Filter by species (e.g., Hsap, Mmus, Dmel, Cele, Scer, sprot, or all)",
    )

    # Add dynamic arguments based on columns
    for column in columns:
        if column.lower() != "species":  # Avoid conflict with manual --species
            dynamic_parser.add_argument(f"--{column.lower()}", type=str, help=f"Filter by {column}")

    # Parse arguments again
    args = vars(dynamic_parser.parse_args())

    # Build filters from provided arguments
    filters = {k: v for k, v in args.items() if v and k not in ["csv", "db", "species"]}

    # Add species filter if provided
    if args["species"] and args["species"].lower() != "all":
        filters["Species"] = args["species"]

    # Query the database
    headers, results = query_database(args["db"], filters)

    # Print results
    if results:
        print(tabulate(results, headers=headers, tablefmt="grid"))
    else:
        print("No results found.")

if __name__ == "__main__":
    main()

