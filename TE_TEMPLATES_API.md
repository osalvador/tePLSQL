Application Program Interface [API] against the TE_TEMPLATES table for the tePLSQL project.
===

This package imports and exports a series of tePLSQL templates for the TE_TEMPLATES using XML.

## File Format
Example XML Format:
   
```xml
<teplsql>
  <templates>
    <template>
      <NAME>hello world</NAME>
      <DESCRIPTION>This is a "Hello World" template</DESCRIPTION>
      <CREATED_BY>SCOTT TIGER</CREATED_BY>
      <CREATED_DATE>2016-11-19</CREATED_DATE>
      <MODIFIED_BY>SCOTT TIGHER</MODIFIED_BY>
      <MODIFIED_DATE>2016-11-19</MODIFIED_DATE>
      <TEMPLATE>Hello World!</TEMPLATE>
    </template>
  </templates>
</teplsql>
```

  - File Extenstion should be .xml or .teplsql
  - DATE columns are those imported/exported via XML SQL.  YYYY-MM-DD
  - The Node "/teplsql/templates/template/TEMPLATE" can be CDATA type data.
  - Multiple /teplsql/templates/template Nodes are expected.

## Security
This is an AUTHID CURRENT_USER package.

The caller must have appropriate INSERT/UPDATE/SELECT permission on the TE_TEMPLATES table.

For APEX:

  - The 'parsing schema' needs EXECUTE permission in order to run.  (This is in addtion to INSERT/SELECT/UPDATE on TE_TEMPLATES

For Oracle Directory:

  - The caller needs INSERT/SELECT/UPDATE permissions on the table TE_TEMPLATES</li>
  - The caller must also have appropriate READ/WRITE permission on the Oracle Directory if the "directory_*" interfaces are used.</li>

## Primative Functions
These functions are the main functions of the package.
   
  - `xml_import` - imports an XML LOB into the TE_TEMPLATES table
  - `xml_export` - returns the XML in CLOB format (todo: this should return an XMLType)
  - `assert` - this verifies that the XML is valid for import()

## PL/SQL Interfaces
These procedures allow you to import from/export to a file using an Oracle Directoyr

  - `file_import` - imports templates from an XML file found in an Oracle Directory.
  - `file_export` - exports templates into an XML file located in an Oracle Directory.

## APEX Interfaces
These procedures are for use from within Oracle Application Express (APEX)

  - `apex_import` - use to import a file uploaded via "File Browse..." Item type into APEX_APPLICATION_TEMP_FILES.  APEX 5.0 or higher is required
  - `apex_export` - a BEFORE HEADER process that allows the end-user to download the XML file.  The Filename must end in xml or teplsql

## List of Values

These are Pipelined Functions that allow you to create a List of Values for your application.

  - `import_options_lov` - returns a list of options for the import() series of procedures
  - `export_options_lov` - returns a list of option for the export() series of procedures

### IMPORT Options

  - `g_import_overwrite` - if NAME matches, always OVERWRITE
  - `g_import_ignore`    - if NAME matches, ignore
  - `g_import_error`     - if NAME mathches, raise an error

### EXPORTS Options

  - `g_export_exact` - Match p_search_values against NAME using a case insentive exact mathch.
  - `g_export_like`  - Match p_search_values against NAME using a case insentive LIKE match.  You must provide "%" keys.
  - `g_export_regexp`  - Match p_search_values against NAME using a case sensitive Regular Expression match.
