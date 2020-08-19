Prompt creating table
@@TE_TEMPLATES.sql

Prompt create template package
@@tePLSQL.pks
@@tePLSQL.pkb

Prompt create template api package
@@TE_TEMPLATES_API.pks
@@TE_TEMPLATES_API.pkb


Prompt installing default helper templates
declare
    t_clob   clob;
    p_vars   teplsql.t_assoc_array;
    imp      xmltype;
begin
    -- get XML file of Helper Templates
    p_vars( teplsql.g_set_render_mode ) := teplsql.g_render_mode_fetch_only;
    t_clob := teplsql.process( p_vars, 'DefaultHelperTemplates.xml', 'TE_TEMPLATES_API' );
    
    -- convert to XML
    imp := xmltype( t_clob );
    
    -- import
    te_templates_api.xml_import( imp, te_templates_api.g_import_overwrite );
end;
/
commit;


Prompt done
