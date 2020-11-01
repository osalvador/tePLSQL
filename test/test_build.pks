create or replace
package test_build
  authid current_user
as
  /*
  * Generates test code for each Helper Template type.
  *
  * To generate *just the code*, use the `make_code()` function.
  * To automatically display via DBMS_OUTPUT, use the `output_code` procedure.
  *
  * The only Parameters, for both function and procedure, represents the Helper Template you want to test.
  *
  * The Global Constants of the Helper Templates you can test have the form `generate_*type*`
  *
  * The actual Build Templates are in the package BODY.
  *
  * @headcom
  */
  subtype template_name_t is te_templates.name%type;
  
  generate_variables       constant template_name_t := 'variable';
  generate_plsql_types     constant template_name_t := 'plsql-type';
  generate_packages        constant template_name_t := 'package'; -- todo
  generate_procedures      constant template_name_t := 'procedure';
  generate_exceptions      constant template_name_t := 'exception';
  generate_select          constant template_name_t := 'select';
  generate_build           constant template_name_t := 'build';
  
  template_not_implemented exception;
  pragma exception_init( template_not_implemented, -20000);
  
  /*
  *    Common code generator for testing Build Template.
  *
  *    Used by the `oddgen` plugin
  *
  *    @param template_name  Name of the template to generate
  *    @return                 Resulting template (or error)
  */
  function make_code( template_name in template_name_t ) return clob;
  
  /*
  *   Wrapper for `make_code()`.
  *   Displays the results to DBMS_OUTPUT
  *   
  *   @param template_name in template_name_t
  */
  procedure output_code( template_name in template_name_t );
  
end;
/