create or replace
package te_syntax
  authid current_user
as
  /**
  * This package is for verifing and parsing of various tePLSQL Template Directives
  *
  * Currently supports:
  * - extends()/enextends
  * - block()/enblock
  *
  * @headcom
  **/

  subtype language_token is varchar2(2000);

  -- list of simple tokens
  op           constant language_token := '\(';
  cp           constant language_token := '\)';
  nspace       constant language_token := '\s*';
  comma        constant language_token := '(' || nspace || ',' || nspace || ')';

  single_word  constant language_token := '[[:alnum:]_\$\{\}][[:alnum:]_.\$\{\}\-]*';
  key_value    constant language_token := '((' || single_word || ')=(' || single_word || '))';

  param_search constant language_token := '(' || key_value || '|' || single_word || ')' || comma || '?';

  /**
  * Describes the <%@ extends() %> syntax
  *
  * Valid format:
  * - extends( node-type, node-name, key=val_parms* )
  **/
  extends_command constant language_token := '^<%@' || nspace || 'extends' || op || nspace || '(' || single_word || comma || single_word
              || '(' || comma || single_word || ')*(' || comma || key_value || ')*'
              || ')' || nspace || cp || nspace || '%>$' ;
  enextends_command  constant language_token := '^enextends$';


  /**
  * Describes the <%@ block() %> syntax
  *
  * Valid format:
  * - block( block-name )
  **/
  block_command   constant language_token := '^<%@' || nspace || 'block' || op || nspace || '(' || single_word || ')' || nspace || cp || nspace || '%>$';
  enblock_command constant language_token := '^enblock$';
  

  /**
  * TYPES for parsed Directives
  */
  subtype t_param       is te_templates.name%type;
  subtype t_object_name is varchar2(128);

  type t_lov is table of t_param index by PLS_INTEGER;
  type t_key_value is table of t_param index by t_param;

  /**
  * All Template Directives fit this TYPE
  */
  type t_generic_parameters is record ( lov t_lov, options t_key_value );
  
  /**
  * Dirctive specific TYPEs
  */
  type t_block_parameters is record ( block_name  t_param );
  type t_extends_parameters is record ( node_type t_param
                                       ,node_name t_param
                                       ,base_name t_param
                                       ,options   t_key_value );

  /**
  * common EXCEPTIONS
  */
  invalid_syntax           exception;
  missing_parameter        exception;
  bad_key_value            exception;
  unknown_parameter_format exception;

  /**
  * decodes the Parameter text into t_extends_parameters
  *
  * @param  p_txt  String containing just the arguments
  * @return Parsed arguments
  */
  function decode_extends_parameters( p_txt in varchar2 ) return t_extends_parameters;

  /**
  * decodes the Parameter text into t_block_parameters
  *
  * @param   p_txt  String containing just the arguments
  * @returns The parsed arguments
  */
  function decode_block_parameters( p_txt in varchar2 ) return t_block_parameters;

  /**
  * Validates the `block` Template Directive and parses its arguments
  *
  * @param p_txt  A string containing the full Template Directive
  * @returns the paarsed argument
  */
  function parse_block_declarative( p_txt in varchar2) return t_block_parameters;

  /**
  * Validates the `extends` Template Directive and parses its arguments
  *
  * @param p_txt  A string containing the full Template Directive
  * @returns the paarsed argument
  */
  function parse_extends_declarative( p_txt in varchar2) return t_extends_parameters;

end te_syntax;
/
