create or replace
procedure build_hello_world( indent_string in varchar2 default '    ' )
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
    buffer_clob := teplsql.process( p_vars, 'HelloWorld', 'BUILD_HELLO_WORLD', 'PROCEDURE' );

    dbms_output.put_line( 'converting to XML clob' );
    teplsql.validate_build_template( buffer_clob );
    buffer_clob := teplsql.convert_extends( buffer_clob );

    dbms_output.put_line( 'converting to XMLType');
    build_xml := xmltype ( buffer_clob );

    dbms_output.put_line( 'creating templates from Build XML' );    
    str := teplsql.build_code_from_xml( build_xml, 'teplsq.demo_builds' );

    dbms_output.put_line( 'Rendering "' || str || '.main"' );
    -- template vars
    p_vars( 'schema' ) := USER;
    
    -- generator system options
    p_vars( teplsql.g_set_max_includes )      := 500;
    p_vars( teplsql.g_set_globbing_mode )     := teplsql.g_globbing_mode_on;
    p_vars( teplsql.g_set_render_mode )       := teplsql.g_render_mode_normal;
    p_vars( teplsql.g_set_indention_string )  := indent_string;
    

    -- the template
    p_template     := '<%@ include( ' || str || '.make ) %>';

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
<%@ template( template_name=HelloWorld ) %>
 <%@ extends object_type="package" object_name="my_pkg" %>
  <%@ extends object_type="function" object_name="outer_f" %>
   <%@ block block_name="spec" %>procedure <%@ include( ${this}.name ) %><%@ enblock %>
   <%@ block block_name="bdy" %><%@ include( ${this}.function.inner_f.name ) %>;
  <%@ enblock %>
  <%@ extends object_type="function" object_name="inner_f" %>
   <%@ block block_name="spec" %>procedure <%@ include( ${this}.name ) %><%@ enblock %>
   <%@ block block_name="bdy" %>dbms_output.put_line( 'Hello World' );<%@ enblock %>
  <%@ enextends %>
 <%@ enextends %>
<%@ enextends %>
$end
end;
/