module namespace control-widgets = 'http://transpect.io/control/util/control-widgets';
import module namespace svn = 'io.transpect.basex.extensions.subversion.XSvnApi';
import module namespace control = 'http://transpect.io/control' at '../control.xq';
import module namespace control-i18n = 'http://transpect.io/control/util/control-i18n' at 'control-i18n.xq';
import module namespace control-util = 'http://transpect.io/control/util/control-util' at 'control-util.xq';
declare namespace c = 'http://www.w3.org/ns/xproc-step';

(: 
 : gets the html head 202202181307
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
 :
 :)
declare function control-widgets:manage-conversions($svnurl as xs:string, $file as xs:string, $type as xs:string){
  let $repo := tokenize(svn:info($svnurl, $control:svnauth)/*:param[@name = 'root-url']/@value,'/')[last()],
      $filepath := replace(
                     replace(
                       string-join(
                         ($svnurl,$file),'/'),'/$','')
                         ,svn:info(
                           $svnurl, $control:svnauth)/*:param[@name = 'root-url']/@value
                         ,'')
  return
    <div class="conversion-widget">
    <h1> {control-i18n:localize('convert-title', $control:locale ) || ' ' || $filepath }</h1>
    <div id="streamed-data" class="hidden">
    {control-util:get-running-conversions($svnurl, $file, $type)}</div>
    <div class="table">
    {control-i18n:localize('running_conversions', $control:locale )}
      <div class="table-body">
        <div class="table-row">
          <div class="table-cell">{control-i18n:localize('status', $control:locale )}</div>
          <div class="table-cell">{control-i18n:localize('converter', $control:locale )}</div>
          <div class="table-cell">{control-i18n:localize('cancel', $control:locale )}</div>
          <div class="table-cell">{control-i18n:localize('delete', $control:locale )}</div>
        </div>
      </div>
      {for $conversion in control-util:get-running-conversions($svnurl, $file, $type)
       return <div class="table-row">
                <div class="table-cell">{$conversion/control:status}</div>
                <div class="table-cell">{$conversion/control:type}</div>
                <div class="table-cell">{$conversion/control:delete}</div>
                <div class="table-cell">{$conversion/control:callback}</div>
              </div>}
      </div>
      
      <h2> {control-i18n:localize('start_conversion', $control:locale ) || ' ' || $filepath }</h2>
      <form action="{$control:siteurl}/convert/start?svnurl={$svnurl}&amp;file={$file}&amp;type={$type}" method="POST" enctype="application/x-www-form-urlencoded" autocomplete="off">
        <div class="start-new-conversion">
          <input type="submit" value="{control-i18n:localize('start_conversion', $control:locale)}"/>
        </div>
      </form>
      <button class="btn">
        <a href="{$control:siteurl}?svnurl={$svnurl}">{control-i18n:localize('back', $control:locale)}</a>
      </button>
    </div>
};


(:
 : get the fancy page head
 :)
declare function control-widgets:get-page-header() as element(header) {
let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
    $username := $credentials[1]
return
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
          <li class="nav-tab"><a href="{ $control:siteurl|| '?svnurl=' || $control:svnurlhierarchy }">{control-i18n:localize('files', $control:locale)}</a></li>
          <li class="nav-tab">{
            if (control-util:is-admin($username))
            then 
              <a href="{$control:siteurl ||  '/config?svnurl=' || $control:svnurl}">{control-i18n:localize('configuration', $control:locale)}</a>
          }
          </li>
        </ol>
        <ol class="username">
          <li class="nav-tab"><a href="{$control:siteurl ||  '/user'}">{$username}</a></li>
        </ol>
      </nav>
    </div>
  </header>
};
declare function control-widgets:get-svnhome-button( $svnurl as xs:string, $control-dir as xs:string, $auth as map(*) ) as element(div){
  <div class="home">
    <a href="{(:concat($control-dir,
                     '?svnurl=',
                     $control:svnbase):)
               concat($control-dir,
               '?svnurl=',
               svn:info($svnurl, $auth)/*:param[@name eq 'root-url']/@value)
              }">
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

declare function control-widgets:rebuild-index($svnurl as xs:string,
                                               $name as xs:string) as element(div){
  <div class="adminmgmt">
    <h2>{control-i18n:localize('rebuildindex', $control:locale)}</h2>
    <button class="btn ok" >
      <a href="{$control:siteurl}/config/rebuildindex?svnurl={$svnurl}&amp;name={$name}">
        {control-i18n:localize('rebuildindexbtn', $control:locale)}
      </a>
    </button>
  </div>
};
(:
 : get file action dropdown button
 :)
declare function control-widgets:get-file-action-dropdown( $svnurl as xs:string, $file as attribute(*)? ) as element(details){
  <details class="file action dropdown autocollapse">
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
           <a class="btn" href="#" onclick="{'showLogForm(''' || $svnurl || ''', ''' || $file || ''', ''' || $control:path || ''')' }">{control-i18n:localize('showLog', $control:locale)}</a>
          </li>,
          <li>
           <a class="btn" href="#" onclick="{'showInfoForm(''' || $svnurl || ''', ''' || $file || ''', ''' || $control:path || ''')' }">{control-i18n:localize('showInfo', $control:locale)}</a>
          </li>,
          <li>
            <a class="btn" href="{$control:path || '/copy?svnurl=' || $svnurl || '&amp;action=copy&amp;file=' || $file }">{control-i18n:localize('copy', $control:locale)}</a>
          </li>,
          <li>
            <a class="btn" href="{$control:path || '/access?svnurl=' || $svnurl || '&amp;action=access&amp;file=' || $file }">{control-i18n:localize('access', $control:locale)}</a>
          </li>,
          <li>
            <a class="btn" href="{$control:path || '/move?svnurl=' || $svnurl || '&amp;action=move&amp;file=' || $file }">{control-i18n:localize('move', $control:locale)}</a>
          </li>,
          <li>
            <a class="btn" href="{$control:path || '/move?svnurl=' || $svnurl || '&amp;action=move&amp;file=' || $file }">{control-i18n:localize('move', $control:locale)}</a>
          </li>,
          <li>
            <a class="btn" href="{$control:path || '/delete?svnurl=' || $svnurl || '&amp;file=' || $file || '&amp;action=delete'}">{control-i18n:localize('delete', $control:locale)}</a>
          </li>,
          if (control-util:is-file($file))
          then (
          <li>
            <a class="btn" download="" href="{control-util:create-download-link($svnurl, $file)}">{control-i18n:localize('download', $control:locale)}</a>
          </li>,
          for $c in control-util:get-converters-for-file($file)
          let $type := $control:converters/converter/types/type[@type = $c]
          return 
            <li>
              <a class="btn" href="{$control:path || '/convert?svnurl=' || $svnurl || '&amp;file=' || $file || '&amp;type=' || $c}">{control-i18n:localize($type/@text, $control:locale)}</a>
            </li>
          )
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
                     $control:svnauth, 
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
              for $files in svn:list( $dest-svnurl, $control:svnauth, false())/*
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
declare function control-widgets:get-dir-list( $svnurl as xs:string, $control-dir as xs:string, $is-svn as xs:boolean, $auth as map(*)) as element(div) {
  <div class="directory-list-wrapper">
  {control-widgets:get-dir-menu( $svnurl, $control-dir, $auth )}
    <div class="directory-list table">
       {(svn:list( $svnurl, $auth, true())/*,
           control-util:parse-externals-property(svn:propget($svnurl, $auth, 'svn:externals', 'HEAD')))}
      <div class="table-body">
        {control-widgets:list-dir-entries( $svnurl, $control-dir, map{'show-externals': true()})}
      </div>
    </div>
  </div>
};


declare function control-widgets:create-infobox()
{
<div id="infobox" class="infobox" style="visibility:hidden">
  <div class="header">
    <div class="heading"></div>
    <div class="closebutton" onclick="closebox(); return false">X</div>
  </div>
  <div class="content"></div>
</div>
};
(:
 : returns controls to modify access to directory
:)
declare function control-widgets:file-access( $svnurl as xs:string, $file as xs:string ) as element(div) {
  let $repo := tokenize(svn:info($svnurl, $control:svnauth)/*:param[@name = 'root-url']/@value,'/')[last()],
      $filepath := replace(
                     replace(
                       string-join(
                         ($svnurl,$file),'/'),'/$','')
                         ,svn:info(
                           $svnurl, $control:svnauth)/*:param[@name = 'root-url']/@value
                         ,'')
      
  return
    <div class="access-widget">
    <h1> {control-i18n:localize('perm-title', $control:locale ) || ' ' || $filepath }</h1>
    <div id="streamed-data" class="hidden">
    {control-util:get-permissions-for-file($svnurl, $file, $control:access)}</div>
    <div class="table">
    {control-i18n:localize('existingrights', $control:locale )}
      <div class="table-body">
        <div class="table-row">
          <div class="table-cell">{control-i18n:localize('group', $control:locale )}</div>
          <div class="table-cell">{control-i18n:localize('permission', $control:locale )}</div>
          <div class="table-cell">{control-i18n:localize('implicit', $control:locale )}</div>
          <div class="table-cell">{control-i18n:localize('delete', $control:locale )}</div>
        </div>
      </div>
      {for $access in control-util:get-permissions-for-file($svnurl, $file,$control:access)
       return <div class="table-row">
                <div class="table-cell">{$access/g}</div>
                <div class="table-cell">{$access/p/text()}</div>
                {if ($access/i = true())
                then
                  <div class="table-cell">implicit</div>
                else
                 (<div class="table-cell">explicit</div>,
                  <div class="table-cell"><a class="delete" href="{$control:siteurl}/group/removepermission?svnurl={$svnurl}&amp;file={$file}&amp;group={$access/*:g/text()}">&#x1f5d1;</a></div>)
                }
              </div>}
      </div>
      
      <h2> {control-i18n:localize('set-perm', $control:locale ) || ' ' || $filepath }</h2>
      <form action="{$control:siteurl}/group/setaccess?svnurl={$svnurl}&amp;file={$file}" method="POST" enctype="application/x-www-form-urlencoded" autocomplete="off">
        <div class="add-new-access">
          <div class="form">
            <label for="groupname" class="leftlabel">{concat(control-i18n:localize('selectgroup', $control:locale),':')}</label>
            <select name="groups" id="groupselect">
              {control-widgets:get-groups( $svnurl )}
            </select>
          </div>
          <div class="form">
            <label for="access" class="leftlabel">{concat(control-i18n:localize('selectdiraccess', $control:locale),':')}</label>
            <select name="access" id="readwrite">
              <option value="none">{control-i18n:localize('none', $control:locale)}</option>
              <option value="read">{control-i18n:localize('read', $control:locale)}</option>
              <option value="write">{control-i18n:localize('write', $control:locale)}</option>
            </select>
          </div>
          <br/>
          <input type="submit" value="{control-i18n:localize('submit', $control:locale)}"/>
        </div>
      </form>
      <button class="btn">
        <a href="{$control:siteurl}?svnurl={$svnurl}">{control-i18n:localize('back', $control:locale)}</a>
      </button>
    </div>
};
(:
 : get dir menu
 :)
declare function control-widgets:get-dir-menu( $svnurl as xs:string, $control-dir as xs:string, $auth as map(*) ) {
  <div class="dir-menu">
    <div class="dir-menu-left">
      {control-widgets:get-svnhome-button( $svnurl, $control-dir, $auth )}
      <div class="path">{tokenize($svnurl,'/')[last()]}&#xa0;/ </div>
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
declare function control-widgets:get-dir-actions( $svnurl as xs:string, $control-dir as xs:string?) as element(div )* {
  <div class="directory-actions">
    <a href="{$control:siteurl||'/new-file?svnurl='||$svnurl}">
      <button class="new-file action btn">
        <img class="small-icon" src="{$control-dir || '/static/icons/open-iconic/svg/cloud-upload.svg'}" alt="new-file"/><span class="spacer"/>
        {control-i18n:localize('upload', $control:locale )}
      </button>
    </a>
    <button class="create-dir action btn" onclick="reveal('create-dir-form-wrapper')">
      <img class="small-icon" src="{$control-dir || '/static/icons/open-iconic/svg/folder.svg'}" alt="new-file"/><span class="spacer"/>
        {control-i18n:localize('create-dir', $control:locale )}
    </button>
  </div>
};
(:
 : provide directory listing
 :)
declare function control-widgets:list-dir-entries( $svnurl as xs:string,
                                           $control-dir as xs:string,
                                           $options as map(xs:string, item()*)?) as element(div )* {
  control-widgets:get-dir-parent( $svnurl, $control-dir, '' ),
  let $filename-filter-regex as xs:string? := $options?filename-filter-regex,
      $dirs-only as xs:boolean? := $options?dirs-only = true(),
      $add-query-params as xs:string? := $options?add-query-params,
      $show-externals as xs:boolean? := $options?show-externals = true(),
      $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
      $username := $credentials[1],
      $auth := map{'username':$credentials[1],'cert-path':'', 'password': $credentials[2]}
  return
  for $files in (
    svn:list( $svnurl, $auth, true())/*,
    if ($show-externals) then
      control-util:parse-externals-property(svn:propget($svnurl, $auth, 'svn:externals', 'HEAD'))
    else ()
  )
  order by lower-case( $files/(@name | @mount) )
  order by $files/local-name()
  let $from-expression := '&amp;fromsvnurl=' || $svnurl,
      $href := if ($files/self::external)
               then 
                 if (starts-with($files/@url, 'https://github.com/'))
                 then replace($files/@url, '/[^/]+/?$', '/')
                 else $control:siteurl || '?svnurl=' || $files/@url || $from-expression || $add-query-params
               else if($files/local-name() eq 'directory')
                    then $control:siteurl || '?svnurl=' || replace($svnurl,'/$','') || '/' || $files/@name 
                      || $from-expression|| $add-query-params
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
        <a href="{if ($files/local-name() eq 'file') then control-util:create-download-link($svnurl, $files/@name) else $href}" id="direntry-{xs:string( $files/@name )}">{xs:string( $files/(@name | @mount) )}</a></div>
      <div class="author table-cell">{xs:string( $files/@author )}</div>
      <div class="date table-cell">{xs:string( $files/@date )}</div>
      <div class="revision table-cell">{xs:string( $files/@revision )}</div>
      <div class="size table-cell">{$files/@size[$files/local-name() eq 'file']/concat(., '&#x202f;KB')}</div>
      <div>{svn:info($svnurl,
                     $auth)/*:param[@name eq 'root-url']/@value
                    }</div>
      <div class="action table-cell">{if (control-util:get-rights($username, xs:string($files/@name)) = "write") 
                                      then control-widgets:get-file-action-dropdown( ($svnurl, string($files/@url))[1], $files/(@name | @mount) ) 
                                      else ""}</div>
    </div> 
    else ()
};
(:
 : provide directory listing for local repo
 :)
(:declare function control-widgets:list-admin-dir-entries( $svnurl as xs:string,
                                           $repopath as xs:string,
                                           $control-dir as xs:string,
                                           $options as map(xs:string, item()*)? ) as element(div)* {
  control-widgets:get-dir-parent( $svnurl, $control-dir, $repopath ),
  let $filename-filter-regex as xs:string? := $options?filename-filter-regex,
      $dirs-only as xs:boolean? := $options?dirs-only = true(),
      $add-query-params as xs:string? := $options?add-query-params,
      $show-externals as xs:boolean? := $options?show-externals = true(),
      $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
      $username := $credentials[1],
      $auth := map{'username':$credentials[1],'cert-path':'', 'password': $credentials[2]}
  return
  for $files in (
    (\:if (not(matches($svnurl, '^http')))
    then 
      svn:list( $svnurl, $auth, false())/*,
      if ($show-externals) then
        control-util:parse-externals-property(svn:propget( $svnurl, $auth, 'svn:externals', 'HEAD'))
    else:\)
      svn:look( $svnurl,$repopath, $auth, false())/*,
      if ($show-externals) then
        control-util:parse-externals-property(svn:propget( $svnurl || $repopath, $auth, 'svn:externals', 'HEAD'))
  )
  order by lower-case( $files/(@name | @mount) )
  order by $files/local-name()
  let $from-expression := if ($repopath)
                         then '&amp;fromsvnurl=' || $svnurl || '&amp;fromrepopath=' || $repopath
                         else '&amp;fromsvnurl=' || $svnurl,
      $href := if ($files/self::external)
               then 
                 if (starts-with($files/@url, 'https://github.com/'))
                 then replace($files/@url, '/[^/]+/?$', '/')
                 else $control:siteurl || '?svnurl=' || $files/@url || $from-expression || $add-query-params
               else 
                if($files/local-name() eq 'directory')
                then $control:siteurl || '?svnurl=' || $svnurl  || '&amp;repopath=' || $repopath || '/' || $files/@name 
                  || $from-expression || $add-query-params
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
        <a href="{$href}" id="direntry-{xs:string( $files/@name )}">{xs:string( $files/(@name | @mount) )}</a>
        {$files}</div>
      <div class="author table-cell">{xs:string( $files/@author )}</div>
      <div class="date table-cell">{xs:string( $files/@date )}</div>
      <div class="revision table-cell">{xs:string( $files/@revision )}</div>
      <div class="size table-cell">{$files/@size[$files/local-name() eq 'file']/concat(., '&#x202f;KB')}</div>
      <div class="action table-cell">{if (control-util:get-rights($username, xs:string($files/@name)) = "write") 
                                      then control-widgets:get-file-action-dropdown( ($svnurl, string($files/@url))[1], $repopath, $files/(@name | @mount) ) 
                                      else ""}</div>
    </div>
    else()
};:)

(:
 : provides a row in the html direcory listing 
 : with the link to the parent directory
:)
declare function control-widgets:get-dir-parent( $svnurl as xs:string, $control-dir as xs:string, $repopath as xs:string? ) as element(div )* {
  let $new-svnurl := control-util:path-parent-dir($svnurl),
      $new-repopath := if ($repopath!= '') then replace($repopath,'/?[^/]+/?$','') else '',
      $path := (request:parameter('from'),
                svn:list(
                  control-util:path-parent-dir( $svnurl ), 
                  $control:svnauth, false()
                )/self::c:files/@*:base)[1]
  return 
    <div class="table-row directory-entry">
      <div class="icon table-cell"/>
      { if ($new-svnurl)
        then 
          <div class="name parentdir table-cell">
            <a href="{$control-dir || '?svnurl=' || $new-svnurl}">{if (request:parameter('from') eq $path) 
                            then '←' 
                            else '..'}</a>
          </div>
          else
          <div class="name parentdir table-cell"></div>
      }
      <div class="author table-cell"/>
      <div class="date table-cell"/>
      <div class="revision table-cell"/>
      <div class="size table-cell"/>
      <div class="actions table-cell"/>
    </div>
};
declare function control-widgets:create-dir-form( $svnurl as xs:string, $control-dir as xs:string ) {
  <div id="create-dir-form-wrapper">
    <form id="create-dir-form" action="{$control:siteurl||'/create-dir?url='||$svnurl}" method="POST">
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
(:
 : return a form for creating a new user/overriding an existing one
 :)
declare function control-widgets:create-new-user($svnurl as xs:string) as element(div) {
  <div class="adminmgmt">
    <h2>{control-i18n:localize('createuser', $control:locale)}</h2>
    <form action="{$control:siteurl}/user/createuser?svnurl={$svnurl}" method="POST" enctype="application/x-www-form-urlencoded" autocomplete="off">
      <div class="createuser">
        <div class="form">
          <label for="newusername" class="leftlabel">{concat(control-i18n:localize('username', $control:locale),':')}</label>
          <input type="text" id="newusername" name="newusername" pattern="[A-Za-z0-9]+" title="Nutzen Sie nur Buchstaben und Zahlen"/>
        </div>
        <div class="form">
          <label for="newpassword" class="leftlabel">{concat(control-i18n:localize('initpw', $control:locale),':')}</label>
          <input type="password" id="newpassword" name="newpassword" autocomplete="new-password" pattern="....+" title="Bitte geben Sie mehr als 3 Zeichen ein."/>
        </div>
        <div class="form">
          <label for="defaultsvnurl" class="leftlabel">{concat(control-i18n:localize('defaultsvnurl', $control:locale),':')}</label>
          <input type="text" id="defaultsvnurl" name="defaultsvnurl" autocomplete="new-password"/>
        </div>
        <br/>
        <input type="submit" value="{control-i18n:localize('submit', $control:locale)}"/>
      </div>
    </form>
  </div>
};
(:
 : returns a form for changing the password
 :)
declare function control-widgets:get-pw-change() as element(div) {
  <div class="adminmgmt">
    <h2>{control-i18n:localize('changepassword', $control:locale)}</h2>
    <form action="{$control:siteurl}/user/setpw" method="POST" enctype="application/x-www-form-urlencoded" autocomplete="off">
      <div class="setpw">
        <div class="form">
          <label for="old-pwd" class="leftlabel">{concat(control-i18n:localize('oldpw', $control:locale),':')}</label>
          <input type="password" id="old-pwd" name="oldpw" autocomplete="new-password"/>
        </div>
        <div class="form">
          <label for="new-pwd" class="leftlabel">{concat(control-i18n:localize('newpw', $control:locale),':')}</label>
          <input type="password" id="new-pwd" name="newpw" autocomplete="new-password" pattern="....+" title="{control-i18n:localize('pwregextip', $control:locale)}"/>
        </div>
        <div class="form">
          <label for="new-pwd-re" class="leftlabel">{concat(control-i18n:localize('newpwre', $control:locale),':')}</label>
          <input type="password" id="new-pwd-re" name="newpwre" autocomplete="new-password" pattern="....+" title="{control-i18n:localize('pwregextip', $control:locale)}"/>
        </div>
        <br/>
        <input type="submit" value="{control-i18n:localize('submit', $control:locale)}"/>
      </div>
    </form>
  </div>
};
(:
 : returns a form for setting the default svnurl
 :)
declare function control-widgets:get-default-svnurl() as element(div) {
  let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
      $username := $credentials[1]
  return
  <div class="adminmgmt">
    <h2>{control-i18n:localize('setdefaultsvnurl', $control:locale)}</h2>
    <form action="{$control:siteurl}/user/setdefaultsvnurl" method="POST" enctype="application/x-www-form-urlencoded" autocomplete="off">
      <div class="setdefaultsvnurl">
        <div class="form">
          <label for="defaultsvnurl" class="leftlabel">{concat(control-i18n:localize('defaultsvnurl', $control:locale),':')}</label>
          <input type="text" id="defaultsvnurl" name="defaultsvnurl" pattern=".+" autocomplete="new-password" value="{control-util:get-defaultsvnurl-from-user($username)}"/>
        </div>
        <br/>
        <input type="submit" value="{control-i18n:localize('submit', $control:locale)}"/>
      </div>
    </form>
  </div>
};
(:
 : returns a form for creating groups
 :)
declare function control-widgets:create-new-group( $svnurl as xs:string ) as element(div) {
  <div class="adminmgmt">
    <h2>{control-i18n:localize('creategroup', $control:locale)}</h2>
    <form action="{$control:siteurl}/group/creategroup?svnurl={$svnurl}" method="POST" enctype="application/x-www-form-urlencoded" autocomplete="off">
      <div class="createnewgroup">
        <div class="form">
          <label for="groupname" class="leftlabel">{concat(control-i18n:localize('groupname', $control:locale),':')}</label>
          <input type="text" id="groupname" name="newgroupname" autocomplete="new-password" pattern="[A-Za-z0-9]+" title="Nutzen Sie nur Buchstaben und Zahlen"/>
        </div>
        <div class="form">
          <label for="groupregex" class="leftlabel">{concat(control-i18n:localize('selectreporegex', $control:locale),':')}</label>
          <input type="text" id="newgroupregex" name="newgroupregex" autocomplete="new-password" pattern=".+" title="Regex darf nicht leer sein"/>
        </div>
        <br/>
        <input type="submit" value="{control-i18n:localize('submit', $control:locale)}"/>
      </div>
    </form>
  </div>
};
(:
 : returns a form for customizing groups
 :)
declare function control-widgets:customize-groups( $svnurl as xs:string ) as element(div) {
  <div class="adminmgmt">
    <h2>{control-i18n:localize('customizegroup', $control:locale)}</h2>
    <form action="{$control:siteurl}/group/setrepo?svnurl={$svnurl}" method="POST" enctype="application/x-www-form-urlencoded" autocomplete="off">
      <div class="managegroups">
        <div>
          <label for="groups" class="leftlabel">{concat(control-i18n:localize('selectgroup', $control:locale),':')}</label>
          <select name="groups" id="groupselect">
            {control-widgets:get-groups( $svnurl )}
          </select>
        </div>
        <div>
          <label for="grouprepo" class="leftlabel">{concat(control-i18n:localize('selectreporegex', $control:locale),':')}</label>
          <input type="text" id="grouprepo" name="grouprepo" autocomplete="new-password" pattern=".+" title="Regex darf nicht leer sein"/>
        </div>
        <br/>
        <input type="submit" value="{control-i18n:localize('submit', $control:locale)}"/>
      </div>
    </form>
  </div>
};
(:
 : returns a form for deleting groups
 :)
declare function control-widgets:remove-groups( $svnurl as xs:string ) as element(div) {
  <div class="adminmgmt">
    <h2>{control-i18n:localize('deletegroup', $control:locale)}</h2>
    <form action="{$control:siteurl}/group/delete?svnurl={$svnurl}" method="POST" enctype="application/x-www-form-urlencoded" autocomplete="off">
      <div class="managegroups">
        <div>
          <label for="groups" class="leftlabel">{concat(control-i18n:localize('selectgroup', $control:locale),':')}</label>
          <select name="groups" id="deletegroupselect">
            {control-widgets:get-groups( $svnurl )}
          </select>
        </div>
        <br/>
        <input type="submit" value="{control-i18n:localize('submit', $control:locale)}"/>
      </div>
    </form>
  </div>
};
(:
 : returns a form for deleting users
 :)
declare function control-widgets:remove-users( $svnurl as xs:string ) as element(div) {
  <div class="adminmgmt">
    <h2>{control-i18n:localize('deleteuser', $control:locale)}</h2>
    <form action="{$control:siteurl}/user/delete?svnurl={$svnurl}" method="POST" enctype="application/x-www-form-urlencoded" autocomplete="off">
      <div class="manageusers">
        <div>
          <label for="users" class="leftlabel">{concat(control-i18n:localize('selectuser', $control:locale),':')}</label>
          <select name="users" id="deleteuserselect">
            {control-widgets:get-users( $svnurl )}
          </select>
        </div>
        <br/>
        <input type="submit" value="{control-i18n:localize('submit', $control:locale)}"/>
      </div>
    </form>
  </div>
};
(:
 : returns the selection for users
 :)
declare function control-widgets:customize-users( $svnurl as xs:string ) as element(div) {
  <div class="adminmgmt">
    <h2>{control-i18n:localize('customizeuser', $control:locale)}</h2>
    <form action="{$control:siteurl}/user/setgroups?svnurl={$svnurl}" method="POST" enctype="application/x-www-form-urlencoded" autocomplete="off">
      <div class="manageuser">
        <div>
          <label for="users" class="leftlabel">{concat(control-i18n:localize('selectuser', $control:locale),':')}</label>
          <select name="users" id="userselect">
            {control-widgets:get-users( $svnurl )}
          </select>
        </div>
        <div>
          <label for="groups" class="leftlabel">{concat(control-i18n:localize('selectusergroup', $control:locale),':')}</label>
          <select name="groups" id="groups" multiple="true">
            {control-widgets:get-groups-and-admin( $svnurl )}
          </select>
        </div>
        <br/>
        <input type="submit" value="{control-i18n:localize('submit', $control:locale)}"/>
      </div>
    </form>
  </div>
};
(:
 : returns the selectionoptions for users
 :)
declare function control-widgets:get-users( $svnurl as xs:string ) as element(option)* {
  for $user in $control:access//control:users/control:user
  return
    <option value="{$user/control:name}">{$user/control:name}</option>
};
(:
 : returns the selectionoptions for groups (not admin)
 :)
declare function control-widgets:get-groups( $svnurl as xs:string ) as element(option)* {
  for $group in $control:access//control:groups/control:group
  where not($group/control:name = "admin")
  return
    <option value="{$group/control:name}">{$group/control:name}</option>
};
(:
 : returns the selectionoptions for groups
 :)
declare function control-widgets:get-groups-and-admin( $svnurl as xs:string ) as element(option)* {
  for $group in $control:access//control:groups/control:group
  return
    <option value="{$group/control:name}">{$group/control:name}</option>
};

(:
  returns the default search form. This function can be overridden in the configuration, in config/functions:
  <function role="search-form-widget" name="my-customization:search-form" arity="4"/>
:)
declare function control-widgets:search-input ( $svnurl as xs:string?, $control-dir as xs:string, 
                                                $auth as map(xs:string, xs:string), $params as map(*)? ) {
  <div class="form-wrapper">
    <form method="get" action="{$control-dir}/ftsearch" id="ftsearch-form">
      <div style="display:flex">
        <svg xmlns="http://www.w3.org/2000/svg" id="search-icon" style="position:relative; top:0.3em; display:inline-block" viewBox="0 0 24 24" width="20" height="20">
          <path d="M16.32 14.9l5.39 5.4a1 1 0 0 1-1.42 1.4l-5.38-5.38a8 8 0 1 1 1.41-1.41zM10 16a6 6 0 1 0 0-12 6 6 0 0 0 0 12z"/>
        </svg>
        <div class="autoComplete_wrapper" role="combobox" aria-owns="autoComplete_list" aria-haspopup="true" aria-expanded="false">
          <input id="search" type="text" name="term" autocomplete="off" size="26" autocapitalize="none" 
            aria-controls="autoComplete_list" aria-autocomplete="both" value="{$params?term}" />
          <ul id="autoComplete_list" role="listbox" class="autoComplete_list" hidden=""></ul>
          { for $lang in $control:config/control:ftindexes/control:ftindex/@lang return (
              <input id="lang_{$lang}" type="checkbox" name="lang" value="{$lang}">
              {if ($params?lang = $lang or empty($params?lang)) then attribute checked { 'true' } else ()}
              </input>,
              <label for="lang_{$lang}">{string($lang)}</label>
            )
          }
          
        </div>
      </div>
    </form>
  </div>
};
