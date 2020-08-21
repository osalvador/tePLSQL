Prompt creating table
@@TE_TEMPLATES.sql

Prompt create template package
@@tePLSQL.pks
@@tePLSQL.pkb

Prompt create template api package
@@TE_TEMPLATES_API.pks
@@TE_TEMPLATES_API.pkb

Prompt installing default helper templates
@@TE_DEFAULT_HELPER_TEMPLATES.pks
@@TE_DEFAULT_HELPER_TEMPLATES.pkb

exec te_derault_helper_templates.install_templates;
commit;


Prompt done
