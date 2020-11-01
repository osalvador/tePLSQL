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
      <TEMPLATE>create or replace
package body &lt;%= lower( &apos;${schema}&apos; ) %&gt;.&lt;%@ include( ${this}.name ) %&gt;\\n
as
&lt;%@ include( ${this}.select.private.*.specification, , , ,1 ) %&gt;\\n
&lt;%@ include( ${this}.plsql-type.private.*.specification, , , ,1 ) %&gt;\\n
&lt;%@ include( ${this}.exception.private.*.specification, , , ,1 ) %&gt;\\n
&lt;%@ include( ${this}.procedure.private.*.body, , , ,1 ) %&gt;\\n
&lt;%@ include( ${this}.procedure.*.body, , , ,1 ) %&gt;\\n
&lt;% if teplsql.template_exists( &apos;${this}.init&apos; )
then %&gt;
begin
&lt;%@ include( ${this}.init, , , ,1 ) %&gt;
&lt;% if teplsql.template_exists( &apos;${this}.exceptions-block.*.body&apos; ) then %&gt;
exception
&lt;%@ include( ${this}.exceptions-block.*.body, , , ,1 ) %&gt;\\n
&lt;% end if; %&gt;
&lt;% end if; %&gt;
end;
&lt;%= &apos;/&apos; %&gt;\\n
</TEMPLATE>
      <DESCRIPTION>code to generate the BODY of the package</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.package.specification</NAME>
      <TEMPLATE>create or replace
package &lt;%= lower(&apos;${schema}&apos;) %&gt;.&lt;%@ include( ${this}.name ) %&gt;\\n
&lt;%@ include( ${this}.authid-spec, , , ,1 ) %&gt;\\n
&lt;% if teplsql.template_exists( &apos;${this}.accessibility&apos; ) then %&gt;
&lt;%@ include( ${this}.access-spec, , , ,1 ) %&gt;&lt;% end if; %&gt;
as
&lt;%@ include( ${this}.documentation, , , ,1 ) %&gt;

&lt;%@ include( ${this}.select.*.specification, , , ,1 ) %&gt;\\n

&lt;%@ include( ${this}.plsql-type.*.specification, , , ,1 ) %&gt;\\n

&lt;%@ include( ${this}.variable.*.specification, , , ,1 ) %&gt;\\n

&lt;%@ include( ${this}.exception.*.specification, , , ,1 ) %&gt;\\n

&lt;%@ include( ${this}.procedure.*.specification, , , ,1 ) %&gt;\\n

end;
&lt;%= &apos;/&apos; %&gt;
</TEMPLATE>
      <DESCRIPTION>code to generate the specification</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.select.SQL</NAME>
      <TEMPLATE>select * from dual</TEMPLATE>
      <DESCRIPTION>The actual SQL statement</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.select.name</NAME>
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
      <NAME>teplsql.helper.default.plsql-type.rcd-spec</NAME>
      <TEMPLATE>type &lt;%@ include( ${this}.name ) %&gt; is record &lt;%@ include( ${this}.record ) %&gt;;</TEMPLATE>
      <DESCRIPTION>specification for RECORD TYPE.</DESCRIPTION>
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
                      ,rpad(o.column_name
                          ,max(length(o.column_name)) over () + 1 ) column_name_rpad
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
      <NAME>teplsql.helper.default.select.documentation</NAME>
      <TEMPLATE>/**
* SQL &lt;%@ include( ${this}.name ) %&gt;\\n
*/
</TEMPLATE>
      <DESCRIPTION>Documentation for the SQL in PL/doc format</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.exception.documentation</NAME>
      <TEMPLATE>/**
*  Something didn&apos;t do what it was suppose to do.
*/
</TEMPLATE>
      <DESCRIPTION>Documentation of the exception in PL/Doc format</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.package.documentation</NAME>
      <TEMPLATE>/**
* Place Description of Package here
*
* @headcom
*/
</TEMPLATE>
      <DESCRIPTION>PL/Doc encoded documentation</DESCRIPTION>
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
      <NAME>teplsql.helper.default.select.make</NAME>
      <TEMPLATE>create or replace
view ${schema}.&lt;%@ include( ${this}.name )%&gt;\\n
as
&lt;%@ include( ${this}.SQL )%&gt;;
</TEMPLATE>
      <DESCRIPTION>creates the VIEW</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.exception.specification</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.documentation ) %&gt;
&lt;%@ include( ${this}.name ) %&gt;  exception;
&lt;% if teplsql.template_exists( &apos;${this}.constant-number-name&apos; ) then %&gt;
&lt;%@ include( ${this}.constant-text-name ) %&gt; constant varchar2(1024) := &lt;%@ include( ${this}.text ) %&gt;;
&lt;% end if; %&gt;
&lt;% if teplsql.template_exists( &apos;${this}.constant-number-name&apos; ) then %&gt;
&lt;%@ include( ${this}.constant-number-name ) %&gt; constant int := &lt;%@ include( ${this}.number ) %&gt;;
pragma exception_init( &lt;%@ include( ${this}.name ) %&gt;, &lt;%@ include( ${this}.constant-number-name ) %&gt; );
&lt;% else %&gt;
pragma exception_init( &lt;%@ include( ${this}.name ) %&gt;, &lt;%@ include( ${this}.number ) %&gt; );
&lt;% end if; %&gt;
</TEMPLATE>
      <DESCRIPTION>specification for all parts of an exception.</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.exception.when-clause</NAME>
      <TEMPLATE>when &lt;%@ include( ${this}.name ) %&gt; then
&lt;%@ include( ${this}.exception-code, , , ,1 ) %&gt;
</TEMPLATE>
      <DESCRIPTION>Exception where clause for this exception.</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.plsql-type.specification</NAME>
      <TEMPLATE>&lt;% if teplsql.template_exists( &apos;${this}.documentation&apos; ) then %&gt;
&lt;%@ include( ${this}.documentation ) %&gt;
&lt;% end if; %&gt;
&lt;% if teplsql.template_exists( &apos;${this}.data-type&apos; ) then %&gt;
&lt;%@ include( ${this}.subtype-spec ) %&gt;\\n
&lt;% elsif teplsql.template_exists( &apos;${this}.record&apos; ) then %&gt;
&lt;%@ include( ${this}.rcd-spec ) %&gt;\\n
&lt;% else %&gt;
-- missing &lt;block&gt; for &apos;${object_name}&apos; - need to define &quot;data-type&quot; or &quot;record&quot;
&lt;% end if; %&gt;
&lt;% if teplsql.template_exists( &apos;${this}.nt-name&apos; ) then %&gt;
&lt;%@ include( ${this}.nt-spec ) %&gt;\\n
&lt;% end if; %&gt;
&lt;% if teplsql.template_exists( &apos;${this}.aa-name&apos; ) then %&gt;
&lt;%@ include( ${this}.aa-spec ) %&gt;\\n
&lt;% end if; %&gt;
&lt;% if teplsql.template_exists( &apos;${this}.ref-name&apos; ) then %&gt;
&lt;%@ include( ${this}.ref-spec ) %&gt;\\n
&lt;% end if; %&gt;\\n
</TEMPLATE>
      <DESCRIPTION>Creates the specification for a record, nested tab</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.plsql-type.aa-spec</NAME>
      <TEMPLATE>&lt;% if teplsql.template_exists( &apos;${this}.aa-key-data-type&apos; ) then %&gt;
type &lt;%@ include( ${this}.aa-name ) %&gt; is table of &lt;%@ include( ${this}.name ) %&gt; index by &lt;%@ include( ${this}.aa-key-data-type ) %&gt;;&lt;% else %&gt;
type &lt;%@ include( ${this}.aa-name ) %&gt; is table of &lt;%@ include( ${this}.name ) %&gt; index by pls_integer;&lt;% end if; %&gt;</TEMPLATE>
      <DESCRIPTION>Creates the Associative Array TYPE</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.plsql-type.nt-spec</NAME>
      <TEMPLATE>type &lt;%@ include( ${this}.nt-name ) %&gt; is table of &lt;%@ include( ${this}.name ) %&gt;;</TEMPLATE>
      <DESCRIPTION>specification for the Nested Table TYPE</DESCRIPTION>
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
    <template>
      <NAME>teplsql.helper.default.exception.raise-error</NAME>
      <TEMPLATE>raise_application_error( &lt;% if teplsql.template_exists( &apos;${this}.constant-number-name&apos; ) then %&gt;
&lt;%@ include( ${this}.constant-number-name) %&gt;&lt;% else %&gt;
&lt;%@ include( ${this}.number) %&gt;&lt;% end if; %&gt;, &lt;% if teplsql.template_exists( &apos;${this}.constant-text-name&apos; ) then %&gt;
&lt;%@ include( ${this}.constant-text-name) %&gt;&lt;% else %&gt;
&lt;%@ include( ${this}.text ) %&gt;&lt;% end if; %&gt; );
</TEMPLATE>
      <DESCRIPTION>PL/Sql code that runs inside an EXCEPTION block</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-15</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-15</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.package.initialization</NAME>
      <TEMPLATE>begin
&lt;%@ include( ${this}.init, , , ,1 ) %&gt;
end;
</TEMPLATE>
      <DESCRIPTION>Package initialization block.</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-05</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-05</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.package.authid</NAME>
      <TEMPLATE>current_user</TEMPLATE>
      <DESCRIPTION>Set package as Definer&apos;s Rights or Invoker&apos;s Rights (default)</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-29</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-29</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.procedure.return-variable-name</NAME>
      <TEMPLATE>return_variable</TEMPLATE>
      <DESCRIPTION>variable name for return value</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-06</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-06</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.procedure.decl</NAME>
      <TEMPLATE>-- set variables here
</TEMPLATE>
      <DESCRIPTION>variable/type/function/cursor definitions go her</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-03</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-03</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.procedure.documentation</NAME>
      <TEMPLATE>/**
*  Procedure &lt;%@ include( ${this}.name ) %&gt;\\n
*/
</TEMPLATE>
      <DESCRIPTION>PL/Doc encoded documentation</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-03</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-03</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.procedure.name</NAME>
      <TEMPLATE>${object_name}</TEMPLATE>
      <DESCRIPTION>Name of the Function/Procedure</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-03</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-03</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.procedure.spec</NAME>
      <TEMPLATE>&lt;% if teplsql.template_exists( &apos;${this}.return-variable-type&apos; ) then %&gt;
function &lt;%@ include( ${this}.name ) %&gt; &lt;% if teplsql.template_exists( &apos;${this}.parameters&apos; ) then
  teplsql.set_tab(1); %&gt;(&lt;%@ include( ${this}.parameters ) %&gt;)
&lt;% teplsql.goto_tab(1); %&gt;return &lt;%@ include( ${this}.return-type ) %&gt;&lt;% else %&gt;
return &lt;%@ include( ${this}.return-type ) %&gt;&lt;% end if; %&gt;
&lt;% else %&gt;
procedure &lt;%@ include( ${this}.name ) %&gt;&lt;% if teplsql.template_exists( &apos;${this}.parameters&apos; ) then 
  teplsql.set_tab(1); %&gt;(&lt;%@ include( ${this}.parameters ) %&gt;)&lt;% end if; %&gt;
&lt;% end if; %&gt;
</TEMPLATE>
      <DESCRIPTION>shortline specification for function/procedure</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-03</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-03</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.procedure.specification</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.documentation ) %&gt;
&lt;%@ include( ${this}.spec ) %&gt;;
</TEMPLATE>
      <DESCRIPTION>Specification of the function for a Package</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-03</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-03</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.procedure.bdy</NAME>
      <TEMPLATE>-- &lt;block&gt;=bdy for &lt;procedure&gt;=${object_name} not defined
null;</TEMPLATE>
      <DESCRIPTION>The body of the code</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-03</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-03</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.procedure.body</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.spec ) %&gt;\\n
as
&lt;%@ include( ${this}.select.*.specification, , , ,1 ) %&gt;
&lt;%@ include( ${this}.plsql-type.*.specification, , , ,1 ) %&gt;
&lt;%@ include( ${this}.exception.*.specification, , , ,1 ) %&gt;
&lt;% if teplsql.template_exists( &apos;${this}.return-variable-type&apos; ) then %&gt;
&lt;%@ include( ${this}.return-decl, , , ,1 ) %&gt;
&lt;% end if; %&gt;
&lt;%@ include( ${this}.decl, , , ,1 ) %&gt;
&lt;%@ include( ${this}.procedure.*.body, , , ,1 ) %&gt;
\\nbegin
&lt;%@ include( ${this}.bdy, , , ,1 ) %&gt;\\n
&lt;% if teplsql.template_exists( &apos;${this}.return-variable-type&apos; ) then %&gt;
\\n
&lt;%@ include( ${this}.return-spec, , , ,1 ) %&gt;
&lt;% end if; %&gt;
&lt;% if teplsql.template_exists( &apos;${this}.exceptions-block.*.body&apos; ) then %&gt;
exception
&lt;%@ include( ${this}.exceptions-block.*.body, , , ,1 ) %&gt;\\n
&lt;% end if; %&gt;
end &lt;%@ include( ${this}.name ) %&gt;;
</TEMPLATE>
      <DESCRIPTION>Body of the function for a Package</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-03</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-03</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.procedure.return-type</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.return-variable-type ) %&gt;</TEMPLATE>
      <DESCRIPTION>return data type (if a function)</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-06</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-06</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.plsql-type.name</NAME>
      <TEMPLATE>${object_name}</TEMPLATE>
      <DESCRIPTION>name of PL/SQL (sub)type</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-06</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-06</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.plsql-type.ref-spec</NAME>
      <TEMPLATE>type &lt;%@ include( ${this}.ref-name ) %&gt; is ref cursor return &lt;%@ include( ${this}.name ) %&gt;;</TEMPLATE>
      <DESCRIPTION>specification for REF type</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-06</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-06</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.select.specification</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.documentation ) %&gt;
cursor &lt;%@ include( ${this}.spec ) %&gt; is
&lt;%@ include( ${this}.SQL, , , ,1 ) %&gt;;
</TEMPLATE>
      <DESCRIPTION>Creates a CURSOR for PL/SQL</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-30</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-30</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.select.spec</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.name ) %&gt;&lt;% if teplsql.template_exists( &apos;${this}.parameters&apos; ) then %&gt;(&lt;% teplsql.set_tab(1); %&gt;
&lt;%@ include( ${this}.parameters ) %&gt; )&lt;% end if; %&gt;</TEMPLATE>
      <DESCRIPTION>spec portion of a CURSOR</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-08-30</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-08-30</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.plsql-type.subtype-spec</NAME>
      <TEMPLATE>subtype &lt;%@ include( ${this}.name ) %&gt; is &lt;%@ include( ${this}.data-type ) %&gt;;</TEMPLATE>
      <DESCRIPTION>specification for RECORD TYPE.</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-06</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-06</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.exception.exception-code</NAME>
      <TEMPLATE>-- default exception process
&lt;%@ include( ${this}.raise-error ) %&gt;
</TEMPLATE>
      <DESCRIPTION>Actual code to run when the exception is encountered</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-05</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-05</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.variable.name</NAME>
      <TEMPLATE>${object_name}</TEMPLATE>
      <DESCRIPTION>name of the variable</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-05</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-05</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.variable.data-type</NAME>
      <TEMPLATE>undefined</TEMPLATE>
      <DESCRIPTION>data type of the variable</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-05</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-05</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.variable.specification</NAME>
      <TEMPLATE>&lt;% if teplsql.template_exists( &apos;${this}.documentation&apos; )
then %&gt;
&lt;%@ include( ${this}.documentation ) %&gt;
&lt;% end if; %&gt;
&lt;%@ include( ${this}.name ) %&gt; &lt;% if teplsql.template_exists(&apos;${this}.constant-value&apos; )
then
%&gt;constant &lt;%@ include( ${this}.data-type ) %&gt; := &lt;%@ include( ${this}.constant-value ) %&gt;;
&lt;% elsif teplsql.template_exists(&apos;${this}.value&apos; )
then
%&gt; &lt;%@ include( ${this}.data-type ) %&gt; := &lt;%@ include( ${this}.value ) %&gt;;
&lt;% else %&gt;
&lt;%@ include( ${this}.data-type ) %&gt;;
&lt;% end if; %&gt;
</TEMPLATE>
      <DESCRIPTION>specification line</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-05</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-05</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.procedure.return-spec</NAME>
      <TEMPLATE>return &lt;%@ include( ${this}.return-variable-name ) %&gt;;
</TEMPLATE>
      <DESCRIPTION>return statement</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-06</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-06</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.procedure.return-decl</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.return-variable-name ) %&gt;    &lt;%@ include( ${this}.return-variable-type ) %&gt;;
</TEMPLATE>
      <DESCRIPTION>return variable declaration</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-06</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-06</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.procedure.make</NAME>
      <TEMPLATE>create or replace
&lt;%@ include( ${this}.body ) %&gt;
&lt;%= &apos;/&apos; %&gt;
</TEMPLATE>
      <DESCRIPTION>make a standalone procedure/function</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-07</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-07</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.select.cte</NAME>
      <TEMPLATE>&lt;%@ include( ${this}.name ) %&gt; as (
&lt;%@ include( ${this}.SQL , , , ,1 ) %&gt;\\n
)</TEMPLATE>
      <DESCRIPTION>Create a CTE (does not have WITH keyword)</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-07</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-07</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.package.authid-spec</NAME>
      <TEMPLATE>authid &lt;%@ include( ${this}.authid ) %&gt;
</TEMPLATE>
      <DESCRIPTION>creates the AUTHID line</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-07</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-07</MODIFIED_DATE>
    </template>
    <template>
      <NAME>teplsql.helper.default.package.access-spec</NAME>
      <TEMPLATE>accessible by (&lt;% teplsql.set_tab(1); %&gt;&lt;%@ include( ${this}.accessibility ) %&gt; )
</TEMPLATE>
      <DESCRIPTION>creates the ACCESSIBLE BY line</DESCRIPTION>
      <CREATED_BY>TEPLSQL$SYS</CREATED_BY>
      <CREATED_DATE>2020-10-07</CREATED_DATE>
      <MODIFIED_BY>TEPLSQL$SYS</MODIFIED_BY>
      <MODIFIED_DATE>2020-10-07</MODIFIED_DATE>
    </template>
  </templates>
</teplsql>
$end
    
end te_default_helper_templates;
/
