CREATE OR REPLACE
PACKAGE te_templates_api
  AUTHID current_user
AS
  /**
   *  <h1>Application Program Interface [API] against the TE_TEMPLATES table for the tePLSQL project.</h1>
   * 
   * This package imports and exports a series of tePLSQL templates for the TE_TEMPLATES using XML.
   * 
   * <h2>File Format</h2>
   * Example XML Format:
   * <code>
   * <teplsql>
   *   <templates>
   *     <template>
   *       <NAME>hello world</NAME>
   *       <DESCRIPTION>This is a "Hello World" template</DESCRIPTION>
   *       <CREATED_BY>SCOTT TIGER</CREATED_BY>
   *       <CREATED_DATE>2016-11-19</CREATED_DATE>
   *       <MODIFIED_BY>SCOTT TIGHER</MODIFIED_BY>
   *       <MODIFIED_DATE>2016-11-19</MODIFIED_DATE>
   *       <TEMPLATE>Hello World!</TEMPLATE>
   *     <template/>
   *   </templates>
   * </teplsql>
   * </code>
   *
   * File Extenstion should be .xml or .teplsql
   * DATE columns are those imported/exported via XML SQL.  YYYY-MM-DD
   * The Node "/teplsql/templates/template/TEMPLATE" can be CDATA type data.
   * Multiple /teplsql/templates/template Nodes are expected.
   * 
   * <h2>Security</h2>
   * This is an AUTHID CURRENT_USER package.
   * 
   * The caller must have appropriate INSERT/UPDATE/SELECT permission on the TE_TEMPLATES table.
   * 
   * For APEX:
   *     The 'parsing schema' needs EXECUTE permission in order to run.  (This is in addtion to INSERT/SELECT/UPDATE on TE_TEMPLATES
   * 
   * For Oracle Directory:
   * <ul>
   * <li>The caller needs INSERT/SELECT/UPDATE permissions on the table TE_TEMPLATES</li>
   * <li>The caller must also have appropriate READ/WRITE permission on the Oracle Directory if the "directory_*" interfaces are used.</li>
   * </ul>
   * 
   * <h2>Primative Functions</h2>
   * These functions are the main functions of the package.
   * <ul>
   * <li>xml_import - imports an XML LOB into the TE_TEMPLATES table</li>
   * <li>xml_export - returns the XML in CLOB format (todo: this should return an XMLType</li>
   * <li>assert - this verifies that the XML is valid for import()</li>
   * </ul>
   * 
   * <h2>PL/SQL Interfaces</h2>
   * These procedures allow you to import from/export to a file using an Oracle Directoyr
   * 
   * <ul>
   * <li>file_import - imports templates from an XML file found in an Oracle Directory.</li>
   * <li>file_export - exports templates into an XML file located in an Oracle Directory.</li>
   * </ul>
   * 
   * <h2>APEX Interfaces</h2>
   * These procedures are for use from within Oracle Application Express (APEX)
   * <ul>
   * <li>apex_import - use to import a file uploaded via "File Browse..." Item type into APEX_APPLICATION_TEMP_FILES.  APEX 5.0 or higher is required</li>
   * <li>apex_export - a BEFORE HEADER process that allows the end-user to download the XML file.  The Filename must end in xml or teplsql</li>
   * </ul>
   *
   * <h2>List of Values</h2>
   * These are Pipelined Functions that allow you to create a List of Values for your application.
   * <ul>
   * <li>import_options_lov - returns a list of options for the import() series of procedures</li>
   * <li>export_options_lov - returns a list of option for the export() series of procedures</li>
   * </ul>
   * 
   *
   * <h3>IMPORT Options</h3>
   * overwrite - if NAME matches, always OVERWRITE
   * ignore    - if NAME matches, ignore
   * error     - if NAME mathches, raise an error
   * 
   *
   * 
   * </h3>EXPORTS Options</h3>
   * exact - Match p_search_values against NAME using a case insentive exact mathch.
   * like  - Match p_search_values against NAME using a case insentive LIKE match.  You must provide "%" keys.
   * regexp  - Match p_search_values against NAME using a case sensitive Regular Expression match.
   * 
   * @headcom
   */
  SUBTYPE options_t IS INTEGER NOT NULL;
  
  g_option_uninitilized CONSTANT options_t :=-1;
  
  TYPE lov_t IS RECORD (  option_value options_t DEFAULT g_option_uninitilized
                        , option_desc VARCHAR2( 50 )
                       );
  TYPE lov_nt IS TABLE OF lov_t;

  g_import_overwrite CONSTANT options_t := 1;
  g_import_ignore    CONSTANT options_t := 2;
  g_import_error     CONSTANT options_t := 0;
  g_import_default   CONSTANT options_t := g_import_overwrite;

  g_export_exact     CONSTANT options_t := 1;
  g_export_like      CONSTANT options_t := 2;
  g_export_regexp    CONSTANT options_t := 3;
  g_export_dot       CONSTANT options_t := 4;
  g_export_default   CONSTANT options_t := g_export_exact;

  invalid_option              EXCEPTION;
  invalid_tePLSQL_xml         EXCEPTION;
  
  /**
   * Asserts that the XML conforms to the current XML Schema for tePLSQL TE_TEMPLATES
   * 
   * TODO: this is currently a NOOP
   * 
   * @param  p_xml                The XML to test
   * @raises invalid_tePLSQL_xml  Raised when input XML is not an tePLSQL XML document.
   */
  PROCEDURE assert_xml (
                          p_xml IN XMLTYPE
                        );
                        
  /*
   * Returns a List of Values for IMPORT Options
   * 
   * The following languages are supported:
   * <ul>
   * <li>'EN' - English</li>
   * </ul>
   * 
   * Default language is 'EN'
   * 
   * usage
   * <code>
   * select *
   * from table( te_templates_api.import_options_lov() )
   * </code>
   *     
   * All unsupported languages will raise the 'invalid_option' exception.
   *
   * At this time, only EN is supported.
   * 
   * @param   p_lang          The language for Description.
   * @returns                 List of Values (LoV) suitable for User Interfaces
   * @raises  invalid_option  Raised if the language is not supported.
   */
  FUNCTION import_options_lov (
                                p_lang IN VARCHAR2 DEFAULT 'EN'
                              ) RETURN lov_nt
                                PIPELINED;
                              
  /**
   * Returns a List of Values for EXPORT Options
   * 
   * The following languages are supported:
   * <ul>
   * <li>'EN' - English</li>
   * </ul>
   *
   * Default language is 'EN'
   *
   *
   * usage
   * <code>
   * select *
   * from table( te_templates_api.export_options_lov() )
   * </code>
   *
   * All unsupported languages will raise the 'invalid_option' exception.
   *
   * At this time, only EN is supported.
   * 
   * @param   p_lang          The language for Description.
   * @returns                 List of Values (LoV) suitable for User Interfaces
   * @raises  invalid_option  Raised if the language is not supported.
   */
  FUNCTION export_options_lov (
                                p_lang IN VARCHAR2 DEFAULT 'EN'
                              ) RETURN lov_nt
                                PIPELINED;
                              
  /*
   *  Imports a series of tePLSQL templates from a given XML document.
   * 
   * The document must have already passed the "assert_xml()" function.
   * 
   * @param   p_xml            The set of tePLSQL templates in XMLType format
   * @returns                 List of Values (LoV) suitable for User Interfaces
   * @param   p_duplicates     Defines how to handle duplicate.  Default is "overwrite".
   * @raises  invalid_option   Raised when option is invalid.
   */
  PROCEDURE xml_import (
                         p_xml          IN XMLTYPE
                       , p_duplicates   IN options_t DEFAULT g_import_default
                       );
                        
  /**
   * Returns an XML Document for a series of templates based on the <i>p_search_value</i>
   * 
   * @param  p_search_value   The search value to use
   * @param  p_search_type    Defines how to match.  Match is either Exact (default), LIKE, or Regulare Expression
   * @returns                 XML Document of Templates suitable for import via xml_import()
   * @raises  invalid_option  Raised when option is invalid..
   */
  FUNCTION xml_export (
                        p_search_value   IN VARCHAR2 DEFAULT NULL
                      , p_search_type    IN options_t DEFAULT g_export_default
                      ) RETURN XMLTYPE;



  /**
   * Imports a file from an Oracle DIRECTORY location.
   * 
   * Filename must have either the ".xml" extension or the ".teplsql" extension.
   * 
   * @param   p_oradir             The name of the Oracle DIRECTORY.
   * @param   p_filename           The  name of the file to import (including extension)
   * @param   p_duplicates         The Import option to how to handle duplicate template NAMEs
   * @raises  invalid_option       Raised when option is invalid or filename is not correct.
   * @raises  invalid_tePLSQL_xml  Raised if filename is invalid or XML is not a tePLSQL XML document.
   */
  PROCEDURE file_import (
                          p_oradir       IN VARCHAR2
                        , p_filename     IN VARCHAR2
                        , p_duplicates   IN options_t DEFAULT g_import_default
                        );

  /**
   * Exports a collection of templates to a file in an Oracle DIRECTORY location.
   * 
   * Filename must have either the ".xml" extension or the ".teplsql" extension.
   * 
   * @param   p_oradir         The name of the Oracle DIRECTORY.
   * @param   p_filename       The  name of the file to export (including extension)
   * @param   p_search_value   The search value to use
   * @param   p_search_type    Defines how to match.  Match is either Exact (default), LIKE, or Regulare Expression
   * @raises  invalid_option   Raised when option is invalid or filename is not correct.
   * 
   */
  PROCEDURE file_export (
                          p_oradir         IN VARCHAR2
                        , p_filename       IN VARCHAR2
                        , p_search_value   IN VARCHAR2 DEFAULT NULL
                        , p_search_type    IN options_t DEFAULT g_export_default
                        );

  
  /**
   * APEX utility to return a file, that was uploded via "File Browse..." Item Type, as a CLOB.
   * 
   * @paream  p_filename  This is the value returned by the "File Browse..." Item.  It is used to identify the correct file to process.
   */
  FUNCTION filebrowse_as_clob (
                                p_filename IN VARCHAR2
                              ) RETURN CLOB;
                                
  /**
   * Interface for APEX Process.
   * 
   * This is a single call interface for APEX Process.
   * 
   * Thie "File Browse..." Item needs to save the file to APEX_APPLICATION_TEMP_FILES.
   * 
   * Example Usage
   * <code>
   * te_templates_api.apex_import( :P10_FILE_BROWSE, :P10_IMPORT_LOV );
   * </code>
   * 
   * @param  p_filename    This is the value returned by the "File Browse..." Item.  It is used to identify the correct file to process.
   * @param  p_duplicates  Defines how to handle duplicate.  Default is "overwrite".
   */
  PROCEDURE apex_import (
                          p_filename     IN VARCHAR2
                        , p_duplicates   IN options_t DEFAULT g_import_default
                        );
      
  /**
   * Interface for APEX Process.
   * 
   * This is a single call interface for APEX Process.
   * 
   * This downloads a colletion of templates as an XML Document.
   * File extension shoul be '.xml' or '.teplsql'.
   * 
   * Example Usage
   * <code>
   * te_templates_api.apex_import( :P10_FILENAME_TEXT, :P10_SEARCH_TEXT, :P10_EXPORT_LOV );
   * </code>
   * 
   * @param   p_filename       This is the value returned by the "File Browse..." Item.  It is used to identify the correct file to process.
   * @param   p_search_value   The search value to use
   * @param   p_search_type    Defines how to match.  Match is either Exact (default), LIKE, or Regulare Expression
   * @raises  invalid_option   Raised when option is invalid or filename is not correct.
   */
  PROCEDURE apex_export (
                          p_filename       IN VARCHAR2
                        , p_search_value   IN VARCHAR2
                        , p_search_type    IN VARCHAR2
                        );

END;
