create or replace
package body te_syntax
as
  procedure parse_key_value( p_txt in varchar2, p_key out varchar2, p_value out varchar2 )
  as
  begin
    p_key   := regexp_replace( trim(p_txt), key_value, '\2' );
    p_value := regexp_replace( trim(p_txt), key_value, '\3' );
  end;

  function parse_parameters( p_txt in varchar2 ) return t_generic_parameters
  as
    n int;
    current_parameter int := 1;
    token t_param;

    key_str t_param;
    val_str t_param;

    ret_val t_generic_parameters;
  begin
    null;
    n := regexp_count( p_txt, param_search );

    for i in 1 .. n
    loop
      token := regexp_replace( regexp_substr( p_txt, param_search, 1, i ), comma, '');

      case
        when regexp_like( token, key_value ) then
          parse_key_value( trim(token), key_str, val_str);
          ret_val.options(key_str) := val_str;
        when regexp_like( token, single_word ) then
          ret_val.lov(current_parameter) := trim(token);

          current_parameter := current_parameter + 1;
        else
          null;
      end case;
    end loop;

    return ret_val;
  end;

  function decode_extends_parameters( p_txt in varchar2 ) return t_extends_parameters
  as
    plist   t_generic_parameters;
    ret_val t_extends_parameters;
  begin
    plist := parse_parameters( p_txt );

    if plist.lov.count < 2
    then
      raise missing_parameter;
    elsif plist.lov.count > 2
    then
      raise_application_error( -20111, 'Bad EXTENDS parameter "' || p_txt || '"' );
      raise invalid_syntax;
    end if;

    ret_val.node_type := plist.lov(1);
    ret_val.node_name := plist.lov(2);

    ret_val.options   := plist.options;

    if ret_val.options.exists( 'base' )
    then
      ret_val.base_name := ret_val.options('base');
    end if;
    
--    dbms_output.put_line( ' debug EXTENDS attribute type="' || ret_val.node_type || '" name="' || ret_val.node_name || '" base="' || ret_val.base_name || '"' );

    return ret_val;
  end decode_extends_parameters;

  function decode_block_parameters( p_txt in varchar2 ) return t_block_parameters
  as
    plist   t_generic_parameters;
    ret_val t_block_parameters;
  begin
    plist := parse_parameters( p_txt );

    if plist.lov.count <> 1
    then
      raise invalid_syntax;
    elsif plist.options.count > 0
    then
      raise invalid_syntax;
    end if;

    ret_val.block_name := plist.lov(1);


    return ret_val;
  end decode_block_parameters;
  
  function parse_block_declarative( p_txt in varchar2) return t_block_parameters
  as
    l_params t_param;
  begin
    if not regexp_like( trim(p_txt), block_command )
    then
      raise_application_error( -20112, 'Bad BLOCK directive "' || p_txt || '"' );
    end if;
    
    l_params := trim( regexp_replace( trim(p_txt), block_command, '\1' ) );
--    dbms_output.put_line( ' debug block attributes "' || l_params || '"' );
  
    return decode_block_parameters( l_params );
  end;

  function parse_extends_declarative( p_txt in varchar2) return t_extends_parameters
  as
    l_params t_param;
  begin
    if not regexp_like( trim(p_txt), extends_command )
    then
      raise_application_error( -20110, 'Bad EXTENDS directive "' || p_txt || '"' );
    end if;
    
    l_params := trim( regexp_replace( trim(p_txt), extends_command, '\1' ) );
  
    return decode_extends_parameters( l_params );
  end;

end te_syntax;
/
