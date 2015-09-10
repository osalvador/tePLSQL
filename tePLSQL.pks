/* Formatted on 10/09/2015 12:51:28 (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE teplsql
AS
   --Define Associative Array
   TYPE t_assoc_array
   IS
      TABLE OF VARCHAR2 (32767)
         INDEX BY VARCHAR2 (255);

   null_assoc_array   t_assoc_array;

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
   * @param  p_template  the template's body.
   * @param  p_vars      the template's arguments.
   * @return             the processed template.
   */
   FUNCTION render (p_template IN CLOB, p_vars IN t_assoc_array DEFAULT null_assoc_array )
      RETURN CLOB;

   /**
   * Receives the name of the object, usually a package,
   * which contains an embedded template.
   * The template is extracted and is rendered with `render` function
   *
   * @param  p_name             the name of the object (usually the name of the package)
   * @param  p_vars             the template's arguments.
   * @param  p_template_name    the name of the template
   * @param  p_object_type      the type of the object (PACKAGE, PROCEDURE, FUNCTION...)
   * @return                    the processed template.
   */
   FUNCTION process (p_name            IN VARCHAR2
                   , p_vars            IN t_assoc_array DEFAULT null_assoc_array
                   , p_template_name   IN VARCHAR2 DEFAULT NULL
                   , p_object_type     IN VARCHAR2 DEFAULT 'PACKAGE'
                   , p_schema          IN VARCHAR2 DEFAULT NULL )
      RETURN CLOB;
END teplsql;
/