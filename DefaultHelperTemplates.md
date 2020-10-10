Introduction
===
When creating a Build Template, Helper Templates are the blue-prints for various sections of code.

This version of *tePLSQL* includes a set of Default Helper Templates.

The types of database objects that can be generated through a Build Template are:

Type | Description
-----|-------------
build | supply cursors, etc to the Template code
select | generate code for a View, Cursor, Select statement, CTE, or a Table Macro (future)
package | generate code for a Package
variable | generate code for a Variable or a Constant
plsql-type | generate code for a Subtype, Record, AA, NT, or Ref Cursor
exception | generate code for an Exception
procedure | generate code for a Function or Procedure
exception-block | generate code for the `EXCEPTION` clause of a Function,Procedur, or Package Initialization


Installation
===
These helper templates should be automatically loaded into the `TE_TEMPLATES` table upon a fresh install.

You can manually install (or refresh) using the `te_default_helper_templates.install_templates` procedure.
By doing this, all existing versions of the Helper Templates will be updated/overwritten.
New ones will be added.

build
==
This provides cursors, etc. to be used by Templates.  Use this as the head Extension.

Cursor "Columns"
----
**note** all parameters are `VARCHAR2`

[h3]Parameters[/h3]

pos | Parameter name | Parameter Desription 
----|---------------|-----------
1 | schema | Schema owner of the Table to search.
2 | table_name | Name of the Table to search.
3 | search_txt | Search criteria (default `-HIDDEN -SYSTEM` )

[h3]Returned Columns[/h3]

Column Name | Column Description
------------|--------------------
column_name | Name of the column
column_name_rpad | Name of the column RPAD'd to largest returned column
order_by | number representing the order of the columns
order_by_desc | number representing the reverse order of the columns
comma_first | gives a comma (`,`) for non-first row.  Space (` `) otherwise.
comma_last | gives a comma (`,`) for non-last row.  Space (` `) otherwise.
data_type | data type of the column
data_desc | data description of the column ( eg `varchar2(10 char)`, `number(6,2)` )
comment | Comment for the column
data_default | ( `LONG` data type ! ) default value for the column
is_pk | Is the column a part of the Primary Key? [YES/NO]
is_id | Is the column an Identity Column(12c) or a single `NUMBER` column? [YES/NO]
is_nullable | Is the column Nullable? [YES/NO]
is_hidden | Is the column Hidden? [YES/NO]
is_vc | Is the column a Virtual Column? [YES/NO]
is_system | (12c+) Was the column System generated? [YES/NO] (opposited of `USER_GENERATED`)

[h3]Search String[/h3]

Search String is a space separated list of *key-words* with/without a prefix [+/-]

- If the *key-word* has no prefix, All columns of that type are returned
- If the *key-wird* has a `+` prefix, those column types are also returned
- If the *key-word* has a `-` prefix, those column types are not returned.

key-word | Column Type
---------|-------------
PK | Column is a Primary Key
ID | Column is the Identity Column
VC | Column is a Virtual Column
HIDDEN | Column is a Hidden Column
SYSTEM | Column is a System Generated column.
NULLABLE | Column can contain nulls
NOTNULL | Column can not contain nulls
DEFAULT | Column has a default value defined

[h3]example[/h3]

(Default) To get all Visible, user generated columns (including Virtual Columns)
```sql
"Cursor"( '${schema}', '${table_name}' )
```

To get NOT NULL columns with a DEFAULT value
```sql
"Cursor"( '${schema}', '${table_name}', 'DEFAULT -NULLABLE' )
```

To get all visible, user generate, non-PK, non-Virtual columns
```sql
"Cursor"( '${schema}', '${table_name}', '-PK -VC' )
```

sub-extenstions
----

Supported sub-extenstions are:
- packages
- select (View or stand-alone Table Macro)
- procedures (stand-alone Functions/Procedures)

package
======
Extend this to generate a Package (both Spec and Body will be generated).

definable blocks
---
Block | req? | Description
------|------|--------------
name | D | name of the Package. (default is the object's name)
Documentation | D | In-code documentation for the Exception.
init | | If define, this is the body of the Package's initialization code.

Legend
- **D** - Required. But, a default value is given.

sub-extensions
---
Supported sub-extensions are
- select (produces a cursor)
- plsql-type
- procedure
- variables
- exception
- exception-block (needs an `init` block to generate)

**note:** Object names of the form `private.*` will only be generated in the Body.

plsql-types
===
Extend this to generates code for Subtypes, Records, Nested Tables, Associative Array, and Ref Cursors.

**note:** Current version of the default helper template requires a subtype/record for nt's, aa's, and ref cursors.

definable blocks
---
block | req? | ST/R | Description
------|------|-----|------------
name | D | Both | name of the Record/Subtype pl/sql type. (default is the object's name)
data-type | Y | ST | Data type for a Subtype pl/sql type. Set only one (`data-type`, `record`)
record | Y | R | Defines the attributes for a Record pl/sql type. Set only one (`data-type`, `record`)
Documentation| | Both | In-code documentation for pl/sql types
nt-name | |Both | Name for a Nested Table pl/sql type.  Set this to generate a Nested Table.
aa-name | |Both | Name for an Associative Array pl/sql type.  Set this to generate an Associative Array.
ref-name | |Both | Name for an Ref Cursor pl/sql type.  Set this to generate a Ref Cursor.
aa-key-data-type | D | AA | Set this to define the `INDEX BY` clause. (default is `pls_integer')

Legend
- **D** - Required. But, a default value is given.
- **Both** - used by Subtypes and Records
- **ST** - only for Subtypes
- **R** - only for Records
- *AA** - only for Associative Arrays. (Requires `aa-name` to be defined)

variables
===
Extend this to generate code for a variable.

definable blocks
---
block | req? | Description
------|------|--------
name | D | name of the variable. (default is the object's name)
Documentation| | In-code documentation for the variable.
data-type | Y | Data type of the variable.
value | | Sets the value of the variable in the Declaration section.
constant-value | | Defines the variable as a Constant.  Also, sets its value.

Legend
- **D** - Required. But, a default value is given.
- **Y** - Required.

select
===
Extend this to generate code for Select, View, Cursor, CTE, or Table Macro(future).

**note:** Future version will generate SQL Table Macro code too

definable blocks
---
block | req? | For? | Description
------|------|--------
name | D | VCM | name of the view,cursor. (default is the object's name)
SQL | D | all | Select Statement. (default: `select * from dual`)
parameters | | CM | Parameters for the Cursor/Table Macro. use `teplsql.goto_tab(1)` for multiline parameters.
rcd-name* | | C | Name for a Record type.  Set this to generate a Subtype for the cursor's `%ROWTYPE`.
nt-name* | | C | Name for a Nested Table pl/sql type.  Set this to generate a Nested Table.
aa-name* | | C | Name for an Associative Array pl/sql type.  Set this to generate an Associative Array.
ref-name* | | C | Name for an Ref Cursor pl/sql type.  Set this to generate a Ref Cursor.
aa-key-data-type* | D | C | Set this to define the `INDEX BY` clause. (default is `pls_integer'). requires `aa-name` to be defined.

Legend
- **D** - Required. But, a default value is given.
- **V** - Used for Views
- **C** - Used for Cursors
- **M** - Used for Table Macros


executable blocks
---
Block | Description
------|-------------
specification | generate code for a cusor (automatically called for Package, Function, Procedure)
make-view | generate code for `create view`
cte | generate code for CTE. `WITH` keyword NOT included
(tbd) | generate code for a stand-alone Table Macro

procedure
====
Generate code for a Procedure or Function.

**note** This version of the Helper Template does not support pipeline functions or other function options ( eg `deterministic`, etc.)

definable blocks
---
Block | req? | For? | Description
------|------|------|------------
name | D | both | name of the Procedure/Function. (default is the object's name)
Documentation| D | In-code documentation for the Procedure/Function.
return-variable-type | | F | Sets the return variable data type. If defined, Function code is generated.
return-variable-name | D | F | Sets the return variable's name. (Default: `return_variable`)
return-type | D | F | Sets the Function's return type.  (Default: same as `return-variable-type` )
decl | | both | Custom declaration code. (Funtions automatically declare the return variable)
bdy | D | both | Custom body code. (Default `null;`) Functions always end with `return return_variable;`
parameters | | Both | Parameters for the Function/Procedure. use `teplsql.goto_tab(1)` for multiline parameters.

Legend
- **D** - Required. But, a default value is given.
- **F** - Only used for Functions

Supported sub-extensions
---
- select (produces a cursor)
- plsql-type
- procedure
- variables
- exception
- exception-block


exception
===
Generate code for a custom exception.

definable blocks
---
Block | req? | Description
------|------|--------------
name | D | name of the Exception. (default is the object's name)
Documentation |  | In-code documentation for the Exception.
number | D | Exception number. (Default: `-20000`).
text | D | The Text that is returned when this exception is raised
constant-number-name | | If defined, generates a constant variable based on the value for `number`
constant-text-name | | If defined, generates a constant based on the value for `text`.
exception-code | D | The code that is ran when an exception is raised. (Default: `raise_application_exception()`)

Legend
---
- **D** - Required. But, a default value is given.

executable blocks
----
Block | Description
------|-------------
when-clause | Generates code for the `WHEN` clause of the `EXCEPTION` clause.


exceptions-block
====
Generates code for the `exception` section of a procedure/function/package initialization.

**note** the object's name is only used for ordering of the generated code

definable blocks
---
Block | req? |Description
------|------|-----------
body | Y | Must generate the `WHEN` clause for an `EXCEPTION` clause

Legend
---
- **Y** - Required.

