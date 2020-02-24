(:
 : transpect control
 :)
module namespace control = 'control';
import module namespace svn = 'io.transpect.basex.extensions.subversion.XSvnApi';
import module namespace control-i18n = 'control-i18n' at 'util/control-i18n.xq';
import module namespace control-rest = 'control-rest' at 'util/control-rest.xq';
import module namespace control-util = 'control-util' at 'util/control-util.xq';

declare variable $control:locale := 'de';
declare variable $control:host := 'localhost';
declare variable $control:port := '8984';
declare variable $control:dir := 'control';
declare variable $control:siteurl := concat('http://', $control:host, ':', $control:port, '/', $control:dir );
declare variable $control:svnusername := 'username';
declare variable $control:svnpassword := 'password';
declare variable $control:max-upload-size := '20'; (: MB :)
declare variable $control:queries := map:merge(for $query in tokenize(request:query(), '\?') 
                                               return map:entry(tokenize( $query, '=')[1], tokenize( $query, '=')[last()])) ;
declare variable $control:svnurl := map:get( $control:queries, 'svnurl');
declare variable $control:msg := map:get( $control:queries, 'msg');
declare variable $control:msgtype := map:get( $control:queries, 'msgtype');

declare
%rest:path('/control')
%output:method('html')
function control:control() as element() {
  control:main( $control:svnurl )
};
(:
 : this is where the fun starts...
 :)
declare function control:main( $svnurl as xs:string ) as element(html ) {
  <html>
    <head>
      {control-util:get-html-head( $control:dir )}
    </head>
    <body>
      {control-util:get-page-header( $control:dir )}
      <main>
        {control:get-message( $control:msg, $control:msgtype )}
        {if(normalize-space( $svnurl ))
         then control:get-dir-list( $svnurl )
         else 'URL parameter empty!'}
      </main>
      {control-util:get-page-footer()}
    </body>
  </html>
};
(:
 : returns a html directory listing
:)
declare function control:get-dir-list( $svnurl as xs:string ) as element(div ) {
  <div class="directory-list-wrapper">
    
    <div class="svnurl">
      {control-util:get-svnhome-button( $svnurl, $control:dir )}
      <div class="path">{tokenize( $svnurl, '/')[last()]}</div>
      {control:create-dir-form( $svnurl )}
    </div>
    {control:get-dir-actions( $svnurl )}
    <div class="directory-list table">
      <div class="table-body">
        {control:list-dir-entries( $svnurl )}
      </div>
    </div>
  </div>
};
(:
 : get action buttons to add new files, create dirs etc.
 :)
declare function control:get-dir-actions( $svnurl ) as element(div )* {
  <div class="directory-actions">
    <a href="/control/new-file?svnurl={$svnurl}">
      <button class="new-file action btn">
        <img class="small-icon" src="{$control:dir || '/static/icons/open-iconic/svg/file.svg'}" alt="new-file"/><span class="spacer"/>
        {control-i18n:localize('new-file', $control:locale )}
      </button>
    </a>
    <button class="create-dir action btn" onclick="reveal('create-dir-form-wrapper')">
      <img class="small-icon" src="{$control:dir || '/static/icons/open-iconic/svg/folder.svg'}" alt="new-file"/><span class="spacer"/>
        {control-i18n:localize('create-dir', $control:locale )}
    </button>
    <button class="download action btn">
      <img class="small-icon" src="{$control:dir || '/static/icons/open-iconic/svg/data-transfer-download.svg'}" alt="new-file"/><span class="spacer"/>
        {control-i18n:localize('download', $control:locale )}
    </button>
  </div>
};
declare function control:create-dir-form( $svnurl as xs:string ) {
  <div id="create-dir-form-wrapper">
    <form id="create-dir-form" action="/control/create-dir?url={$svnurl}" method="POST">
      <label>/</label>
      <input type="text" id="dirname" name="dirname"/>
      <input type="hidden" name="svnurl" value="{$svnurl}" />
      <button class="btn ok" value="ok">
        OK
        <img class="small-icon" src="{$control:dir || '/static/icons/open-iconic/svg/check.svg'}" alt="ok"/>
      </button>
    </form>
    <button class="btn cancel" value="cancel" onclick="hide('create-dir-form-wrapper')">
      Cancel
      <img class="small-icon" src="{$control:dir || '/static/icons/open-iconic/svg/ban.svg'}" alt="cancel"/>
    </button>
  </div>
};
(:
 : provides a row in the html direcory listing 
 : with the link to the parent directory
:)
declare function control:get-dir-parent( $svnurl as xs:string ) as element(div )? {
  for $files in svn:list(control-util:path-parent-dir( $svnurl ), $control:svnusername, $control:svnpassword, false())[local-name() ne 'errors']
  return 
    <div class="table-row directory-entry {local-name( $files )}">
      <div class="icon table-cell"/>
      <div class="name parentdir table-cell">
        <a href="{concat(
                         $control:siteurl,
                         '?svnurl=',
                         control-util:path-parent-dir( $svnurl )
                         )}">..</a></div>
      <div class="author table-cell"/>
      <div class="date table-cell"/>
      <div class="revision table-cell"/>
      <div class="size table-cell"/>
      <div class="actions table-cell"/>
    </div>
};
(:
 : returns each entry of the directory as single html row
:)
declare function control:list-dir-entries( $svnurl ) as element(div )* {
  control:get-dir-parent( $svnurl ),
  for $files in svn:list( $svnurl, $control:svnusername, $control:svnpassword, false())/*
  order by lower-case( $files/@name )
  order by $files/local-name()
  return
    <div class="table-row directory-entry {local-name( $files )}">
      <div class="table-cell icon">
        <a href="{concat(
                   $control:siteurl,
                   '?svnurl=',
                   $svnurl,
                   '/',
                   $files/@name
            )}">
          <img src="{(concat( $control:dir,
                             '/',
                             control:get-mimetype-url(
                                       if( $files/local-name() eq 'directory') 
                                       then 'folder'
                                       else tokenize( $files/@name, '\.')[last()]
                                       )
                      )
               )}" alt="" class="file-icon"/>
        </a>
      </div>
      <div class="name table-cell">
        <a href="{concat(
                         $control:siteurl,
                         '?svnurl=',
                         $svnurl,
                         '/',
                         $files/@name
                  )}">{xs:string( $files/@name )}</a></div>
      <div class="author table-cell">{xs:string( $files/@author )}</div>
      <div class="date table-cell">{xs:string( $files/@date )}</div>
      <div class="revision table-cell">{xs:string( $files/@revision )}</div>
      <div class="size table-cell">{$files/@size[$files/local-name() eq 'file']/concat(., '&#x202f;KB')}</div>
      <div class="action table-cell">{control:get-file-action-button( $files/@name )}</div>
    </div> 
};
(:
 : get file action dropdown button
 :)
declare function control:get-file-action-button( $basename as xs:string ) as element(button ){
  <button class="file action btn">{control-i18n:localize('actions', $control:locale )} ▼</button>
};
(:
 : get icon url for an icon name
 :)
declare function control:get-mimetype-url( $ext as xs:string? ) as xs:string {
  if (( $ext ) eq 'folder')
  then 'static/icons/flat-remix/Flat-Remix-Blue-Dark/places/scalable/folder-black.svg'
  else concat('static/icons/flat-remix/Flat-Remix-Blue-Dark/mimetypes/scalable/',
              control:ext-to-mimetype( $ext ),
              '.svg' )
};
(:
 : get mimetype for file extension
 :)
declare function control:ext-to-mimetype( $ext as xs:string ) as xs:string {
     if ( $ext eq 'xml')              then 'text-xml'
else if ( $ext eq 'text')             then 'text-plain'
else if ( $ext = ('Makefile', 'bat')) then 'text-x'
else                                      'text-plain'
};

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
(:~
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