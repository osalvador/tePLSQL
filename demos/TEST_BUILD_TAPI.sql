create or replace procedure test_build_tapi
as
    xml_dat xmltype;
    str     varchar2(50);
    buffer_clob clob;
    t_clob clob;
    txt_clob clob;
    att_clob clob;
    build_xml xmltype;

    p_vars           teplsql.t_assoc_array;
    v_returnvalue    clob;
    p_template       clob;
    p_error_template clob;
begin
    dbms_output.put_line( 'fetching build template' );
    p_vars( teplsql.g_set_render_mode ) := teplsql.g_render_mode_fetch_only;
    buffer_clob := teplsql.process( p_vars, 'TestBuild', 'TEST_BUILD_TAPI', 'PROCEDURE' );

    dbms_output.put_line( 'converting to XML clob' );
    teplsql.validate_build_template( buffer_clob );
    buffer_clob := teplsql.convert_extends( buffer_clob );

    dbms_output.put_line( 'converting to XMLType');
    build_xml := xmltype ( buffer_clob );

    dbms_output.put_line( 'creating templates from Build XML' );    
    str := teplsql.build_code_from_xml( build_xml, 'stuff.morestufff' );

    dbms_output.put_line( 'Rendering "' || str || '.main"' );
    -- template variables
    p_vars( 'schema' )                        := 'TEPLSQL$SYS';
    p_vars( 'table_name' )                    := 'TE_TEMPLATES';

    -- generator system options
    p_vars( teplsql.g_set_max_includes )      := 500;
    p_vars( teplsql.g_set_globbing_mode )     := teplsql.g_globbing_mode_on;
    p_vars( teplsql.g_set_render_mode )       := teplsql.g_render_mode_normal;

    -- the template
    p_template     := '<%@ include( ' || str || '.main ) %>';

    -- actual render
    v_returnvalue  := teplsql.render( p_vars => p_vars
                                     ,p_template => p_template
                                     ,p_error_template => p_error_template
                        );

    dbms_output.put_line( v_returnvalue );
exception
    when others then
        dbms_output.put_line( p_error_template );
        raise;

$if false $then
<%@ template( template_name=TestBuild ) %>
<%@ extends object_type="build" object_name="TAPI" %>
  <%@ extends object_type="package" object_name="simple_tapi" %>
    <%@ block fragment_name="name" %>POC_${table_name}_API<%@ enblock %>
    <%@ extends object_type="exception" object_name="not_yet_implemented" %>
      <%@ block fragment_name="text" %>'This feature has not yet been implemented.'<%@ enblock %>
      <%@ block fragment_name="number" %>-20100<%@ enblock %>
    <%@ enextends %>
    <%@ extends object_type="function" object_name="ins" %>
      <%@ block fragment_name="spec" %>procedure <%@ include( ${this}.name ) %>( rcd in ${schema}.${table_name}%rowtype )<%@ enblock %>
      <%@ block fragment_name="documentation" %>/**
* new row entry
*/<%@ enblock %>
      <%@ block fragment_name="bdy" %>
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
      <%@ block fragment_name="spec" %>procedure <%@ include( ${this}.name ) %>( rcd in ${schema}.${table_name}%rowtype )<%@ enblock %>
      <%@ block fragment_name="documentation" %>/**
* updates a row
*/<%@ enblock %>
      <%@ block fragment_name="bdy" %>-- THIS = ${this}
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
      <%@ block fragment_name="spec" %>procedure <%@ include( ${this}.name ) %>( rcd in ${schema}.${table_name}%rowtype )<%@ enblock %>
      <%@ block fragment_name="documentation" %>/**
* deletes a record
*/<%@ enblock %>
      <%@ block fragment_name="bdy" %>
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
