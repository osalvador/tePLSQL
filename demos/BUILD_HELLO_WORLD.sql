create or replace procedure build_hello_world( indent_string in varchar2 default '    ' )
  authid current_user
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
  <%@ block( init ) %>-- package init block
dbms_output.put_line( 'Package Initialization' );
<%@ enblock %>
  <%@ extends( variable, pi ) %>
    <%@ block( data-type ) %>number<%@ enblock %>
    <%@ block( constant-value ) %>3.14159<%@ enblock %>
    <%@ block( documentation ) %>-- the circle is now complete\\\\n<%@ enblock %>
  <%@ enextends %>
  <%@ extends( variable, g_hw ) %>
    <%@ block( data-type ) %><%@ include( ${super.super}.plsql-type.c1_t.name ) %><%@ enblock %>
    <%@ block( value ) %>'hello'<%@ enblock %>
  <%@ enextends %>
  <%@ extends( variable, foo ) %>
    <%@ block( data-type ) %>interval day to second<%@ enblock %>
  <%@ enextends %>
  <%@ extends( exception, exception1 ) %><%@ block( number ) %>-20101<%@ enblock %><%@ enextends %>
  <%@ extends( select, cursor_one ) %><%@ enextends %>
  <%@ extends( plsql-type, c1_t ) %>
    <%@ block( data-type ) %>varchar2(50)<%@ enblock %>
    <%@ block( nt-name ) %>nt_name<%@ enblock %>
    <%@ block( aa-name ) %>aa_name<%@ enblock %>
    <%@ block( ref-name ) %>make_no_ref<%@ enblock %>
    <%@ block( documentation ) %>-- subtype + nt,aa\\\\n<%@ enblock %>
  <%@ enextends %>
  <%@ extends( plsql-type, my_txt_t ) %>
    <%@ block( record ) %>( bob  varchar2(10) )<%@ enblock %>
    <%@ block( ref-name ) %>ref_name<%@ enblock %>
    <%@ block( documentation ) %>-- record + ref\\\\n<%@ enblock %>
  <%@ enextends %>
  <%@ extends( procedure, outer_p ) %>
   <%@ block( bdy ) %><%@ include( ${this}.procedure.inner_p.name ) %>;
  <%@ enblock %>
    <%@ extends( exceptions-block, bad-boy ) %>
      <%@ block( body ) %><%@ include( ${super.super.super.super}.exception.exception1.when-clause ) %><%@ enblock %>
    <%@ enextends %>
    <%@ extends(procedure, inner_p ) %>
     <%@ block( bdy ) %>if dbms_random.value() > 0.5 then
  dbms_output.put_line( 'Hello World' );
else
  raise <%@ include( ${super.super.super.super}.exception.exception1.name ) %>;
end if;
     <%@ enblock %>
    <%@ enextends %>
  <%@ enextends %>
  <%@ extends( procedure, outer_f ) %>
    <%@ block( return-variable-type ) %><%@ include( ${super.super}.plsql-type.c1_t.name ) %><%@ enblock %>
    <%@ extends( plsql-type, my_inner_txt_t ) %>
      <%@ block( data-type ) %>varchar2(50)<%@ enblock %>
    <%@ enextends %>
    <%@ extends( procedure, inner_f ) %>
      <%@ block( return-variable-type ) %><%@ include( ${super.super}.plsql-type.my_inner_txt_t.name ) %><%@ enblock %>
      <%@ block( return-variable-name ) %>inner_ret_val<%@ enblock %>
      <%@ block( bdy ) %><%@ include( ${this}.return-variable-name ) %> := 'Hello World';<%@ enblock %>
    <%@ enextends %>
    <%@ block(bdy)%><%@ include( ${this}.return-variable-name ) %> := <%@ include( ${this}.procedure.inner_f.name ) %>;
    <%@ enblock %>
 <%@ enextends %>
 -- package initialization exceptions
  <%@ extends( exceptions-block, bad-boy ) %>
    <%@ block( body ) %><%@ include( ${super.super}.exception.exception1.when-clause ) %><%@ enblock %>
  <%@ enextends %>

<%@ enextends %>
$end
end;