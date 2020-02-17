(:
 : transpect control
 :)
module namespace control = 'control';
import module namespace svn = 'io.transpect.basex.extensions.subversion.XSvnApi';
import module namespace control-util = 'control-util' at 'util/control-util.xq';
import module namespace control-i18n = 'control-i18n' at 'util/control-i18n.xq';

declare variable $control:locale := 'de';
declare variable $control:host := 'localhost';
declare variable $control:port := '8984';
declare variable $control:dir := 'control';
declare variable $control:name := concat('http://', $control:host, ':', $control:port, '/', $control:dir);
declare variable $control:svnusername := 'username';
declare variable $control:svnpassword := 'password';
declare variable $control:svnurl := replace(request:query(), '^url=', '');

declare
%rest:path('/control')
%output:method('html')
function control:control() as element() {
  control:main()
};
(:
 : this is where the fun starts...
 :)
declare function control:main() as element(html) {
  <html>
    <head>
      <meta charset="utf-8"></meta>
      <title>control</title>
      <link rel="stylesheet" type="text/css" href="{$control:dir || '/static/style.css'}"></link>
    </head>
    <body>
      <header>
        <div id="logo">
          <img src="{$control:dir || '/static/icons/transpect.svg'}" alt="transpect logo"/>
        </div>
        <h1><span class="thin">transpect</span>control</h1>
        <div class="wrapper"/>        
      </header>
      <main>
        <div class="col1">
        </div>
        <div class="col2">
          {if(normalize-space($control:svnurl))
           then control:get-dir-list($control:svnurl, $control:svnusername, $control:svnpassword)
           else 'URL parameter empty!'
          }
        </div>
        <div class="col3">
        </div>
      </main>
      <footer>
      </footer>
    </body>
  </html>
};
(:
 : returns a html directory listing
:)
declare function control:get-dir-list($svnurl as xs:string, $svnusername as xs:string, $svnpassword as xs:string) as element(div) {
  <div class="directory-list-wrapper">
    <div class="svnurl">      
      <a href="{ concat($control:name,
                        '?url=',
                        svn:info("https://subversion.le-tex.de/customers/suhrkamp/transpect/trunk", $svnusername, $svnpassword)/*:param[@name eq 'root-url']/@value
                        ) }">
        <button class="create-dir action btn">
          <img class="small-icon" src="{$control:dir || '/static/icons/open-iconic/svg/home.svg'}" alt="home"/>
        </button>
      </a>
      <span class="spacer"/>
      {$svnurl}
    </div>
    {control:get-dir-actions($svnurl, $svnusername, $svnpassword)}
    <div class="directory-list table">
      <div class="table-body">
        {control:list-dir-entries($control:svnurl, $control:svnusername, $control:svnpassword)}
      </div>
    </div>
  </div>
};
(:
 : get action buttons to add new files, create dirs etc.
 :)
declare function control:get-dir-actions($svnurl as xs:string, $svnusername as xs:string, $svnpassword as xs:string) as element(div)* {
  <div class="directory-actions">
    <button class="new-file action btn">
      <img class="small-icon" src="{$control:dir || '/static/icons/open-iconic/svg/file.svg'}" alt="new-file"/><span class="spacer"/>
      {control-i18n:localize('new-file', $control:locale)}
    </button>
    <button class="create-dir action btn">
      <img class="small-icon" src="{$control:dir || '/static/icons/open-iconic/svg/folder.svg'}" alt="new-file"/><span class="spacer"/>
        {control-i18n:localize('create-dir', $control:locale)}
    </button>
    <button class="download action btn">
      <img class="small-icon" src="{$control:dir || '/static/icons/open-iconic/svg/data-transfer-download.svg'}" alt="new-file"/><span class="spacer"/>
        {control-i18n:localize('download', $control:locale)}
    </button>
  </div>
};
(:
 : provides a row in the html direcory listing 
 : with the link to the parent directory
:)
declare function control:get-dir-parent($svnurl as xs:string, $svnusername as xs:string, $svnpassword as xs:string) as element(div)? {
  for $files in svn:list(control-util:path-parent-dir($svnurl), $svnusername, $svnpassword, false())[local-name() ne 'errors']
  return 
    <div class="table-row directory-entry {local-name($files)}">
      <div class="icon table-cell"/>
      <div class="name table-cell">
        <a href="{concat(
                         $control:name,
                         '?url=',
                         control-util:path-parent-dir($svnurl)
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
declare function control:list-dir-entries($svnurl, $svnusername, $svnpassword as xs:string) as element(div)* {
  control:get-dir-parent($svnurl, $svnusername, $svnpassword),
  for $files in svn:list($svnurl, $svnusername, $svnpassword, false())/*
  order by lower-case($files/@name)
  order by $files/local-name()
  return
    <div class="table-row directory-entry {local-name($files)}">
      <div class="table-cell icon">
        <img src="{(concat($control:dir,
                           '/',
                           control:get-mimetype-url(
                                     if($files/local-name() eq 'directory') 
                                     then 'folder'
                                     else tokenize($files/@name, '\.')[last()]
                                     )
                    )
             )}" alt="" class="file-icon"/>
      </div>
      <div class="name table-cell">
        <a href="{concat(
                         $control:name,
                         '?url=',
                         $svnurl,
                         '/',
                         $files/@name
                  )}">{xs:string($files/@name)}</a></div>
      <div class="author table-cell">{xs:string($files/@author)}</div>
      <div class="date table-cell">{xs:string($files/@date)}</div>
      <div class="revision table-cell">{xs:string($files/@revision)}</div>
      <div class="size table-cell">{$files/@size[$files/local-name() eq 'file']/concat(., '&#x202f;KB')}</div>
      <div class="action table-cell">{control:get-file-action-button($files/@name)}</div>
    </div> 
};
(:
 : get file action dropdown button
 :)
declare function control:get-file-action-button($basename as xs:string) as element(button){
  <button class="file action btn">{control-i18n:localize('actions', $control:locale)} ▼</button>
};
(:
 : get icon url for an icon name
 :)
declare function control:get-mimetype-url( $ext as xs:string? ) as xs:string {
  if (($ext) eq 'folder')
  then 'static/icons/flat-remix/Flat-Remix-Blue-Dark/places/scalable/folder-black.svg'
  else concat('static/icons/flat-remix/Flat-Remix-Blue-Dark/mimetypes/scalable/',
              control:ext-to-mimetype($ext),
              '.svg' )
};
(:
 : get mimetype for file extension
 :)
declare function control:ext-to-mimetype($ext as xs:string) as xs:string {
     if ($ext eq 'xml')              then 'text-xml'
else if ($ext eq 'text')             then 'text-plain'
else if ($ext = ('Makefile', 'bat')) then 'text-x'
else                                      'text-plain'
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
    map {'media-type': web:content-type($path)},
    map {
      'Cache-Control': 'max-age=3600,public',
      'Content-Length': file:size($path)
    }
    ),
    file:read-binary($path)
    )
};