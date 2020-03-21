(:
 : transpect control
 :)
module namespace        control         = 'control';
import module namespace svn             = 'io.transpect.basex.extensions.subversion.XSvnApi';
import module namespace control-i18n    = 'control-i18n'    at 'util/control-i18n.xq';
import module namespace control-rest    = 'control-rest'    at 'util/control-rest.xq';
import module namespace control-util    = 'control-util'    at 'util/control-util.xq';
import module namespace control-widgets = 'control-widgets' at 'util/control-widgets.xq';

declare variable $control:locale          := 'de';
declare variable $control:host            := 'localhost';
declare variable $control:port            := '8984';
declare variable $control:dir             := 'control';
declare variable $control:siteurl         := 'http://' || $control:host || ':' || $control:port || '/' || $control:dir;
declare variable $control:svnusername     := 'username';
declare variable $control:svnpassword     := 'password';
declare variable $control:max-upload-size := '20'; (: MB :)
declare variable $control:svnurl          := request:parameter('svnurl');
declare variable $control:msg             := request:parameter('msg');
declare variable $control:msgtype         := request:parameter('msgtype');
declare variable $control:action          := request:parameter('action');
declare variable $control:file            := request:parameter('file');
declare variable $control:alt-svnurl      := request:parameter('alt-svnurl');

declare
%rest:path('/control')
%output:method('html')
function control:control() as element() {
  control:main( $control:svnurl )
};
(:
 : this is where the fun starts...
 :)
declare function control:main( $svnurl as xs:string ) as element(html) {
  <html>
    <head>
      {control-widgets:get-html-head( $control:dir )}
    </head>
    <body>
      {control-widgets:get-page-header( $control:dir ),
       if( normalize-space($control:action) and normalize-space($control:file) )
       then control-widgets:manage-file-actions( $svnurl, ($control:alt-svnurl, $svnurl)[1], $control:action, $control:file )
       else ()}
      <main>
        {control:get-message( $control:msg, $control:msgtype ),
         if(normalize-space( $svnurl ))
         then control-widgets:get-dir-list( $svnurl, $control:dir )
         else 'URL parameter empty!'}
      </main>
      {control-widgets:get-page-footer()}
    </body>
  </html>
};
(:
 : returns each entry of the directory as single html row
:)
declare function control:get-message( $message as xs:string?, $messagetype as xs:string?) as element(div )?{
  if( $message )
  then
    <div id="message-wrapper">
      <div id="message">
        <p>{control-util:decode-uri( $message )}
          <button class="btn" onclick="hide('message-wrapper')">
            OK
            <img class="small-icon" src="{$control:dir || '/static/icons/open-iconic/svg/check.svg'}" alt="ok"/>
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