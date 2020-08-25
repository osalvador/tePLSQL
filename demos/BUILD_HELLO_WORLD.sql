create or replace
procedure build_hello_world( indent_string in varchar2 default '    ' )
as
    p_vars           teplsql.t_assoc_array;
    v_returnvalue    clob;
    p_template       clob;
begin
    p_vars( 'schema' ) := USER;
    p_vars( teplsql.g_set_indention_string )  := indent_string;


    v_returnvalue := teplsql.process_build( p_vars, 'HelloWorld', 'BUILD_HELLO_WORLD', 'PROCEDURE' );

    dbms_output.put_line( v_returnvalue );
  
$if false $then
<%@ template( template_name=HelloWorld, build=make ) %>
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