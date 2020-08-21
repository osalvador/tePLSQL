create or replace
package te_default_helper_templates
as
    /**
    * This package is for distributing
    * the default Helper Templates for tePLSQL.
    *
    * execute the install procedure to load
    * the templates into TE_TEMPLATES
    *
    * @headcom
    */
    
    g_base_name    constant te_templates.name%type := 'teplsql.helper.default';
    
    /**
    * installs the templates into TE_TEMPLATES
    */
    procedure install_templates;
    
    /**
    * Returns the Base Name of the default templates.
    * Used in SQL statements.
    */
    function base_name return te_templates.name%type;
    
end te_default_helper_templates;
/
