CREATE OR REPLACE PACKAGE teplsql
AS
   --Define Associative Array
   TYPE t_assoc_array
   IS
      TABLE OF VARCHAR2 (32767)
         INDEX BY VARCHAR2 (255);

   --Print procedures, print data into tePLSQL Buffer.
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
   FUNCTION render (p_template IN CLOB, p_vars IN t_assoc_array)
      RETURN CLOB;

   /**
   * Receives the name of the object, usually a package,
   * which contains an embedded template. 
   * The template is extracted and is rendered with `render` function 
   *
   * @param  p_name         the name of the object (usually the name of the package)
   * @param  p_vars         the template's arguments.
   * @param  p_object_type  the type of the object (PACKAGE, PROCEDURE, FUNCTION...)
   * @return                the processed template.
   */
   FUNCTION process (p_name          IN VARCHAR2
                   , p_vars          IN t_assoc_array
                   , p_object_type   IN VARCHAR2 DEFAULT 'PACKAGE'
                   , p_schema        IN VARCHAR2 DEFAULT NULL )
      RETURN CLOB;
END teplsql;
/