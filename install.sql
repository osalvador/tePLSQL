Prompt creating table
@@TE_TEMPLATES.sql

Prompt creating Syntax checking package
@@TE_SYNTAX.pks
@@TE_SYNTAX.pkb

Prompt create template api package
@@TE_TEMPLATES_API.pks
@@TE_TEMPLATES_API.pkb

Prompt create template package
@@tePLSQL.pks
@@tePLSQL.pkb

Prompt installing default helper templates
@@TE_DEFAULT_HELPER_TEMPLATES.pks
@@TE_DEFAULT_HELPER_TEMPLATES.pkb

exec te_default_helper_templates.install_templates;
commit;


Prompt done
