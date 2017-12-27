CREATE OR REPLACE PACKAGE teplsql
   AUTHID CURRENT_USER
AS
   --Define data type for Template Variable names
   SUBTYPE t_template_variable_name IS VARCHAR2 (255);
   
   --Define data type for Template Variable values
   SUBTYPE t_template_variable_value IS VARCHAR2 (32767);
   
   --Define Associative Array
   TYPE t_assoc_array
   IS
      TABLE OF t_template_variable_value
         INDEX BY t_template_variable_name;

   null_assoc_array   t_assoc_array;

   --Use these Template Variable Names to adjust the maximum number of includes (default=50)
   g_set_max_includes        constant t_template_variable_name := 'tePLSQL.max_includes';
   g_set_globbing_mode       constant t_template_variable_name := 'tePLSQL.globbing.mode';
   g_set_globbing_separator  constant t_template_variable_name := 'tePLSQL.globbing.separator';

   -- Valid values for globbing mode
   g_globbing_mode_off      constant t_template_variable_value := 'off';
   g_globbing_mode_on       constant t_template_variable_value := 'on';
   g_globbing_mode_regexp   constant t_template_variable_value := 'regexp';
   g_globbing_mode_like     constant t_template_variable_value := 'like';

   /**
   * Output CLOB data to the DBMS_OUTPUT.PUT_LINE
   *
   * @param  p_clob     the CLOB to print to the DBMS_OUTPUT
   */
   PROCEDURE output_clob (p_clob IN CLOB);

   /**
   * Prints received data into the buffer
   *
   * @param  p_data     the data to print into buffer
   */
   PROCEDURE PRINT (p_data IN CLOB);

   PROCEDURE p (p_data IN CLOB);

   PROCEDURE PRINT (p_data IN VARCHAR2);

   PROCEDURE p (p_data IN VARCHAR2);

   PROCEDURE PRINT (p_data IN NUMBER);

   PROCEDURE p (p_data IN NUMBER);

   /**
   * Renders the template received as parameter.
   *
   * @param  p_vars             the template's arguments and engine properties.
   * @param  p_template         the template's body.
   * @param  p_error_template   if an error occurs, the template processed with the error description
   * @return                    the processed template.
   */
   FUNCTION render (p_vars             IN            t_assoc_array DEFAULT null_assoc_array
                  , p_template         IN            CLOB
                  , p_error_template      OUT NOCOPY CLOB)
      RETURN CLOB;

   /**
   * Renders the template received as parameter. Overloaded function for backward compatibility.
   *
   * @param  p_vars             the template's arguments and engine properties.
   * @param  p_template         the template's body.
   * @return                    the processed template.
   */
   FUNCTION render (p_vars IN t_assoc_array DEFAULT null_assoc_array , p_template IN CLOB)
      RETURN CLOB;

   /**
   * Receives the name of the object, usually a package,
   * which contains an embedded template.
   * The template is extracted and is rendered with `render` function
   *
   * @param  p_vars             the template's arguments and engine properties.
   * @param  p_template_name    the name of the template
   * @param  p_object_name      the name of the object (usually the name of the package)
   * @param  p_object_type      the type of the object (PACKAGE, PROCEDURE, FUNCTION...)
   * @param  p_schema           the object's schema name.
   * @return                    the processed template.
   */
   FUNCTION process (p_vars            IN t_assoc_array DEFAULT null_assoc_array
                   , p_template_name   IN VARCHAR2 DEFAULT NULL
                   , p_object_name     IN VARCHAR2 DEFAULT 'TE_TEMPLATES'
                   , p_object_type     IN VARCHAR2 DEFAULT 'PACKAGE'
                   , p_schema          IN VARCHAR2 DEFAULT NULL )
      RETURN CLOB;
END teplsql;
/