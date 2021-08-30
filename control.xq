(:
 : transpect control
 :)
module namespace        control         = 'http://transpect.io/control';
import module namespace session         = "http://basex.org/modules/session";
import module namespace svn             = 'io.transpect.basex.extensions.subversion.XSvnApi';
import module namespace control-actions = 'http://transpect.io/control/util/control-actions' at 'util/control-actions.xq';
import module namespace control-api     = 'http://transpect.io/control/util/control-api'     at 'util/control-api.xq';
import module namespace control-i18n    = 'http://transpect.io/control/util/control-i18n'    at 'util/control-i18n.xq';
import module namespace control-util    = 'http://transpect.io/control/util/control-util'    at 'util/control-util.xq';
import module namespace control-widgets = 'http://transpect.io/control/util/control-widgets' at 'util/control-widgets.xq';

declare variable $control:locale          := doc('config.xml')/control:config/control:locale;
declare variable $control:host            := doc('config.xml')/control:config/control:host;
declare variable $control:port            := doc('config.xml')/control:config/control:port;
declare variable $control:path            := doc('config.xml')/control:config/control:path;
declare variable $control:datadir         := doc('config.xml')/control:config/control:datadir;
declare variable $control:db              := doc('config.xml')/control:config/control:db;
declare variable $control:max-upload-size := doc('config.xml')/control:config/control:max-upload-size;
declare variable $control:protocol        := if ($control:port = '443') then 'https' else 'http';
declare variable $control:siteurl         := $control:protocol || '://' || $control:host || ':' || $control:port || '/' || $control:path;
declare variable $control:svnusername     := (request:parameter('svnusername'), xs:string(doc('config.xml')/control:config/control:svnusername))[1];
declare variable $control:svnpassword     := (request:parameter('svnpassword'), xs:string(doc('config.xml')/control:config/control:svnpassword))[1];
declare variable $control:svnurl          := (request:parameter('svnurl'), xs:string(doc('config.xml')/control:config/control:svnurl))[1];
declare variable $control:msg             := request:parameter('msg');
declare variable $control:msgtype         := request:parameter('msgtype');
declare variable $control:action          := request:parameter('action');
declare variable $control:file            := request:parameter('file');
declare variable $control:dest-svnurl     := request:parameter('dest-svnurl');

declare
%rest:path('/control')
%output:method('html')
function control:control() as element() {
  control:main( $control:svnurl )
};
(:
 : this is where the "fun" starts...
 :)
declare function control:main( $svnurl as xs:string ) as element(html) {
  <html>
    <head>
      {control-widgets:get-html-head( )}
    </head>
    <body>
      {control-widgets:get-page-header( ),
       if( normalize-space($control:action) and normalize-space($control:file) )
       then control-widgets:manage-actions( $svnurl, ($control:dest-svnurl, $svnurl)[1], $control:action, $control:file )
       else ()}
      <main>
        {
         control:get-message( $control:msg, $control:msgtype ),
         if(normalize-space( $svnurl ))
         then control-widgets:get-dir-list( $svnurl, $control:path )
         else 'URL parameter empty!'}
      </main>
      {control-widgets:get-page-footer()}
    </body>
  </html>
};
(:
 : displays a message
:)
declare function control:get-message( $message as xs:string?, $messagetype as xs:string?) as element(div )?{
  if( $message )
  then
    <div id="message-wrapper">
      <div id="message">
        <p>{control-util:decode-uri( $message )}
          <button class="btn" onclick="hide('message-wrapper')">
            OK
            <img class="small-icon" src="{$control:path || '/static/icons/open-iconic/svg/check.svg'}" alt="ok"/>
          </button>
        </p>
      </div>
      <div id="message-background" class="{$messagetype}">
      </div>
    </div>
  else()
};
(:
 : Returns a file.
 : @param  $file  file or unknown path
 : @return rest binary data
 :)
declare
%rest:path("/control/static/{$file=.+}")
%perm:allow("all")
function control:file(
$file as xs:string
) as item()+ {
  let $path := file:base-dir() || 'static/' || $file
  return
    (
    web:response-header(
    map {'media-type': web:content-type( $path )},
    map {
      'Cache-Control': 'max-age=3600,public',
      'Content-Length': file:size( $path )
    }
    ),
    file:read-binary( $path )
    )
};