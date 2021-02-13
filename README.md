# DataPrep.jl

This package facilitates the preparation of tabular data sets for analysis.
Data preparation includes column filtering, row filtering, constructing new columns, formatting values,
modifying values, and checking whether values are consistent with a user-supplied schema.
Users configure the preparation using TOML files - they do not need to write any Julia code.

## Usage

Configure a TOML file that specifies the tables to be prepped and the sequence of operations to apply to each row - see the example below.
For each row in the source data (the input row), a transformed row (the output row) is constructed as specified.
The resulting tables are written to disk as tab-separated values (tsv) files.

There are 3 basic operations used to construct an output row:

1. Create: Construct a value for a field using values from the input row and string interpolation. The field needn't already exist.
2. Update: Replace part of the value using strings and/or regexes.
3. Delete: Retain the row only if it satisfies user-supplied criteria.

Note that column filtering is implied by the construction of the output row.
That is, the output row contains only the fields listed in the TOML file.

In addition, the following built-in functionality can be used as part of these operations:

1. Check whether the row satisfies the user-supplied schema.

The following TOML file demonstrates the format for each of these operations.
Further examples are given in the test suite.

```toml
projectname = "my-project-dataprep"
description = "Preparing tables for analysis"

[tables.table1]
infile     = "/path/to/infile1.csv"
outfile    = "/path/to/outfile1.csv"
schemafile = "/path/to/schema1.toml"
eachrow    = [  # Only columns listed below will be included in the result
    "retain row if $(birthdate) is not missing",  # Operation 3. The format is: retain row if expression
    "fullname = $(firstname) $(lastname)",        # Operation 1
    "col1 = using $(col1) replace \"my string\" with string2",  # Operation 2. Use escaped quotation marks if a string contains spaces.
    "col2 = using $(col1) replace Regex(string1) with SubstitutionString(string2)",  # Operation 2. Exclude outer quotation marks. Escape backslashes.
    "satisfies_schema = row satisfies schema",  # Check whether the row satisfies the schema (built-in functionality), store the result in a new field (Operation 1).
    "retain row if row satisfies schema"        # Operation 3: Exclude row if the schema is not satisfied
]

[tables.table2]
infile     = "/path/to/infile2.csv"
outfile    = "/path/to/outfile2.csv"
schemafile = "/path/to/schema2.toml"
eachrow    = [
    "retain row if $(birthdate) is not missing"
]
```

Once your configuration is complete, run the `prepare_tables` script from the command line.

On Windows use PowerShell:

```bash
PS julia path\to\DataPrep.jl\scripts\prepare_tables.jl path\to\config.toml
```

On Linux or Mac:

```bash
$ julia path/to/DataPrep.jl/scripts/prepare_tables.jl path/to/config.toml
```