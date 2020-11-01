create or replace
package body test_build
as
  type build_hash_t is table of template_name_t index by template_name_t;
  
  list_of_templates  constant build_hash_t := build_hash_t(
                                                 generate_variables    => 'build.variables'
                                                ,generate_plsql_types  => 'build.plsql-types'
                                                ,generate_procedures   => 'build.procedures'
                                                ,generate_exceptions   => 'build.exceptions'
                                                ,generate_select       => 'build.select'
                                                ,generate_build        => 'build.build'
                                              );

  function get_build_template_name( template_name in template_name_t )
    return template_name_t
  as
  begin
    if not list_of_templates.exists( template_name )
    then
      raise template_not_implemented;
    end if;
    
    return list_of_templates( template_name );
  end get_build_template_name;

  function make_code( template_name in template_name_t ) return clob
  as
    p_vars           teplsql.t_assoc_array;
    v_returnvalue    clob;
  begin
    p_vars( 'schema' ) := USER;
    p_vars( teplsql.g_set_indention_string )  := '    ';

    v_returnvalue := teplsql.process_build(  p_vars
                                            ,get_build_template_name( template_name )
                                            ,$$PLSQL_UNIT
                                            ,'PACKAGE'
                                            );

    return v_returnvalue;
  end make_code;
  
  /*
  *   Wrapper for `make_code()`.
  *   Displays the results to DBMS_OUTPUT
  *   
  *   @param template_name in template_name_t
  */
  procedure output_code( template_name in template_name_t )
  as
  begin
    if template_name is null
    then
      raise no_data_found;
    end if;
    
    dbms_output.put_line( make_code( template_name) );
  exception
    when template_not_implemented then
      dbms_output.put_line( 'Template "' || template_name || '" not yet implemented.' );
    when no_data_found then
      dbms_output.put_line( 'Template name must be defined.' );
  end;
  
  
$if false $then
<%@ template( template_name=build.procedures, build=make ) %>
<%@ extends( package, demo_procs_pkg ) %>
  <%@ extends( plsql-type, a_type ) %>
    <%@ block( data-type )%>varchar2(20 char)<%@ enblock %>
  <%@ enextends %>
  <%@ extends( procedure, 01_proc_1 ) %>
    <%@ block( name ) %>proc_1<%@ enblock %>
  <%@ enextends %>
  <%@ extends( procedure, 02_func_1) %>
    <%@ block( name ) %>func_1<%@ enblock %>
    <%@ block( return-variable-type ) %><%@ include( ${super.super}.plsql-type.a_type.name ) %><%@ enblock %>
  <%@ enextends %>
<%@ enextends %>
$end

$if false $then
<%@ template( template_name=build.plsql-types, build=make ) %>
<%@ extends( package, demo_plsql_types_pkg ) %>
  <%@ extends( plsql-type, z99_last ) %>
    <%@ block( data-type ) %>varchar2(10)<%@ enblock %>
    <%@ block( name ) %>this_is_last<%@ enblock %>
  <%@ enextends %>
  <%@ extends( plsql-type, 02_with_documentation ) %>
    <%@ block( data-type ) %>varchar2(10)<%@ enblock %>
    <%@ block( name ) %>this_has_documentation<%@ enblock %>
    <%@ block( documentation ) %>-- This TYPE contains a Documentation section\\\\n<%@ enblock %>
  <%@ enextends %>
  <%@ extends( plsql-type, 03_nt_example ) %>
    <%@ block( name ) %>this_has_nt<%@ enblock %>
    <%@ block( data-type ) %>varchar2(10)<%@ enblock %>
    <%@ block( nt-name) %>nt_name<%@ enblock %>
  <%@ enextends %>
  <%@ extends( plsql-type, 01_z_error ) %>
    <%@ block( name ) %>bad_build<%@ enblock %>
  <%@ enextends %>
  <%@ extends( plsql-type, 04_aa_example ) %>
    <%@ block( name ) %>this_has_aa<%@ enblock %>
    <%@ block( data-type ) %>varchar2(10)<%@ enblock %>
    <%@ block( aa-name) %>aa_name<%@ enblock %>
  <%@ enextends %>
  <%@ extends( plsql-type, 05_aa_example2 ) %>
    <%@ block( name ) %>this_has_aa2<%@ enblock %>
    <%@ block( data-type ) %>varchar2(10)<%@ enblock %>
    <%@ block( aa-name) %>aa_name2<%@ enblock %>
    <%@ block( aa-key-data-type ) %><%@ include( ${super}.01_first.name ) %><%@ enblock %>
  <%@ enextends %>
  <%@ extends( plsql-type, 06_rcd_example ) %>
    <%@ block( name ) %>record_example<%@ enblock %>
    <%@ block( record ) %>(<% teplsql.set_tab(1); %> m  number(4,2)
<% teplsql.goto_tab(1); %>,x  number
<% teplsql.goto_tab(1); %>,y  number
<% teplsql.goto_tab(1); %>,b  number
<% teplsql.goto_tab(1); %>,notes  <%@ include( ${super}.01_first.name ) %>
<% teplsql.goto_tab(1); %>)<%@ enblock %>
  <%@ enextends %>
  <%@ extends( plsql-type, 07_rcd_example2 ) %>
    <%@ block( name ) %>record_has_ref<%@ enblock %>
    <%@ block( record ) %>( m  number(4,2) )<%@ enblock %>
    <%@ block( ref-name ) %>ref_name<%@ enblock %>
  <%@ enextends %>
  <%@ extends( plsql-type, no_name_given ) %>
    <%@ block( data-type ) %>varchar2(10)<%@ enblock %>
  <%@ enextends %>
  <%@ extends( plsql-type, 01_first ) %>
    <%@ block( data-type ) %>varchar2(10)<%@ enblock %>
    <%@ block( name ) %>this_is_first<%@ enblock %>
  <%@ enextends %>
<%@ enextends %>
$end

$if false $then
<%@ template( template_name=build.variables, build=make ) %>
<%@ extends( package, demo_variables_pkg ) %>
  <%@ extends( plsql-type, undefined ) %>
    <%@ block( data-type ) %>varchar2(42)<%@ enblock %>
  <%@ enextends %>
  
  <%@ extends( variable, 01_error ) %>
    <%@ block( name ) %>should_be_undefined<%@ enblock %>
  <%@ enextends %>
  <%@ extends( variable, 02_basic ) %>
    <%@ block( name ) %>test_2<%@ enblock %>
    <%@ block( data-type ) %>varchar2(42)<%@ enblock %>
  <%@ enextends %>
  <%@ extends( variable, 03_doc ) %>
    <%@ block( name ) %>test_3<%@ enblock %>
    <%@ block( data-type ) %>varchar2(42)<%@ enblock %>
    <%@ block( documentation ) %>/**
* Test #3 has some comments
*/
<%@ enblock %>
  <%@ enextends %>
  <%@ extends( variable, 04_value ) %>
    <%@ block( name ) %>test_4<%@ enblock %>
    <%@ block( data-type ) %>varchar2(42)<%@ enblock %>
    <%@ block( value ) %>'This is the initial value for Test #4'<%@ enblock %>
  <%@ enextends %>
  <%@ extends( variable, 05_constant ) %>
    <%@ block( name ) %>test_5<%@ enblock %>
    <%@ block( data-type ) %>varchar2(42)<%@ enblock %>
    <%@ block( constant-value ) %>'This is the constant value for Test #5'<%@ enblock %>
  <%@ enextends %>
<%@ enextends %>
  
$end

$if false $then
<%@ template( template_name=build.exceptions, build=make ) %>
<%@ extends( package, demo_exceptions_pkg ) %>
  <%@ block( init ) %>-- testing exception call via Package Initialization clause
null;
<%@ enblock %>
  <%@ extends( exception, no_name ) %>
  <%@ enextends %>
  <%@ extends( exception, 01_doc ) %>
    <%@ block( name ) %>doc_changed<%@ enblock %>
    <%@ block( documentation ) %>/*
* this exception is for some error
*/
<%@ enblock %>
  <%@ enextends %>
  <%@ extends( exception, 02_number ) %>
    <%@ block( name ) %>exception_02<%@ enblock %>
    <%@ block( number ) %>-20101<%@ enblock %>
  <%@ enextends %>
  <%@ extends( exception, 03_text ) %>
    <%@ block( name ) %>exception_03<%@ enblock %>
    <%@ block( text ) %>'The Text has changed'<%@ enblock %>
  <%@ enextends %>
  <%@ extends( exception, 04_text ) %>
    <%@ block( name ) %>exception_04<%@ enblock %>
    <%@ block( text ) %>'The Text has changed'<%@ enblock %>
  <%@ enextends %>
  <%@ extends( exception, 05_const_num ) %>
    <%@ block( name ) %>exception_05<%@ enblock %>
    <%@ block( constant-number-name ) %>g_05_number<%@ enblock %>
  <%@ enextends %>
  <%@ extends( exception, 06_const_text ) %>
    <%@ block( name ) %>exception_06<%@ enblock %>
    <%@ block( constant-text-name ) %>g_06_text<%@ enblock %>
  <%@ enextends %>
  
  <%@ extends( procedure, test_exceptions ) %>
    <%@ extends( exceptions-block, 01_all ) %>
      <%@ block( body ) %><%@ include( ${super.super.super.super}.exception.*.when-clause ) %><%@ enblock %>
    <%@ enextends %>
    <%@ extends( exceptions-block, 99_others ) %>
      <%@ block( body ) %>-- custom error WHEN clause
when others then
    raise;<%@ enblock %>
    <%@ enextends %>
  <%@ enextends %>
  -- exception for init clause
  <%@ extends( exceptions-block, 01_all ) %>
    <%@ block( body ) %>when no_data_found then null;<%@ enblock %>
  <%@ enextends %>
<%@ enextends %>
$end

$if false $then
<%@ template( template_name=build.select, build=main ) %>
<%@ extends( build, foo ) %>
<%@ extends( package, demo_exceptions_pkg ) %>
  <%@ block( init ) %>with <%@ include( ${this}.select.simple_cursor.cte ) %>\\\\n
select a.dummy
  into <%@ include( ${this}.name ) %>.dummy
from <%@ include( ${this}.select.simple_cursor.name ) %> a;
<%@ enblock %>
  <%@ extends( variable, dummy ) %>
    <%@ block( data-type ) %>dual.dummy%type<%@ enblock %>
  <%@ enextends %>  <%@ extends( select, simple_cursor ) %>
    <%@ block( SQL ) %>select 'X' dummy
from emp
where empno = 0<%@ enblock %>
  <%@ enextends %>
  <%@ extends( select, cursor_with_params ) %>
    <%@ block( parameters ) %><% teplsql.goto_tab(1); %> line_1 varchar2
<% teplsql.goto_tab(1); %>,line_2 int
<% teplsql.goto_tab(1); %>,line_3 date<%@ enblock %>
  <%@ enextends %>
<%@ enextends %>
  <%@ extends( select, this_is_a_view ) %>
  <%@ enextends %>
<%@ enextends %>
$end

$if false $then
<%@ template( template_name=build.build, build=main ) %>
<%@ extends( build, some_build ) %>
<%@ enextends %>
$end

end;
/
