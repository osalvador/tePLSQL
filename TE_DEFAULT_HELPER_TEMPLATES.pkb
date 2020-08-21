create or replace
package body te_default_helper_templates
as
    procedure install_templates
    as
        t_clob   clob;
        p_vars   teplsql.t_assoc_array;
        imp      xmltype;
    begin
        -- get XML file of Helper Templates
        p_vars( teplsql.g_set_render_mode ) := teplsql.g_render_mode_fetch_only;
--        t_clob := teplsql.process( p_vars, 'DefaultHelperTemplates.xml', $$PLSQL_OBJECT );
        t_clob := teplsql.process( p_vars, 'DefaultHelperTemplates.xml', 'TE_DEFAULT_HELPER_TEMPLATES' );
        
        -- convert to XML
        imp := xmltype( t_clob );
        
        -- import
        te_templates_api.xml_import( imp, te_templates_api.g_import_overwrite );
    end install_templates;
    
    function base_name return te_templates.name%type
    as
    begin
        return g_base_name;
    end base_name;

$if false $then    
<%@ template( template_name=DefaultHelperTemplates.xml ) %>
<teplsql>
  <templates>
    <template>
      <NAME>teplsql.helper.default.function.name</NAME>
      <TEMPLATE>${object_name}</TEMPLATE>
      <DESCRIPTION>Name of the Function/Procedure</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.function.bdy</NAME>
      <TEMPLATE>     return NULL;
</TEMPLATE>
      <DESCRIPTION>The body of the code</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.function.decl</NAME>
      <TEMPLATE>-- set variables here</TEMPLATE>
      <DESCRIPTION>variable/type/function/cursor definitions go her</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.function.spec</NAME>
      <TEMPLATE>function &lt;%@ include( ${this}.name ) %&gt; return varchar2</TEMPLATE>
      <DESCRIPTION>shortline specification for function/procedure</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.package.name</NAME>
      <TEMPLATE>${object_name}</TEMPLATE>
      <DESCRIPTION>Name of the Function/Procedure</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.package.body</NAME>
      <TEMPLATE>CREATE OR REPLACE
PACKAGE BODY ${schema}.&lt;%@ include( ${this}.name ) %&gt;\\n
AS
&lt;%@ include( ${this}.function.*.body ) %&gt;\\n
END;
&lt;%= &apos;/&apos; %&gt;\\n</TEMPLATE>
      <DESCRIPTION>code to generate the BODY of the package</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.package.specification</NAME>
      <TEMPLATE>CREATE OR REPLACE
PACKAGE ${schema}.&lt;%@ include( ${this}.name ) %&gt;\\n
AS
&lt;%@ include( ${this}.documentation ) %&gt;

&lt;%@ include( ${this}.type.*.specification ) %&gt;\\n

&lt;%@ include( ${this}.exception.*.specification ) %&gt;\\n

&lt;%@ include( ${this}.function.*.specification ) %&gt;\\n
END;
&lt;%= &apos;/&apos; %&gt;</TEMPLATE>
      <DESCRIPTION>code to generate the specification</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.SQL.view_name</NAME>
      <TEMPLATE>${schema}.&lt;%@ include( ${this}.name ) %&gt;</TEMPLATE>
      <DESCRIPTION>View name of SQL</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.SQL.cursor_name</NAME>
      <TEMPLATE>c_&lt;%@ include( ${this}.name ) %&gt;</TEMPLATE>
      <DESCRIPTION>Name of cursor version of SQL</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.SQL.SQL</NAME>
      <TEMPLATE>select * from dual</TEMPLATE>
      <DESCRIPTION>The actual SQL statement</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.SQL.name</NAME>
      <TEMPLATE>${object_name}</TEMPLATE>
      <DESCRIPTION>Name of SQL statement</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.exception.number</NAME>
      <TEMPLATE>-20000</TEMPLATE>
      <DESCRIPTION>Exception Number</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.exception.text</NAME>
      <TEMPLATE>&apos;Something went wrong&apos;</TEMPLATE>
      <DESCRIPTION>Text displayed for a RAISE_APPLICATION_EXCEPTION.
(in PL/SQL code format)</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.exception.name</NAME>
      <TEMPLATE>${object_name}</TEMPLATE>
      <DESCRIPTION>name of the exception</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.exception.raise_error</NAME>
      <TEMPLATE>raise_application_error( &lt;%@ include( ${this}.number) %&gt;, &lt;%@ include( ${this}.text ) %&gt; );</TEMPLATE>
      <DESCRIPTION>PL/Sql code that runs inside an EXCEPTION block</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.type.rcd_spec</NAME>
      <TEMPLATE>SUBTYPE &lt;%@ include( ${this}.rcd_name ) %&gt; ${schema}.${table_name}%ROWTYPE;</TEMPLATE>
      <DESCRIPTION>specification for RECORD TYPE.</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.type.nt_name</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.base_name) %&gt;_nt</TEMPLATE>
      <DESCRIPTION>creates the name for the Nested Table TYPE.</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.type.rcd_name</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.base_name ) %&gt;_rcd</TEMPLATE>
      <DESCRIPTION>Creates the name for the RECORD TYPE</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.type.aa_name</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.base_name) %&gt;_aa</TEMPLATE>
      <DESCRIPTION>Name of the Associative Array TYPE</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.type.base_name</NAME>
      <TEMPLATE>${table_name}</TEMPLATE>
      <DESCRIPTION>common name for all related types</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.build.main</NAME>
      <TEMPLATE>&lt;%!
  cursor &quot;Columns&quot;( schema in varchar2, table_name in varchar2, search_str in varchar2 ) is
                  with PK_COLUMN_LIST as (
                    select c.owner,c.table_name,cc.column_name
                      ,decode(count(*) over (partition by c.owner,c.constraint_name),1,&apos;YES&apos;)
                        SINGLE_PK_COLUMN
                    from sys.all_constraints c
                     join sys.all_cons_columns cc
                       on c.owner=cc.owner and c.constraint_name=cc.constraint_name
                    where c.OWNER=&quot;Columns&quot;.schema
                      and c.TABLE_NAME=&quot;Columns&quot;.TABLE_NAME
                      and c.constraint_type=&apos;P&apos;
                  ), OWNER_TABLE_FILTERED_DATA as (
                    select
                       a.owner
                      ,a.table_name
                      ,a.column_name
                      ,a.data_type
                      ,a.data_type_mod
                      ,a.data_type_owner
                      ,a.data_length
                      ,a.data_precision
                      ,a.data_scale
                      ,a.CHAR_USED
                      ,decode(a.nullable,&apos;Y&apos;,&apos;YES&apos;,&apos;NO&apos;) as NULLABLE
                      ,a.column_id
                      ,a.data_default -- warning this is a LONG
                      ,case when a.data_default is not null then &apos;YES&apos; else &apos;NO&apos; end as HAS_DEFAULT
                      ,a.hidden_column IS_HIDDEN
                      ,a.VIRTUAL_COLUMN IS_VIRTUAL
                      ,a.QUALIFIED_COL_NAME
                      ,m.COMMENTS
                     $IF SYS.DBMS_DB_VERSION.VERSION &gt;= 12 $THEN
                      ,a.USER_GENERATED
                    $ELSE
                      ,NULL AS USER_GENERATED
                     $END
                      ,case a.data_type 
                        when &apos;CHAR&apos;     then
                          data_type||&apos;(&apos;||a.char_length||decode(char_used,&apos;B&apos;,&apos; BYTE&apos;,&apos;C&apos;,&apos; CHAR&apos;,null)||&apos;)&apos;
                        when &apos;VARCHAR&apos;  then
                          data_type||&apos;(&apos;||a.char_length||decode(char_used,&apos;B&apos;,&apos; BYTE&apos;,&apos;C&apos;,&apos; CHAR&apos;,null)||&apos;)&apos;
                        when &apos;VARCHAR2&apos; then
                          data_type||&apos;(&apos;||a.char_length||decode(char_used,&apos;B&apos;,&apos; BYTE&apos;,&apos;C&apos;,&apos; CHAR&apos;,null)||&apos;)&apos;
                        when &apos;NCHAR&apos;    then
                          data_type||&apos;(&apos;||a.char_length||decode(char_used,&apos;B&apos;,&apos; BYTE&apos;,&apos;C&apos;,&apos; CHAR&apos;,null)||&apos;)&apos;
                        when &apos;NUMBER&apos; then
                          case
                            when a.data_precision is null and a.data_scale is null
                            then
                              &apos;NUMBER&apos; 
                            when a.data_precision is null and a.data_scale is not null
                            then
                              &apos;NUMBER(38,&apos;||a.data_scale||&apos;)&apos; 
                            else
                              a.data_type||&apos;(&apos;||a.data_precision||&apos;,&apos;||a.data_SCALE||&apos;)&apos;
                            end    
                        when &apos;NVARCHAR&apos; then
                          a.data_type||&apos;(&apos;||a.char_length||decode(char_used,&apos;B&apos;,&apos; BYTE&apos;,&apos;C&apos;,&apos; CHAR&apos;,null)||&apos;)&apos;
                        when &apos;NVARCHAR2&apos; then
                          a.data_type||&apos;(&apos;||a.char_length||decode(char_used,&apos;B&apos;,&apos; BYTE&apos;,&apos;C&apos;,&apos; CHAR&apos;,null)||&apos;)&apos;    
                        else
                          a.data_type
                        end DATA_TYPE_DESC
                        ,nvl2(p.COLUMN_NAME,&apos;YES&apos;,&apos;NO&apos;)
                           as IS_PK
                      ,coalesce(
 $IF SYS.DBMS_DB_VERSION.VERSION &gt;= 12 $THEN
                            a.IDENTITY_COLUMN -- 12c+
 $ELSE
                            NULL -- pre-12c
 $END
                            ,decode(a.DATA_TYPE,&apos;NUMBER&apos;,p.SINGLE_PK_COLUMN)
                            ,&apos;NO&apos;
                        ) IS_ID
                    from SYS.ALL_TAB_COLS a
                      left outer join PK_COLUMN_LIST p
                        on a.OWNER=p.OWNER
                          and a.TABLE_NAME=p.TABLE_NAME
                          and a.COLUMN_NAME=p.COLUMN_NAME
                      left outer join SYS.ALL_COL_COMMENTS m
                        on a.OWNER=m.OWNER
                          and a.TABLE_NAME=m.TABLE_NAME
                          and a.COLUMN_NAME=m.COLUMN_NAME
                    where a.OWNER = &quot;Columns&quot;.schema
                      and a.TABLE_NAME = &quot;Columns&quot;.TABLE_NAME
                      and a.COLUMN_ID is not null -- VCs for FBIs
                  ), OPTION_FILTERED_DATA as (
                    select 
                       f.owner
                      ,f.table_name
                      ,f.column_name
                      ,f.data_type
                      ,f.data_type_mod
                      ,f.data_type_owner
                      ,f.data_length
                      ,f.data_precision
                      ,f.data_scale
                      ,f.CHAR_USED
                      ,f.nullable
                      ,f.column_id
                      ,f.has_default
                      ,f.data_default
                      ,f.is_hidden
                      ,f.is_virtual
                      ,f.QUALIFIED_COL_NAME
                      ,f.DATA_TYPE_DESC
                      ,f.IS_PK
                      ,f.is_id
                      ,f.COMMENTS
                      ,f.USER_GENERATED
                    from OWNER_TABLE_FILTERED_DATA f
                    where 
                    ( -- include
                        ((&quot;Columns&quot;.search_str is null  or not regexp_like( &quot;Columns&quot;.search_str, &apos;(^| )[[:alpha:]]+&apos; ))
                        and f.is_hidden &lt;&gt; &apos;YES&apos;)
                        or (regexp_like( &quot;Columns&quot;.search_str, &apos;(^| )[[:alpha:]]+&apos; )
                            and (1 = case
                                        when regexp_like( &quot;Columns&quot;.search_str, &apos;(^| )PK&apos;)       and IS_PK=&apos;YES&apos; then 1
                                        when regexp_like( &quot;Columns&quot;.search_str, &apos;(^| )VC&apos;)       and IS_VIRTUAL=&apos;YES&apos; then 1
                                        when regexp_like( &quot;Columns&quot;.search_str, &apos;(^| )HIDDEN&apos;)   and IS_HIDDEN=&apos;YES&apos; then 1
                                        when regexp_like( &quot;Columns&quot;.search_str, &apos;(^| )ID&apos;)       and IS_ID=&apos;YES&apos; then 1
                                        when regexp_like( &quot;Columns&quot;.search_str, &apos;(^| )NULLABLE&apos;) and NULLABLE=&apos;YES&apos; then 1
                                        else 0
                                    end
                            )
                            or 1 = case
                                        when &quot;Columns&quot;.search_str like &apos;%+PK%&apos;       and is_pk=&apos;YES&apos; then 1
                                        when &quot;Columns&quot;.search_str like &apos;%+VC%&apos;       and is_virtual=&apos;YES&apos; then 1
                                        when &quot;Columns&quot;.search_str like &apos;%+HIDDEN%&apos;   and is_hidden=&apos;YES&apos; then 1
                                        when &quot;Columns&quot;.search_str like &apos;%+ID%&apos;       and is_id=&apos;YES&apos; then 1
                                        when &quot;Columns&quot;.search_str like &apos;%+NULLABLE%&apos; and nullable=&apos;YES&apos; then 1
                                    else 0
                                end
                            ) )
                            -- exclude
                            and not 1 = case
                                            when &quot;Columns&quot;.search_str like &apos;%-PK%&apos;       and is_pk=&apos;YES&apos; then 1
                                            when &quot;Columns&quot;.search_str like &apos;%-VC%&apos;       and is_virtual=&apos;YES&apos; then 1
                                            when &quot;Columns&quot;.search_str like &apos;%-HIDDEN%&apos;   and is_hidden=&apos;YES&apos; then 1
                                            when &quot;Columns&quot;.search_str like &apos;%-ID%&apos;       and is_id=&apos;YES&apos; then 1
                                            when &quot;Columns&quot;.search_str like &apos;%-NULLABLE%&apos; and nullable=&apos;YES&apos; then 1
                                        else 0
                                    end
                  ), data as (
                    select
                       o.owner
                      ,o.table_name
                      ,o.column_name
                      ,o.data_type
                      ,o.data_type_mod
                      ,o.data_type_owner
                      ,o.data_length
                      ,o.data_precision
                      ,o.data_scale
                      ,o.CHAR_USED
                      ,o.nullable
                      ,o.column_id
                      ,o.has_default
                      ,o.data_default
                      ,o.is_hidden
                      ,o.is_virtual
                      ,o.QUALIFIED_COL_NAME
                      ,o.DATA_TYPE_DESC
                      ,o.IS_PK
                      ,o.is_ID
                      ,o.COMMENTS
                      ,row_number() over (partition by o.OWNER,o.TABLE_NAME order by o.COLUMN_ID)
                          as ORDER_BY
                      ,decode( row_number() over (partition by o.OWNER,o.TABLE_NAME order by o.COLUMN_ID)
                                ,1, &apos; &apos;, &apos;,&apos; ) as COMMA_FIRST
                      ,row_number() over (partition by o.OWNER,o.TABLE_NAME order by o.COLUMN_ID desc)
                          as ORDER_BY_DESC
                      ,decode( row_number() over (partition by o.OWNER,o.TABLE_NAME order by o.COLUMN_ID desc)
                                ,1, &apos; &apos;, &apos;,&apos; ) as COMMA_LAST
                      from OPTION_FILTERED_DATA o
                  )
                  select *
                  from data d
                  order by OWNER,TABLE_NAME,ORDER_BY;
%&gt;

/*
  Building for ${this}

  Time       : &lt;%= systimestamp %&gt;\\n
  Schema     : ${schema}
  Table Name : ${table_name}
*/

-- simple make all
&lt;%@ include( ${this}.*.*.make ) %&gt;</TEMPLATE>
      <DESCRIPTION>top-level Build</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.SQL.documentation</NAME>
      <TEMPLATE>/**
  SQL &lt;%@ include( ${this}.name ) %&gt;

*/</TEMPLATE>
      <DESCRIPTION>Documentation for the SQL in PL/doc format</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.exception.documentation</NAME>
      <TEMPLATE>/**
  Something didn&apos;t do what it was suppose to
*/</TEMPLATE>
      <DESCRIPTION>Documentation of the exception in PL/Doc format</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.function.documentation</NAME>
      <TEMPLATE>/**
  Function &lt;%@ include( ${this}.name ) %&gt;
*/</TEMPLATE>
      <DESCRIPTION>PL/Doc encoded documentation</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.package.documentation</NAME>
      <TEMPLATE>/**
      Place Description of Package here
@headcom
*/
</TEMPLATE>
      <DESCRIPTION>PL/Doc encoded documentation</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.function.body</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.spec ) %&gt;\\n
AS
&lt;%@ include( ${this}.type.*.specification ) %&gt;\\n
&lt;%@ include( ${this}.exception.*.specification ) %&gt;\\n
&lt;%@ include( ${this}.decl ) %&gt;\\n
&lt;%@ include( ${this}.function.*.body ) %&gt;\\n
BEGIN
&lt;%@ include( ${this}.bdy ) %&gt;\\n
END &lt;%@ include( ${this}.name ) %&gt;;\\n</TEMPLATE>
      <DESCRIPTION>Body of the function for a Package</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.function.specification</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.documentation ) %&gt;\\n
&lt;%@ include( ${this}.spec ) %&gt;;</TEMPLATE>
      <DESCRIPTION>Specification of the function for a Package</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.package.make</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.specification ) %&gt;

&lt;%@ include( ${this}.body ) %&gt;</TEMPLATE>
      <DESCRIPTION>makes both specification followed by the body</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.package.init</NAME>
      <TEMPLATE>  BEGIN
    NULL;
  end;

</TEMPLATE>
      <DESCRIPTION>Initialization code for the package</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.SQL.make_view</NAME>
      <TEMPLATE>create or replace
view &lt;%@ include( ${this}.view_name )%&gt;\\n
as
&lt;%@ include( ${this}.SQL )%&gt;
;</TEMPLATE>
      <DESCRIPTION>creates the VIEW</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.exception.specification</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.name ) %&gt;  exception;
&lt;%@ include( ${this}.constant_number_name ) %&gt; constant int := &lt;%@ include( ${this}.number ) %&gt;;
&lt;%@ include( ${this}.constant_text_name ) %&gt; constant varchar2(4000) := &apos;&lt;%@ include( ${this}.name ) %&gt;&apos;;
pragma exception_init( &lt;%@ include( ${this}.name ) %&gt;, &lt;%@ include( ${this}.constant_number_name ) %&gt; );</TEMPLATE>
      <DESCRIPTION>specification for all parts of an exception.</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.exception.constant_text_name</NAME>
      <TEMPLATE>g_&lt;%@ include( ${this}.name ) %&gt;_txt</TEMPLATE>
      <DESCRIPTION>constant that hold the exception name as a varchar</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.exception.constant_number_name</NAME>
      <TEMPLATE>g_&lt;%@ include( ${this}.name ) %&gt;#</TEMPLATE>
      <DESCRIPTION>name of the constant that holds the error number.</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.exception.exception</NAME>
      <TEMPLATE>when &lt;%@ include( ${this}.name ) %&gt; then
    &lt;%@ include( ${this}.plsql ) %&gt;</TEMPLATE>
      <DESCRIPTION>Exception where clause for this exception.</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.type.specification</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.documentation ) %&gt;\\n
&lt;%@ include( ${this}.rcd_spec ) %&gt;\\n
&lt;%@ include( ${this}.nt_spec ) %&gt;\\n
&lt;%@ include( ${this}.aa_spec ) %&gt;\\n</TEMPLATE>
      <DESCRIPTION>Creates the specification for a record, nested tab</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.type.aa_spec</NAME>
      <TEMPLATE>TYPE &lt;%@ include( ${this}.aa_name ) %&gt; is table of &lt;%@ include( ${this}.rcd_name ) %&gt; index by pls_integer;</TEMPLATE>
      <DESCRIPTION>Creates the Associative Array TYPE</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.type.nt_spec</NAME>
      <TEMPLATE>TYPE &lt;%@ include( ${this}.nt_name ) %&gt; is table of &lt;%@ include( ${this}.rcd_name ) %&gt;;</TEMPLATE>
      <DESCRIPTION>specification for the Nested Table TYPE</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.type.documentation</NAME>
      <TEMPLATE>/*
  Description of this type
*/</TEMPLATE>
      <DESCRIPTION>PL/Doc style comments</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.function</NAME>
      <TEMPLATE>CREATE OR REPLACE
&lt;%= &apos;&lt;&apos; %&gt;%@ include( ${this}.spec ) %&lt;%= &apos;&gt;&apos; %&gt;&lt;%= &apos;\&apos; || &apos;\&apos; || &apos;n&apos; %&gt;
AS
&lt;%= &apos;&lt;&apos; %&gt;%@ include( ${this}.decl ) %&lt;%= &apos;&gt;&apos; %&gt;&lt;%= &apos;\&apos; || &apos;\&apos; || &apos;n&apos; %&gt;
BEGIN
&lt;%= &apos;&lt;&apos; %&gt;%@ include( ${this}.bdy ) %&lt;%= &apos;&gt;&apos; %&gt;&lt;%= &apos;\&apos; || &apos;\&apos; || &apos;n&apos; %&gt;
END;
&lt;%= &apos;&lt;&apos; %&gt;%= &apos;/&apos; %&lt;%= &apos;&gt;&apos; %&gt;&lt;%= &apos;\&apos; || &apos;\&apos; || &apos;n&apos; %&gt;</TEMPLATE>
      <DESCRIPTION>Template for a Standalone function</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
  </templates>
</teplsql>
$end
    
end te_default_helper_templates;
/
