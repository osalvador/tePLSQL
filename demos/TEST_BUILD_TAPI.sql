create or replace procedure test_build_tapi( schema        in varchar2 default USER
                                            ,table_name    in varchar2 default 'TE_TEMPLATES'
                                            ,indent_string in varchar2 default '    ')
as
    p_vars           teplsql.t_assoc_array;
    v_returnvalue    clob;
    p_template       clob;
begin
    p_vars( 'schema' )                        := NVL( schema, USER );
    p_vars( 'table_name' )                    := nvl( table_name, 'TE_TEMPLATES' );
    p_vars( teplsql.g_set_indention_string )  := indent_string;


    v_returnvalue := teplsql.process_build( p_vars, 'TestBuild', 'TEST_BUILD_TAPI', 'PROCEDURE' );

    dbms_output.put_line( v_returnvalue );

$if false $then
<%@ template( template_name=TestBuild, build=main ) %>
<%@ extends object_type="build" object_name="TAPI" %>
  <%@ extends object_type="package" object_name="simple_tapi" %>
    <%@ block block_name="name" %>POC_${table_name}_API<%@ enblock %>
    <%@ extends object_type="exception" object_name="not_yet_implemented" %>
      <%@ block block_name="text" %>'This feature has not yet been implemented.'<%@ enblock %>
      <%@ block block_name="number" %>-20100<%@ enblock %>
    <%@ enextends %>
    <%@ extends object_type="function" object_name="ins" %>
      <%@ block block_name="spec" %>procedure <%@ include( ${this}.name ) %>( rcd in ${schema}.${table_name}%rowtype )<%@ enblock %>
      <%@ block block_name="documentation" %>/**
* new row entry
*/<%@ enblock %>
      <%@ block block_name="bdy" %>
insert into ${schema}.${table_name} (
<% for curr in "Columns"( '${schema}', '${table_name}', '-VC -ID' ) loop %>
                <%= curr.comma_first || curr.column_name %>\\\\n
<% end loop; %>
            ) values (
<% for curr in "Columns"( '${schema}', '${table_name}', '-VC -ID' ) loop
if curr.has_default='NO' then %>
                <%= curr.comma_first || 'rcd.' || curr.column_name %>\\\\n
<% else
declare
    str varchar2(4000) := curr.data_default;
begin
%>
                <%= curr.comma_first || 'nvl(rcd.' || curr.column_name || ', ' || trim(str) || ' )' %>\\\\n
<%
end;
end if;
end loop; %>
            );<%@ enblock %>
    <%@ enextends %>
    <%@ extends object_type="function" object_name="upd" %>
      <%@ block block_name="spec" %>procedure <%@ include( ${this}.name ) %>( rcd in ${schema}.${table_name}%rowtype )<%@ enblock %>
      <%@ block block_name="documentation" %>/**
* updates a row
*/<%@ enblock %>
      <%@ block block_name="bdy" %>-- THIS = ${this}
-- P = ${super}
-- GP = ${super.super}
update ${schema}.${table_name} a
    set
<% for curr in "Columns"( '${schema}', '${table_name}', '-VC -PK' ) loop %>
        a.<%= curr.column_name %> = rcd.<%= curr.column_name || curr.comma_last %>\\\\n
<% end loop; %>
    where 1=1
<% for curr in "Columns"( '${schema}', '${table_name}', 'PK' ) loop %>
        and a.<%= curr.column_name %> = rcd.<%= curr.column_name %>
<% end loop; %>
;<%@ enblock %>
    <%@ enextends %>
    <%@ extends object_type="function" object_name="del" %>
      <%@ block block_name="spec" %>procedure <%@ include( ${this}.name ) %>( rcd in ${schema}.${table_name}%rowtype )<%@ enblock %>
      <%@ block block_name="documentation" %>/**
* deletes a record
*/<%@ enblock %>
      <%@ block block_name="bdy" %>
delete from ${schema}.${table_name} a
    where 1=1
<% for curr in "Columns"( '${schema}', '${table_name}', 'PK' ) loop %>
        and a.<%= curr.column_name %> = rcd.<%= curr.column_name %>
<% end loop; %>;<%@ enblock %>
<%@ enextends %>
<%@ enextends %>
<%@ enextends %>

$end

end;
/
