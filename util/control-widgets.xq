module namespace control-widgets = 'control-widgets';
import module namespace svn = 'io.transpect.basex.extensions.subversion.XSvnApi';
import module namespace control = 'control' at '../control.xq';
import module namespace control-i18n = 'control-i18n' at 'control-i18n.xq';
import module namespace control-util = 'control-util' at 'control-util.xq';
(: 
 : gets the html head
 :)
declare function control-widgets:get-html-head( $control-dir as xs:string ) as element()+ {
  <meta charset="utf-8"></meta>,
  <title>control</title>,
  <script src="{$control-dir || '/static/js/control.js'}" type="text/javascript"></script>,
  <link rel="stylesheet" type="text/css" href="{$control-dir || '/static/style.css'}"></link>
};
declare function control-widgets:get-page-footer( ) as element(footer) {
  <footer>
    
  </footer>
};
(:
 : get the fancy page head
 :)
declare function control-widgets:get-page-header( $control-dir as xs:string ) as element(header) {
  <header>
    <div class="header-wrapper">
      <div id="logo">
        <img src="{$control-dir || '/static/icons/transpect.svg'}" alt="transpect logo"/>
      </div>
      <h1><span class="thin">transpect</span>control</h1>
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
  <div class="home">
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
declare function control-widgets:get-file-action-dropdown( $svnurl as xs:string, $file as xs:string ) as element(details){
  <details class="file action dropdown">
    <summary class="btn">
      {control-i18n:localize('actions', $control:locale)}<span class="spacer"/>▼
    </summary>
    <div class="dropdown-wrapper">
	    <ul>
	      <li>
	       <a class="btn" href="{$control:dir || '/rename?svnurl=' || $svnurl || '&amp;action=rename&amp;file=' || $file }">{control-i18n:localize('rename', $control:locale)}</a>
	      </li>
	      <li>
	        <a class="btn" href="{$control:dir || '/copy?svnurl=' || $svnurl || '&amp;action=copy&amp;file=' || $file }">{control-i18n:localize('copy', $control:locale)}</a>
	      </li>
    		<li>
    		  <a class="btn" href="{$control:dir || '/move?svnurl=' || $svnurl || '&amp;action=move&amp;file=' || $file }">{control-i18n:localize('move', $control:locale)}</a>
    		</li>
    		<li>
    		  <a class="btn" href="{$control:dir || '/delete?svnurl=' || $svnurl || '&amp;action=delete&amp;file=' || $file }">{control-i18n:localize('delete', $control:locale)}</a>
    		</li>
      </ul>
	  </div>
  </details>
};
(:
 : use request parameter and perform file action
 :)
declare function control-widgets:manage-file-actions( $svnurl as xs:string, $alt-svnurl as xs:string?, $action as xs:string, $file as xs:string ) as element(div)+ {
  <div class="transparent-bg"></div>,
  <div class="transparent-fg">
    <div class="window-fg">
      { control-widgets:choose-directory( $svnurl, $alt-svnurl, $action, $file ) }
    </div>
  </div>
};

declare function control-widgets:choose-directory( $svnurl as xs:string, $alt-svnurl as xs:string?, $action as xs:string, $file as xs:string ) as element(div) {
  <div class="choose-directory">
    <h2>Choose directory</h2>
    <div class="directory-list table">
      <div class="table-body">
      { for $files in svn:list(control-util:path-parent-dir( $svnurl ), $control:svnusername, $control:svnpassword, false())[local-name() ne 'errors']
        return 
            <div class="table-row directory-entry {local-name( $files )}">
              <div class="icon table-cell"/>
              <div class="name parentdir table-cell">
                <a href="{$control:siteurl || '?svnurl=' || $svnurl || '&amp;alt-svnurl=' || control-util:path-parent-dir( $alt-svnurl ) || '&amp;action=' || $action || '&amp;file=' || $file }">..</a></div>
              </div>,
              for $files in svn:list( $alt-svnurl, $control:svnusername, $control:svnpassword, false())/*
              order by lower-case( $files/@name )
              order by $files/local-name()
              let $href := $control:siteurl || '?svnurl=' || $svnurl || '&amp;alt-svnurl=' || $alt-svnurl || '/' || $files/@name || '&amp;action=' || $action || '&amp;file=' || $file
              return
                if( $files/local-name() eq 'directory' )
                then 
                  <div class="table-row directory-entry {local-name( $files )}">
                    <div class="table-cell icon">
                      <a href="{$href}">
                        <img src="{(concat( $control:dir,
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
                      <a href="{$href}">{xs:string( $files/@name )}</a></div>
                    <div class="action table-cell">{control-widgets:get-select-directory-button( $svnurl, 'svn-copy', $file, $files/@name)}</div>
                  </div>
              else ()
      }
      </div>
    </div>
  </div>
};
declare function control-widgets:get-select-directory-button( $svnurl as xs:string, $action as xs:string, $source as xs:string, $target as xs:string) as element(div){
  <div class="home">
    <a href="{ $control:dir || '/../?svnurl=' || $svnurl || '&amp;action=' || $action || '&amp;source=' || $source || '&amp;target=' || $target }">
      <button class="back action btn">
        <img class="small-icon" src="{$control:dir || '/static/icons/open-iconic/svg/check.svg'}" alt="back"/>
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
        {control-widgets:list-dir-entries( $svnurl, $control-dir, (), false(), () )}
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
                                           $filename-filter-regex as xs:string?, 
                                           $dirs-only as xs:boolean,
                                           $add-query-params as xs:string?) as element(div )* {
  control-widgets:get-dir-parent( $svnurl, $control-dir ),
  for $files in svn:list( $svnurl, $control:svnusername, $control:svnpassword, false())/*
  order by lower-case( $files/@name )
  order by $files/local-name()
  let $href := $control:siteurl || '?svnurl=' || $svnurl || '/' || $files/@name || $add-query-params
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
                                       else tokenize( $files/@name, '\.')[last()]
                                       )
                      )
               )}" alt="" class="file-icon"/>
        </a>
      </div>
      <div class="name table-cell">
        <a href="{$href}">{xs:string( $files/@name )}</a></div>
      <div class="author table-cell">{xs:string( $files/@author )}</div>
      <div class="date table-cell">{xs:string( $files/@date )}</div>
      <div class="revision table-cell">{xs:string( $files/@revision )}</div>
      <div class="size table-cell">{$files/@size[$files/local-name() eq 'file']/concat(., '&#x202f;KB')}</div>
      <div class="action table-cell">{control-widgets:get-file-action-dropdown( $svnurl, $files/@name )}</div>
    </div> 
    else()
};
(:
 : provides a row in the html direcory listing 
 : with the link to the parent directory
:)
declare function control-widgets:get-dir-parent( $svnurl as xs:string, $control-dir as xs:string ) as element(div )? {
  for $files in svn:list(control-util:path-parent-dir( $svnurl ), $control:svnusername, $control:svnpassword, false())[local-name() ne 'errors']
  return 
    <div class="table-row directory-entry {local-name( $files )}">
      <div class="icon table-cell"/>
      <div class="name parentdir table-cell">
        <a href="{concat(
                         $control-dir,
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
