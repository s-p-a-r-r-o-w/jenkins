import re
import os
from collections import defaultdict

drop_statements = []
create_table_statements = []
create_statements = []
alter_table_statements = []
alter_statements = []
other_statements = []

def parse_changes_diff(file_path):
    """
    Parse the changes.diff file to extract column changes and table names.
    """
    changes = {
        "tables": set(),  # Store only the table names
        "columns": set()  # Store only the column names
    }

    with open(file_path, 'r') as file:
        for line in file:
            # Detect table name (filename in the diff)
            if line.startswith("---") or line.startswith("+++"):
                table_match = re.search(r'entities/([a-zA-Z_0-9]+)\.xml', line)
                if table_match:
                    table_name = table_match.group(1)
                    changes["tables"].add(table_name)

            # Process column names
            if "<Attribute ColumnName=" in line:
                column_match = re.search(r'ColumnName="([^"]+)"', line)
                if column_match:
                    column_name = column_match.group(1)
                    changes["columns"].add(column_name)

    return dict(changes)

def filter_sql_statements(sql, valid_columns, tables):
    """
    Filter and categorize SQL statements based on valid columns and command type.
    DROP commands should come first, followed by CREATE and then ALTER commands.
    """
    # Split SQL into individual statements
    sql_statements = sql.split(";")

    for statement in sql_statements:
        statement = statement.strip()

        # Include the statement if it mentions any valid column or table
        if any(column in statement for column in valid_columns) or any(table in statement for table in tables):
            # Categorize based on the SQL command
            if statement.upper().startswith("DROP"):
                drop_statements.append(statement + ";\n\n")
            elif statement.upper().startswith("CREATE TABLE"):
                create_table_statements.append(statement + ";\n\n")
            elif statement.upper().startswith("CREATE"):
                create_statements.append(statement + ";\n\n")
            elif statement.upper().startswith("ALTER TABLE"):
                alter_table_statements.append(statement + ";\n\n")
            elif statement.upper().startswith("ALTER"):
                alter_statements.append(statement + ";\n\n")
            else:
                other_statements.append(statement + ";\n\n")

def process_sql_files(directory, valid_columns, tables, output_file):
    """
    Process all SQL files in a directory and filter based on valid columns.
    SQL statements are categorized and ordered as per the rules.
    """
    with open(output_file, 'w') as outfile:
        for filename in os.listdir(directory):
            if filename.endswith('.sql'):
                file_path = os.path.join(directory, filename)

                with open(file_path, 'r') as sql_file:
                    sql_content = sql_file.read()

                    filter_sql_statements(sql_content, valid_columns, tables)

        # Order the statements: DROP first, then CREATE, then ALTER, then others
        ordered_statements = drop_statements + create_table_statements + create_statements + alter_table_statements + alter_statements + other_statements
        # Write the ordered statements to the output file
        outfile.write("".join(ordered_statements))
        #print(f"SQL Ordered Statements:\n{ordered_statements}")

def write_table_names(tables, output_file):
    """
    Write table names to a file.
    """
    with open(output_file, 'w') as file:
        for table in tables:
            file.write(f"{table}\n")

# Main script execution
diff_file_path = "/opt/jenkins/entity_automation/changes.diff"
changes = parse_changes_diff(diff_file_path)

# Collect all table names and column names from changes.diff
tables = changes["tables"]
print(f"Tables: {tables}")

valid_columns = changes["columns"]
print(f"Valid Columns: {valid_columns}")

# Directory containing SQL files and output file path
directory = '/opt/IBM/OMS10/repository/scripts/'  # Replace with your directory path
output_file = '/opt/jenkins/entity_automation/entity_dbcr.sql'
tables_file = '/opt/jenkins/entity_automation/tables.diff'

# Process SQL files
process_sql_files(directory, valid_columns, tables, output_file)

# Write table names to tables.diff
write_table_names(tables, tables_file)
