*&---------------------------------------------------------------------*
*&p Report ZSAP_OFFICE_TOUR
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZSAP_CLOUD_PLATFORM_GE_TOUR.
*&---------------------------------------------------------------------*
PARAMETERS: mp3 TYPE c length 200 lower case default 'http://open.sap.com/static/podcastgen/media/2018-02-08_cloudplatformpodcast_episode37.mp3'.
PARAMETERS: mp3delay TYPE c length 8 default ''.
PARAMETERS: mp32 TYPE c length 200 lower case default ''.
PARAMETERS: delay TYPE c length 8 default '15.0'.
PARAMETERS: GEOUSER TYPE c length 20 lower case default 'demo'.
PARAMETERS: UTAGS TYPE c length 200 lower case default 'sap,insidetrack'.
PARAMETERS: FLICKEY TYPE c length 200 lower case default ''.
PARAMETERS: SAVEKML TYPE c length 200 lower case default '/var/tmp/sapcp_tour_google_earth.kml'.
PARAMETERS ENABLEGE AS CHECKBOX DEFAULT ''.
PARAMETERS ENABLEFL AS CHECKBOX DEFAULT ''.

write: / ENABLEGE.


DATA: proxy_hostn type string.

*Add proxy if required and search for proxy_hostn in the code below
proxy_hostn = 'x.x.x.x'.

DATA: tab_c type i.
data: all type i.
DATA: p_count type i.


*KML map structure
DATA: BEGIN OF wa,
        name        TYPE string,
        desc        TYPE string,
        coord       type string,
        lat         type string,
        lon         type string,
        alt         type string,
        country     type string,
        twitter     type string,
        delay       type string,
        tilt        type string,
        range       type string,
        placemarker type i,
      END OF wa.
*What country

*HANA Table
DATA: BEGIN OF hwa,
        name TYPE string,
        desc TYPE string,
        lat  type string,
        lon  type string,
      END OF hwa.

Data: templat type string,
      templon type string,
      tempcon type string.

*WIKIPEDIA
DATA: BEGIN OF wikitab,
        title        TYPE string,
        summary      TYPE string,
        lat          type string,
        lng          type string,
        wikipediaurl type string,
        feature      type string,
      END OF wikitab.

DATA w_itab LIKE TABLE OF wikitab.
DATA w_ntab LIKE TABLE of wikitab.


*FLICKERING
DATA: BEGIN OF flicktab,
        owner  TYPE string,
        secret TYPE string,
        id     type string,
        title  type string,
        server type string,
        farm   type string,
        lat    type string,
        lng    type string,
        f_url  type string,
        f_jpg  type string,
        f_html type string,
      END OF flicktab.

DATA f_itab LIKE TABLE OF flicktab.
DATA f_ntab LIKE TABLE of flicktab.

DATA: tags type string.
DATA: num_p type i.

*GEORSSNEWS
DATA: BEGIN OF georss,
        key         type i,
        title       type string,
        link        type string,
        description type string,
        lat         type string,
        lng         type string,

      END OF georss.

DATA g_itab LIKE TABLE OF georss.
DATA g_ntab LIKE table of georss.


DATA itab LIKE TABLE OF wa.
DATA htab LIKE TABLE OF hwa.

data: store    type string.
data: valves    type string.

p_count = 1.

*url get
DATA: urlget      TYPE STRING,
      urlstub     TYPE STRING,
      http_client TYPE REF TO IF_HTTP_CLIENT,
      return_code TYPE I,

      p_filnam    type string,
      content     TYPE STRING.

DaTA:            country type string.

**************************
**************************
**This SECTION reads KML from a MIME object stored in a BSP
**See below
**Now using SAP Cloud Platform to read data from HANA
**************************
**************************
*urlget = 'http://vhcalnplci.dummy.nodomain:8000/sap/bc/bsp/sap/zhost/doc.kml'.
*cl_http_client=>create_by_url(
*  EXPORTING url = urlget
**  proxy_host = proxy_hostn
**  proxy_service = '8080'
*
*  IMPORTING client = http_client ).
*
*http_client->send( ).
*http_client->receive( ).
*http_client->response->get_status( IMPORTING code = return_code ).
*
*content = http_client->response->get_cdata( ).
*
*http_client->close( ).
*******end

*data: inputstring type xstring.
*
*call function 'SCMS_STRING_TO_XSTRING'
*  EXPORTING
*    text   = content
*  IMPORTING
*    buffer = inputstring
*  EXCEPTIONS
*    failed = 1
*    others = 2.
*
*CALL FUNCTION 'DISPLAY_XML_STRING'
*  EXPORTING
*    XML_STRING = inputstring.
*
*CALL TRANSFORMATION  ZJ_YAH_KML
* SOURCE XML  inputstring
*   RESULT ROOT = itab.
*
****END of BSP KML section
**************************

**************************
***START OF READING HANA
*https://blogs.sap.com/2012/04/11/test-16/
*https://help.sap.com/doc/abapdocu_752_index_htm/7.52/en-US/abenadbc_dml_ddl_bulk_abexa.htm
TYPES:
  BEGIN OF t_struct,
    col1    TYPE i,
    col2(4) TYPE n,
  END OF t_struct.
****Create the SQL Connection and pass in the DBCON ID to state which Database Connection will be used
DATA lr_sql TYPE REF TO cl_sql_statement.
CREATE OBJECT lr_sql
  EXPORTING
    con_ref = cl_sql_connection=>get_connection( 'NEOGEODB' ).
****Execute a query, passing in the query string and receiving a result set object
DATA lr_result TYPE REF TO cl_sql_result_set.
lr_result = lr_sql->execute_query(
  |select * from "RJRUSSLOC"."rjruss.neogeoxsc::LOCATION" ORDER BY CAST(EVENT AS int) | ).
****Get the result data set back into our ABAP internal table
lr_result->set_param_table( itab_ref = REF #( htab ) ).
lr_result->next_package( ).
lr_result->close( ).
* result->set_param_table( itab_ref = REF #( itab ) ).

*LOOP AT htab INTO hwa.
*
*  WRITE: / 'NAME:', hwa-name.
*  WRITE: / 'LINK :', hwa-desc.
*  WRITE: / 'LAT  :', hwa-lat.
*  WRITE: / 'LON  :', hwa-lon.
*
*endloop.
*
*exit.

LOOP AT htab INTO hwa.
  CLEAR wa.
  MOVE-CORRESPONDING hwa TO wa.
  concatenate wa-lon ',' wa-lat ',0' into wa-coord.
  wa-name = wa-desc.
  APPEND wa TO itab.
ENDLOOP.

*exit.
data: tweet type string.

**SECTION ADAPTS THE FINAL KML to suit my chosen tour
LOOP AT itab INTO wa.
  split wa-coord at ',' into: wa-lon wa-lat wa-alt.
  case wa-name.
*@saplabsbg
    when 'SAP Labs Bulgaria'.
      wa-desc = '@saplabsbg'.
      wa-delay = delay.
      wa-alt = '1'.
      wa-tilt = '70'.
      wa-range = '100'.

    when 'Palo Alto'.
      wa-desc = '@moyalynne'.
      wa-delay = '17'.
      wa-alt = '1'.
      wa-tilt = '70'.
      wa-range = '100'.

    when 'Enter @twitter id here'.
      wa-delay = delay.
      wa-name = 'Anonymous SAPCP user'.
      wa-desc = '@sapcp'.
      wa-alt = '1'.
      wa-tilt = '70'.
      wa-range = '100'.

    when '@AVFCOfficial'.
      wa-name = 'Aston Villa'.
      wa-alt = '100'.
      wa-tilt = '30'.
      wa-range = '250'.

    when others.
      wa-delay = delay.
      wa-alt = '1'.
      wa-tilt = '70'.
      wa-range = '100'.

  endcase.


  concatenate wa-desc ' https://twitter.com/intent/user?screen_name=' wa-desc into wa-desc.
  wa-twitter = tweet.
  wa-delay = delay.
* Used to check the country of the entered location
*  perform what_country.
  wa-placemarker = p_count.

**FLICKR API Code NEEDS ACTIVE KEY
if ENABLEFL = 'X'.
perform flick_man using UTAGS '25'.
ENDIF.

  MODIFY  itab FROM wa.
  p_count = p_count + 1.
  WRITE: / 'name:', wa-name.
  WRITE: / 'id', wa-placemarker.

ENDLOOP.

*https://help.sap.com/doc/abapdocu_751_index_htm/7.51/en-US/abenappend_lines_abexa.htm
***EXTEND TOUR to allow podcast to finish
wa-name = 'SAP Cloud Platfrom Google Earth Tour'.
wa-desc = '<p>Created by Robert Russell,  thanks for viewing</br>'.
wa-coord = '0,0,0'.
wa-lat = '0'.
wa-lon = '0,0'.
wa-alt = '3995500'.
wa-country = ''.
wa-twitter = '@rjruss'.
wa-delay = '690'.
wa-tilt = '0'.
wa-range  = '2995500'.
wa-placemarker = p_count + 1.
APPEND wa TO itab.

*/
*SORT ITAB DESCENDING BY: country, lat ascending.
*LOOP AT itab INTO wa.
*  WRITE: / wa-name, wa-lat, wa-lon, wa-country.
*ENDLOOP.
*/

if ENABLEFL = 'X'.
perform flick_man using UTAGS '100'.
ENDIF.

data: feeder type string.
*
*LOOP AT f_ntab INTO flicktab.
*
*  WRITE: / 'Owner:', flicktab-owner.
*  WRITE: / 'Secret :', flicktab-secret.
*  WRITE: / 'Title  :', flicktab-title.
*  WRITE: / 'id  :', flicktab-id.
*  WRITE: / 'farm  :', flicktab-farm.
*  WRITE: / 'server  :', flicktab-server.
*  WRITE: / 'lat  :', flicktab-lat.
*  WRITE: / 'lng  :', flicktab-lng.
*  concatenate 'http://flickr.com/photos/' flicktab-owner '/' flicktab-id into feeder.
*  write: / feeder.
*  concatenate 'http://farm' flicktab-farm '.static.flickr.com/' flicktab-server '/' flicktab-id '_' flicktab-secret '.jpg' into feeder.
*  write: / feeder.
*
*endloop.

if ENABLEGE = 'X'.
perform georss_man.
endif.

************************************************
***********************************************
**********************************************
*CREATE THE TOUR THEN DOWNLOAD TO DESKTOP
**********************************************
**********************************************

data xml_string type xstring.

DATA: s_rif_ex   TYPE REF TO cx_root,
      s_var_text TYPE string.

TRY.

    CALL TRANSFORMATION ZJ_YAH_TOUR_FLY_BLOG

                      SOURCE  ROOT = itab
                           ROOT2 = itab
                           ROOT4 = f_ntab
                           ROOT6 = g_ntab

                             P1 = mp3
                             P2 = mp32
                             P3 = mp3delay

                  RESULT XML xml_string.

  CATCH cx_root INTO s_rif_ex.
    s_var_text = s_rif_ex->get_text( ).
    MESSAGE s_var_text TYPE 'E'.

ENDTRY.


DATA: lv_file_length    TYPE i.
DATA: lv_of TYPE STRING.
DATA: lt_data TYPE TABLE OF x255.
DATA: lv_url1 TYPE c length 450.

lv_of = SAVEKML.
concatenate 'file:/' SAVEKML into lv_url1.


* Conver the xstring content to binary
CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
  EXPORTING
    buffer        = xml_string
  IMPORTING
    output_length = lv_file_length
  TABLES
    binary_tab    = lt_data.


* Download to PC
CALL METHOD cl_gui_frontend_services=>gui_download
  EXPORTING
    bin_filesize = lv_file_length
    filename     = lv_of
    filetype     = 'BIN'
  CHANGING
    data_tab     = lt_data
  EXCEPTIONS
    OTHERS       = 24.


CALL FUNCTION 'DISPLAY_XML_STRING'
  EXPORTING
    XML_STRING = xml_string.

******************************************************
******************************************************
******************************************************
******************************************************
form what_country.
  data:
    stub          type string,
    urlcount      type string,
    geonames_user type string,
    geocon        type string.
  geonames_user = geouser.

  stub = 'http://api.geonames.org/findNearbyPlaceName?lat='.
  concatenate stub wa-lat '&lng=' wa-lon '&username=' geonames_user into urlcount.

  write: / urlcount.



  cl_http_client=>create_by_url(
    EXPORTING url = urlcount
*    proxy_host = proxy_hostn
*    proxy_service = '8080'

    IMPORTING client = http_client ).

  http_client->send( ).
  http_client->receive( ).
  http_client->response->get_status( IMPORTING code = return_code ).

  geocon = http_client->response->get_cdata( ).

  http_client->close( ).

  data: geostring type xstring.

  call function 'SCMS_STRING_TO_XSTRING'
    EXPORTING
      text   = geocon
    IMPORTING
      buffer = geostring
    EXCEPTIONS
      failed = 1
      others = 2.


  CALL TRANSFORMATION  ZJ_YAH_GEONAMES_BLOG
SOURCE XML  geostring
   RESULT P1 = wa-country.


endform.                    "what_country
******************************************************
******************************************************

**************************
**************************
**************************
*Flicking
************************
**************************
*************************
form flick_man using tags num_p.

  DATA: f_latinum type string,
        f_longnum type string,
        f_url1    type string.

  DATA: f_urlget      TYPE STRING,
        f_urlstub     TYPE STRING,
        f_http_client TYPE REF TO IF_HTTP_CLIENT,
        return_code   TYPE I,

        f_p_filnam    type string,
        f_content     TYPE STRING.


*working geo location radius search near offices  concatenate 'http://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=' FLICKEY '&lat=' wa-latinum '&lon=' wa-longnum '&radius=10'  into f_urlget.
  if num_p = 25.
    concatenate 'https://api.flickr.com/services/rest/?method=flickr.photos.search' '&api_key=' FLICKEY '&min_taken_date=2010-01-01&tags=' tags '&tag_mode=all&has_geo=1&lat=' wa-lat '&lon=' wa-lon '&radius=10'
      into f_urlget.
  endif.
  if num_p = 100.
    concatenate 'https://api.flickr.com/services/rest/?method=flickr.photos.search' '&api_key=' FLICKEY '&min_taken_date=2010-01-01&tags=' tags '&tag_mode=all&has_geo=1'
    into f_urlget.
  endif.


  cl_http_client=>create_by_url(
    EXPORTING url = f_urlget
*    proxy_host = proxy_hostn
*    proxy_service = '8080'

    IMPORTING client = http_client ).

  http_client->send( ).
  http_client->receive( ).
  http_client->response->get_status( IMPORTING code = return_code ).

  f_content = http_client->response->get_cdata( ).

  http_client->close( ).



  DATA: gs_rif_ex   TYPE REF TO cx_root,
        gs_var_text TYPE string.



  TRY.

      CALL TRANSFORMATION ZJ_YAH_FLICKRING
      SOURCE XML  f_content
          RESULT ROOT = f_itab.

    CATCH cx_root INTO gs_rif_ex.
      gs_var_text = gs_rif_ex->get_text( ).
      MESSAGE gs_var_text TYPE 'E'.

  ENDTRY.


  LOOP AT f_itab INTO flicktab from 1 to num_p.


    perform geo_flick.

    concatenate 'http://flickr.com/photos/' flicktab-owner '/' flicktab-id into flicktab-f_url.
    concatenate 'http://farm' flicktab-farm '.static.flickr.com/' flicktab-server '/' flicktab-id '_' flicktab-secret '.jpg' into flicktab-f_jpg.


    data: stub type string.
    data: stub1 type string.
    data: stub2 type string.

    concatenate '<HTML><A href="' flicktab-f_url '">Link to FLICKR PAGE</A></HTML>' into stub.
    stub1 = '<![CDATA[<html><body><img src="'.
    concatenate stub stub1 flicktab-f_jpg  '" alt="Flickr" width="540" height="500" /></body></html>]];' into flicktab-f_html.



    append flicktab to f_ntab.

  endloop.

  refresh f_itab.

endform.                    "flick_man


******************************
******************************
******************************


form geo_flick.

  DATA: fgurlget    TYPE STRING,
        fgurlstub   TYPE STRING,
        http_client TYPE REF TO IF_HTTP_CLIENT,
        return_code TYPE I,
        fgcontent   TYPE STRING.

  concatenate 'https://api.flickr.com/services/rest/?method=flickr.photos.geo.getLocation&api_key=' FLICKEY '&photo_id=' flicktab-id into fgurlget.

  write: fgurlget.

*exit.

  cl_http_client=>create_by_url(
    EXPORTING url = fgurlget
*    proxy_host = proxy_hostn
*    proxy_service = '8080'

    IMPORTING client = http_client ).

  http_client->send( ).
  http_client->receive( ).
  http_client->response->get_status( IMPORTING code = return_code ).

  fgcontent = http_client->response->get_cdata( ).

  http_client->close( ).
*******end

  write: fgcontent.

*  exit.


  DATA: gs_rif_ex   TYPE REF TO cx_root,
        gs_var_text TYPE string.



  TRY.

      CALL TRANSFORMATION  ZJ_YAH_FLICKRING_GEOP

          SOURCE XML  fgcontent
          RESULT PLAT = flicktab-lat
                  PLNG = flicktab-lng.

    CATCH cx_root INTO gs_rif_ex.
      gs_var_text = gs_rif_ex->get_text( ).
      MESSAGE gs_var_text TYPE 'E'.

  ENDTRY.

endform.                    "geo_flick
*************************
************************
**************************
*&---------------------------------------------------------------------*
*&      Form  georss_man
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
form georss_man.
  DATA: latinum type string,
        longnum type string,
        url1    type string.
  data: userid type string,
        userpw type string.


  DATA: grss_urlget  TYPE STRING,
        urlstub      TYPE STRING,
        http_client  TYPE REF TO IF_HTTP_CLIENT,
        return_code  TYPE I,

        p_filnam     type string,
        free_err     type string,
        grss_content TYPE STRING.



  DATA xml_string type xstring.

  DATA: stub type string.
  DATA: stub1 type string.
  DATA: stub2 type string.
  DATA: stub3 type string.
  DATA: stub4 type string.

*SAP Community blogs -  inside track tag
*https://blogs.sap.com/tags/72472722867005232775920452375500/feed/
*  grss_urlget = 'http://ws.geonames.org/rssToGeoRSS?feedUrl=http://feeds.feedburner.com/SDNWeblogs_SDNDay'.
*  grss_urlget = 'http://ws.geonames.org/rssToGeoRSS?&username=rjruss&feedUrl=https://blogs.sap.com/tags/72472722867005232775920452375500/feed/'.


  concatenate 'http://ws.geonames.org/rssToGeoRSS?&username=' geouser '&feedUrl=https://blogs.sap.com/tags/72472722867005232775920452375500/feed/' into  grss_urlget.
  write: / grss_urlget.

  CALL METHOD cl_http_client=>create_by_url
    EXPORTING
      url                = grss_urlget
*     proxy_host         = '10.160.33.6'
*     proxy_service      = '8080'
    IMPORTING
      client             = http_client
    EXCEPTIONS
      argument_not_found = 1
      plugin_not_active  = 2
      internal_error     = 3
      OTHERS             = 4.

  http_client->request->set_header_field( name  = '~request_method'
                                          value = 'GET' ).
* Send the request
  http_client->send( ).



* Reterive the result
  CALL METHOD http_client->receive
    EXCEPTIONS
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      OTHERS                     = 4.

  grss_content = http_client->response->get_cdata( ).

  DATA: gs_rif_ex   TYPE REF TO cx_root,
        gs_var_text TYPE string.


  call function 'SCMS_STRING_TO_XSTRING'
    EXPORTING
      text   = grss_content
    IMPORTING
      buffer = xml_string
    EXCEPTIONS
      failed = 1
      others = 2.



  CALL FUNCTION 'DISPLAY_XML_STRING'
    EXPORTING
      XML_STRING = xml_string.


*exit.



  DATA: GEOCHK type string.
  GEOCHK = 'global'.


*  TRY.

  CALL TRANSFORMATION  Z_SAP_SCN_DAYSv2
SOURCE XML  grss_content
    RESULT ROOT = g_itab
           E1 = free_err.


*  ENDTRY.
  if free_err is not initial.
    write: / 'ERROR with free geonames service, maybe the free servers are overloaded'.
    write: / 'Therefore RSS feed will not be included in this run'.
  endif.

  data: feeder type string.


  data c type i.
  c = 0.


  DELETE g_itab WHERE ( lat = '' ) AND ( lng = '' ).
  sort g_itab descending by: lat.



*LOOP AT g_itab INTO georss.
  LOOP AT g_itab INTO georss.
    WRITE: / 'TITLE:', georss-title.
    WRITE: / 'LINK:', georss-link.
    WRITE: / 'DESCRIPTION:', georss-description.
    write: / 'lat', georss-lat.
    write: / 'lng', georss-lng.
    c = c + 1.
    write:/ c.
    append georss to g_ntab.
*  WRITE : /.
  ENDLOOP.

  write: / 'lltt'.



endform.                    "georss_man
