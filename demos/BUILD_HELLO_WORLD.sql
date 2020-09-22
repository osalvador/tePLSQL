create or replace procedure build_hello_world( indent_string in varchar2 default '    ' )
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
 <%@ extends( package, my_pkg) %>
  <%@ extends( function, outer_f ) %>
   <%@ block( spec ) %>procedure <%@ include( ${this}.name ) %><%@ enblock %>
   <%@ block( bdy ) %><%@ include( ${this}.function.inner_f.name ) %>;
  <%@ enblock %>
  <%@ extends(function, inner_f ) %>
   <%@ block( spec ) %>procedure <%@ include( ${this}.name ) %><%@ enblock %>
   <%@ block( bdy ) %>dbms_output.put_line( 'Hello World' );<%@ enblock %>
  <%@ enextends %>
 <%@ enextends %>
<%@ enextends %>
$end
end;
