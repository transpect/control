module namespace control-widgets = 'http://transpect.io/control/util/control-widgets';
import module namespace svn = 'io.transpect.basex.extensions.subversion.XSvnApi';
import module namespace control = 'http://transpect.io/control' at '../control.xq';
import module namespace control-i18n = 'http://transpect.io/control/util/control-i18n' at 'control-i18n.xq';
import module namespace control-util = 'http://transpect.io/control/util/control-util' at 'control-util.xq';
declare namespace c = 'http://www.w3.org/ns/xproc-step';

(: 
 : gets the html head
 :)
declare function control-widgets:get-html-head( ) as element()+ {
  <meta charset="utf-8"></meta>,
  <title>control</title>,
  <script src="{ $control:siteurl || '/static/js/control.js'}" type="text/javascript"></script>,
  <link rel="stylesheet" type="text/css" href="{ $control:siteurl || '/static/style.css'}"></link>
};
declare function control-widgets:get-page-footer( ) as element(footer) {
  <footer>
    
  </footer>
};
(:
 : get the fancy page head
 :)
declare function control-widgets:get-page-header(  ) as element(header) {
  <header class="page-header">
    <div class="header-wrapper">
      <div id="logo">
        <a href="{ $control:siteurl }">
          <img src="{ $control:siteurl || '/static/icons/transpect.svg'}" alt="transpect logo"/>
        </a>
      </div>
      <h1><a href="{ $control:siteurl }"><span class="thin">transpect</span>control</a></h1>
    </div>
    <div class="nav-wrapper">
      <nav class="nav">
        <ol class="nav-ol">
          <li class="nav-tab"><a href="{ 'control/projects?svnurl=' || $control:svnurl   }">{control-i18n:localize('projects', $control:locale)}</a></li>
          <li class="nav-tab"><a>{control-i18n:localize('files', $control:locale)}</a></li>
          <li class="nav-tab"><a>{control-i18n:localize('configuration', $control:locale)}</a></li>
        </ol>
      </nav>
    </div>
  </header>
};
declare function control-widgets:get-svnhome-button( $svnurl as xs:string, $control-dir as xs:string ) as element(div){
  <div class="home">
    <a href="{concat($control-dir,
                     '?svnurl=',
                     svn:info($svnurl, 
                              $control:svnusername, 
                              $control:svnpassword)/*:param[@name eq 'root-url']/@value
                              )}">
      <button class="home action btn">
        <img class="small-icon" src="{$control-dir || '/static/icons/open-iconic/svg/home.svg'}" alt="home"/>
      </button>
    </a>
  </div>
};
declare function control-widgets:get-back-to-svndir-button( $svnurl as xs:string, $control-dir as xs:string ) as element(div){
  <div class="back">
    <a href="{$control-dir || '?svnurl=' || $svnurl}">
      <button class="back action btn">
        <img class="small-icon" src="{$control-dir || '/static/icons/open-iconic/svg/chevron-left.svg'}" alt="back"/>
      </button>
    </a>
  </div>
};
(:
 : get file action dropdown button
 :)
declare function control-widgets:get-file-action-dropdown( $svnurl as xs:string, $file as attribute(*) ) as element(details){
  <details class="file action dropdown">
    <summary class="btn">
      {control-i18n:localize('actions', $control:locale)}<span class="spacer"/>▼
    </summary>
    <div class="dropdown-wrapper">
      <ul>{
        if (name($file) = 'mount')
        then (
          <li>
           <a class="btn" href="{$control:path || '/external/remove?svnurl=' || $svnurl || '&amp;mount=' || $file }">{control-i18n:localize('remove-external', $control:locale)}</a>
          </li>,
          <li>
           <a class="btn" href="{$control:path || '/external/change-url?svnurl=' || $svnurl || '&amp;mount=' || $file }">{control-i18n:localize('change-url', $control:locale)}</a>
          </li>,
          <li>
           <a class="btn" href="{$control:path || '/external/change-mountpoint?svnurl=' || $svnurl || '&amp;mount=' || $file }">{control-i18n:localize('change-mountpoint', $control:locale)}</a>
          </li>
        ) else (
          <li>
           <a class="btn" href="#" onclick="{'createRenameForm(''' || $svnurl || ''', ''' || $file || ''', ''' || $control:path || ''')' }">{control-i18n:localize('rename', $control:locale)}</a>
          </li>,
          <li>
            <a class="btn" href="{$control:path || '/copy?svnurl=' || $svnurl || '&amp;action=copy&amp;file=' || $file }">{control-i18n:localize('copy', $control:locale)}</a>
          </li>,
          <li>
            <a class="btn" href="{$control:path || '/move?svnurl=' || $svnurl || '&amp;action=move&amp;file=' || $file }">{control-i18n:localize('move', $control:locale)}</a>
          </li>,
          <li>
            <a class="btn" href="{$control:path || '/delete?svnurl=' || $svnurl || '&amp;action=delete&amp;file=' || $file }">{control-i18n:localize('delete', $control:locale)}</a>
          </li>
        )
      }</ul>
    </div>
  </details>
};
(:
 : use request parameter and perform file action.
 :)
declare function control-widgets:manage-actions( $svnurl as xs:string, $dest-svnurl as xs:string?, $action as xs:string, $file as xs:string ) {
  if($action = ('copy', 'move')) 
      then control-widgets:display-window( $svnurl, $dest-svnurl, $action, $file )
    else if( $action = 'do-copy' )
      then svn:copy( $svnurl, 
                     $control:svnusername, $control:svnpassword, 
                     substring-after( $file, $svnurl ), substring-after( $dest-svnurl, $svnurl ), 'copy' )
    else () (: tbd :)
};
(:
 : display window
 :)
declare function control-widgets:display-window( $svnurl as xs:string, $dest-svnurl as xs:string?, $action as xs:string, $file as xs:string ) as element(div)+ {
  <div class="transparent-bg"></div>,
  <div class="transparent-fg">
    <div class="window-fg">
        { if($action = ('copy', 'move')) 
          then control-widgets:choose-directory( $svnurl, $dest-svnurl, 'do-' || $action, $file )
          else()
        }
    </div>
  </div>
};

(:
 : displays window to choose directory, usually needed for performing copy or delete actions 
 :)
declare function control-widgets:choose-directory( $svnurl as xs:string, $dest-svnurl as xs:string?, $action as xs:string, $file as xs:string ) as element(div) {
  <div class="choose-directory">
    <div class="window-actions"><a class="window-action close" href="{ $control:siteurl || '?svnurl=' || $svnurl }">&#x2a2f;</a></div>
    <h2>{ control-i18n:localize('choose-dir', $control:locale) }</h2>
    <div class="directory-list table">
      <div class="table-body">
      { for $files in svn:list(control-util:path-parent-dir( $svnurl ), $control:svnusername, $control:svnpassword, false())[local-name() ne 'errors']
        return 
            <div class="table-row directory-entry {local-name( $files )}">
              <div class="icon table-cell"/>
              <div class="name parentdir table-cell">
                <a href="{$control:siteurl || '/' || $action || '?svnurl=' || $svnurl || '&amp;dest-svnurl=' || control-util:path-parent-dir( $dest-svnurl ) || '&amp;action=' || $action || '&amp;file=' || $file }">..</a></div>
              </div>,
              for $files in svn:list( $dest-svnurl, $control:svnusername, $control:svnpassword, false())/*
              order by lower-case( $files/@name )
              order by $files/local-name()
              let $href := $control:siteurl || '/' || $action || '?svnurl=' || $svnurl || '&amp;dest-svnurl=' || $dest-svnurl || '/' || $files/@name || '&amp;action=' || $action || '&amp;file=' || $file
              return
                if( $files/local-name() eq 'directory' )
                then 
                  <div class="table-row directory-entry {local-name( $files )}">
                    <div class="table-cell icon">
                      <a href="{$href}">
                        <img src="{(concat( $control:path,
                                            '/../',
                                            control-util:get-mimetype-url(
                                                                          if( $files/local-name() eq 'directory') 
                                                                          then 'folder'
                                                                          else tokenize( $files/@name, '\.')[last()]
                                                                         )
                                    )
                             )}" alt="" class="file-icon"/>
                      </a>
                    </div>
                    <div class="name table-cell">
                      <a href="{$href}">{xs:string( $files/@name )}</a>
                    </div>
                    <div class="action table-cell">
                      { control-widgets:get-choose-directory-button( $svnurl, 'do-copy', $file, $dest-svnurl || '/' || $files/@name ) }
                    </div>
                  </div>
              else ()
      }
      </div>
    </div>
  </div>
};
declare function control-widgets:get-choose-directory-button( $svnurl as xs:string, $action as xs:string, $file as xs:string, $dest-svnurl as xs:string) as element(div){
  <div class="home">
    <a href="{ $control:path || '/..?svnurl=' || $svnurl || '&amp;action=' || $action || '&amp;file=' || $file || '&amp;dest-svnurl=' || $dest-svnurl }">
      <button class="select action btn">
        <img class="small-icon" src="{$control:path || '/../static/icons/open-iconic/svg/check.svg'}" alt="select"/>
        <span class="spacer"/>{control-i18n:localize('select', $control:locale )}
      </button>
    </a>
  </div>
};
(:
 : returns a html directory listing
:)
declare function control-widgets:get-dir-list( $svnurl as xs:string, $control-dir as xs:string ) as element(div) {
  <div class="directory-list-wrapper">
  {control-widgets:get-dir-menu( $svnurl, $control-dir )}        
    <div class="directory-list table">
      <div class="table-body">
        {control-widgets:list-dir-entries( $svnurl, $control-dir, map{'show-externals': true()} )}
      </div>
    </div>
  </div>
};
(:
 : get dir menu
 :)
declare function control-widgets:get-dir-menu( $svnurl as xs:string, $control-dir as xs:string ) {
  <div class="dir-menu">
    <div class="dir-menu-left">
      {control-widgets:get-svnhome-button( $svnurl, $control-dir )}
      <div class="path">{tokenize( $svnurl, '/')[last()]}&#xa0;/ </div>
      {control-widgets:create-dir-form( $svnurl, $control-dir )}
    </div>
    <div class="dir-menu-right">
      {control-widgets:get-dir-actions( $svnurl, $control-dir )}
    </div>
  </div>
};
(:
 : get action buttons to add new files, create dirs etc.
 :)
declare function control-widgets:get-dir-actions( $svnurl as xs:string, $control-dir as xs:string) as element(div )* {
  <div class="directory-actions">
    <a href="/control/new-file?svnurl={$svnurl}">
      <button class="new-file action btn">
        <img class="small-icon" src="{$control-dir || '/static/icons/open-iconic/svg/cloud-upload.svg'}" alt="new-file"/><span class="spacer"/>
        {control-i18n:localize('upload', $control:locale )}
      </button>
    </a>
    <button class="create-dir action btn" onclick="reveal('create-dir-form-wrapper')">
      <img class="small-icon" src="{$control-dir || '/static/icons/open-iconic/svg/folder.svg'}" alt="new-file"/><span class="spacer"/>
        {control-i18n:localize('create-dir', $control:locale )}
    </button>
    <a href="/control/download?svnurl={$svnurl}">
      <button class="download action btn">
        <img class="small-icon" src="{$control-dir || '/static/icons/open-iconic/svg/cloud-download.svg'}" alt="new-file"/><span class="spacer"/>
          {control-i18n:localize('download', $control:locale )}
      </button>
    </a>
  </div>
};
(:
 : provide directory listing
 :)
declare function control-widgets:list-dir-entries( $svnurl as xs:string,
                                           $control-dir as xs:string,
                                           $options as map(xs:string, item()*)? ) as element(div )* {
  control-widgets:get-dir-parent( $svnurl, $control-dir ),
  let $filename-filter-regex as xs:string? := $options?filename-filter-regex,
      $dirs-only as xs:boolean? := $options?dirs-only = true(),
      $add-query-params as xs:string? := $options?add-query-params,
      $show-externals as xs:boolean? := $options?show-externals = true()
  return
  (:<div>{svn:list( $svnurl, $control:svnusername, $control:svnpassword, false()), 
  control-util:parse-externals-property(svn:propget( $svnurl, $control:svnusername, $control:svnpassword, 'svn:externals', 'HEAD'))}</div>:)
  for $files in (
    svn:list( $svnurl, $control:svnusername, $control:svnpassword, false())/*,
    if ($show-externals) then
      control-util:parse-externals-property(svn:propget( $svnurl, $control:svnusername, $control:svnpassword, 'svn:externals', 'HEAD'))
    else ()
  )
  order by lower-case( $files/(@name | @mount) )
  order by $files/local-name()
  let $href := if ($files/self::external)
               then 
                 if (starts-with($files/@url, 'https://github.com/'))
                 then replace($files/@url, '/[^/]+/?$', '/')
                 else $control:siteurl || '?svnurl=' || $files/@url || '&amp;from=' || $svnurl || $add-query-params
               else if($files/local-name() eq 'directory')
                    then $control:siteurl || '?svnurl=' || $svnurl || '/' || $files/@name 
                      || '&amp;from='[request:parameter('from')] || request:parameter('from') || $add-query-params
                    else $svnurl || '/' || $files/@name
  return
    if(    not($dirs-only and $files/local-name() eq 'file')
       or  not(matches($files/@name, ($filename-filter-regex, '')[1])))
    then 
    <div class="table-row directory-entry {local-name( $files )}">
      <div class="table-cell icon">
        <a href="{$href}">
          <img src="{(concat( $control-dir,
                             '/',
                             control-util:get-mimetype-url(
                                       if( $files/local-name() eq 'directory') 
                                       then 'folder'
                                       else if ($files/self::external)
                                            then 'external'
                                            else tokenize( $files/@name, '\.')[last()]
                                       )
                      )
               )}" alt="" class="file-icon"/>
        </a>
      </div>
      <div class="name table-cell">
        <a href="{$href}" id="direntry-{xs:string( $files/@name )}">{xs:string( $files/(@name | @mount) )}</a></div>
      <div class="author table-cell">{xs:string( $files/@author )}</div>
      <div class="date table-cell">{xs:string( $files/@date )}</div>
      <div class="revision table-cell">{xs:string( $files/@revision )}</div>
      <div class="size table-cell">{$files/@size[$files/local-name() eq 'file']/concat(., '&#x202f;KB')}</div>
      <div class="action table-cell">{control-widgets:get-file-action-dropdown( ($svnurl, string($files/@url))[1], $files/(@name | @mount) )}</div>
    </div> 
    else()
};
(:
 : provides a row in the html direcory listing 
 : with the link to the parent directory
:)
declare function control-widgets:get-dir-parent( $svnurl as xs:string, $control-dir as xs:string ) as element(div )* {
  for $path in (
                  request:parameter('from'),
                  svn:list(
                    control-util:path-parent-dir( $svnurl ), 
                    $control:svnusername, $control:svnpassword, false()
                  )/self::c:files/@*:base
                )
  return 
    <div class="table-row directory-entry">
      <div class="icon table-cell"/>
      <div class="name parentdir table-cell">
        <a href="{$control-dir || '?svnurl=' || $path}">{if (request:parameter('from') and $path/position() = 1) then '←' else '..'}</a>
      </div>
      <div class="author table-cell"/>
      <div class="date table-cell"/>
      <div class="revision table-cell"/>
      <div class="size table-cell"/>
      <div class="actions table-cell"/>
    </div>
};
declare function control-widgets:create-dir-form( $svnurl as xs:string, $control-dir as xs:string ) {
  <div id="create-dir-form-wrapper">
    <form id="create-dir-form" action="/control/create-dir?url={$svnurl}" method="POST">
      <input type="text" id="dirname" name="dirname"/>
      <input type="hidden" name="svnurl" value="{$svnurl}" />
      <button class="btn ok" value="ok">
        OK
        <span class="spacer"/><img class="small-icon" src="{$control-dir || '/static/icons/open-iconic/svg/check.svg'}" alt="ok"/>
      </button>
    </form>
    <button class="btn cancel" value="cancel" onclick="hide('create-dir-form-wrapper')">
      Cancel
      <span class="spacer"/><img class="small-icon" src="{$control-dir || '/static/icons/open-iconic/svg/ban.svg'}" alt="cancel"/>
    </button>
  </div>
};