(:
 : transpect control 202202181307
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
declare variable $control:access          := doc('control.xml')/control:access;
declare variable $control:index           := doc('index.xml')/root;
declare variable $control:svnbasehierarchy:= "/data/svn/hierarchy";
declare variable $control:svnurlhierarchy := "http://127.0.0.1/content/hierarchy";
declare variable $control:svnbasewerke    := "/data/svn/werke";
declare variable $control:svnurlwerke     := "http://127.0.0.1/content/werke";
declare variable $control:repobase        := "/content/hierarchy";
declare variable $control:protocol        := if ($control:port = '443') then 'https' else 'http';
declare variable $control:siteurl         := $control:protocol || '://' || $control:host || ':' || $control:port || $control:path;
declare variable $control:svnusername     := xs:string(doc('config.xml')/control:config/control:svnusername);
declare variable $control:svnpassword     := xs:string(doc('config.xml')/control:config/control:svnpassword);
declare variable $control:svnurl          := (request:parameter('svnurl'), xs:string(doc('config.xml')/control:config/control:svnurl))[1];
declare variable $control:msg             := request:parameter('msg');
declare variable $control:msgtype         := request:parameter('msgtype');
declare variable $control:action          := request:parameter('action');
declare variable $control:file            := request:parameter('file');
declare variable $control:dest-svnurl     := request:parameter('dest-svnurl');
declare variable $control:svnauth         := "/etc/svn/default.authz";
declare variable $control:default-permission
                                          := "r";
declare variable $control:nl              := "
";

declare
%rest:path('/control')
%rest:query-param("svnurl", "{$svnurl}")
%rest:query-param("repopath", "{$repopath}")
%output:method('html')
%output:version('5.0')
function control:control($svnurl as xs:string?, $repopath as xs:string?) as element() {
  let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
       $username := $credentials[1],
       $auth := map{'username':$credentials[1],'cert-path':'', 'password': $credentials[2]}
  return control:main( $svnurl, $repopath ,$auth)
};

declare
%rest:path('/control/setposition')
%rest:query-param("svnurl", "{$svnurl}")
%rest:query-param("repopath", "{$repopath}")
%output:method('html')
%output:version('5.0')
function control:setposition($svnurl as xs:string?, $repopath as xs:string?) as element() {
  let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
       $username := $credentials[1],
       $auth := map{'username':$credentials[1],'cert-path':'', 'password': $credentials[2]},
       $session := session:set('svnurl',$svnurl),
       $session2 := session:set('repopath',$repopath)
       
  return web:redirect('/basex/control')
};

(:
 : this is where the "fun" starts...
 :)
declare function control:main( $svnurl as xs:string?, $repopath as xs:string?, $auth as map(*)) as element(html) {
  let $used-svnurl := control-util:get-current-svnurl(map:get($auth,'username'), $svnurl)
  return
  <html>
    <head>
      {control-widgets:get-html-head( )}
    </head>
    <body>
      {control-widgets:get-page-header( ),
       if( normalize-space($control:action) and normalize-space($control:file) )
       then control-widgets:manage-actions( $used-svnurl, ($control:dest-svnurl, $used-svnurl)[1], $control:action, $control:file )
       else ()}
      <main>
        {
         control:get-message( $control:msg, $control:msgtype ),
         if(normalize-space( $used-svnurl ))
         then control-widgets:get-dir-list( $used-svnurl, $repopath, $control:path, control-util:is-svn-repo($used-svnurl), $auth)
         else 'URL parameter empty!'}
      </main>
      {control-widgets:get-page-footer(),
       control-widgets:create-infobox()}
    </body>
  </html>
};
(:
 : Get SVN Log info for svnurl
 :)
declare
%rest:path('/control/getsvnlog')
%rest:query-param("svnurl", "{$svnurl}")
%rest:query-param("repopath", "{$repopath}")
%rest:query-param("file", "{$file}")
%output:method('html')
%output:version('5.0')
function control:get-svnlog($svnurl as xs:string?, $repopath as xs:string?, $file as xs:string?) as element(table) {
  let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
       $username := $credentials[1],
       $auth := map{'username':$credentials[1],'cert-path':'', 'password': $credentials[2]},
       $svnlog := svn:log( $svnurl || $repopath || '/' || $file,$auth,0,0,0)
  return 
    <table> 
      <thead>
        <th>Author</th>
        <th>Date</th>
        <th>Revision</th>
      </thead>
      <tbody>{
      for $le in $svnlog/*:logEntry
      return
         (<tr>
            <td>{xs:string($le/@author)}</td>
            <td>{xs:string($le/@date)}</td>
            <td>{xs:string($le/@revision)}</td>
          </tr>,
          <tr>
            <td colspan="3">
              <div class="table">
                <div class="table-row">
                  <div class="table-cell">Path</div>
                  <div class="table-cell">Type</div>
                </div>{
                for $changedPath in $le//*:changedPath
                let $path := xs:string($changedPath/@name),
                    $type := xs:string($changedPath/@type)
                return 
                  <div class="table-row">
                    <div class="table-cell">{$path}</div>
                    <div class="table-cell">{$type}</div>
                  </div>}
              </div>
            </td>
          </tr>)
      }
      </tbody>
    </table>
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
(:
 : User Management main page
 : For now contains only Reset Password
 :)
declare
%rest:path("/control/user")
%rest:query-param("svnurl", "{$svnurl}")
%output:method('html')
%output:version('5.0')
function control:usermgmt($svnurl as xs:string?) as element(html) {
let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
    $username := $credentials[1],
    $password := $credentials[2]
return
  <html>
    <head>
      {control-widgets:get-html-head()}
    </head>
    <body>
      {control-widgets:get-page-header( ),
       control-widgets:get-pw-change(),
       control-widgets:get-default-svnurl()}
    </body>
  </html>
};
(:
 : Configuration main page
 :)
declare
%rest:path("/control/config")
%rest:query-param("svnurl", "{$svnurl}")
%rest:query-param("repopath", "{$repopath}")
%output:method('html')
%output:version('5.0')
function control:configmgmt($svnurl as xs:string, $repopath as xs:string?) as element(html) {
let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
    $username := $credentials[1],
    $password := $credentials[2],
    $auth := map{'username':$credentials[1],'cert-path':'', 'password': $credentials[2]}
return
  <html>
    <head>
      {control-widgets:get-html-head()(:,
      control-util:create-path-index('/data/svn/hierarchy', '/', 'root', $auth, 'root', $svnurl || $repopath,''):)}
    </head>
    <body>
      {control-widgets:get-page-header( ),
       if (control-util:is-admin($username))
       then (control-widgets:create-new-user($svnurl),
             control-widgets:customize-users($svnurl),
             control-widgets:remove-users($svnurl),
             control-widgets:create-new-group($svnurl),
             control-widgets:customize-groups($svnurl),
             control-widgets:remove-groups($svnurl),
             control-widgets:rebuild-index($svnurl, $repopath, 'root'),
             <div>{'session-id: '||session:id()}</div>)
       else ''}
    </body>
  </html>
};
(:
 : get pw set result
 :)
declare
%rest:path("/control/user/setpw")
%rest:query-param("svnurl", "{$svnurl}")
%output:method('html')
%output:version('5.0')
function control:setpw($svnurl as xs:string) {

let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
    $username := $credentials[1],
    $password := $credentials[2], 
    $oldpw := request:parameter("oldpw"),
    $newpw := request:parameter("newpw"),
    $newpwre := request:parameter("newpwre"),

    (: checks if the user is logged in and provided the correct old password :)
    $iscorrectuser :=
      if ($password = $oldpw)
      then
        proc:execute( 'htpasswd', ('-vb', '/etc/svn/default.htpasswd', $username, $password))
      else
        element result { element error {"The provided old passwort is not correct."}, element code {1}},
    (: tries to set the new password and returns an error message if it fails :)
    $result :=
      if ($iscorrectuser/code = 0)
      then (
        if ($newpw = $newpwre)
        then
          (proc:execute('htpasswd', ('-b', '/etc/svn/default.htpasswd', $username, $newpw)))
        else
          (element result { element error {"The provided new passwords are not the same."}, element code {1}})
      )
      else ($iscorrectuser),
    $btntarget :=
      if ($result/code = 0)
      then
        ($control:siteurl || '?svnurl=' || $svnurl)
      else
        ($control:siteurl || '/user?svnurl=' || $svnurl),
    $btntext :=
      if ($result/code = 0)
      then
        ("OK")
      else
        ("Zurück")
return
  <html>
    <head>
      {control-widgets:get-html-head( )}
    </head>
    <body>
      {control-widgets:get-page-header( )}
      <div class="result">
        {$result/error}
        <br/>
         <a href="{$btntarget }">
          <input type="button" value="{$btntext}"/>
        </a>
      </div>
    </body>
  </html>
};
(:
 : get set defaultsvnurl result
 :)
declare
%rest:path("/control/user/setdefaultsvnurl")
%output:method('html')
%output:version('5.0')
function control:setdefaultsvnurl() {

let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
    $username := $credentials[1],
    $password := $credentials[2],
    
    $defaultsvnurl := request:parameter("defaultsvnurl"),
    
    $file := doc("control.xml"),
    
    $updated-access := $file update {delete node //control:rels/control:rel[control:user = $username][control:defaultsvnurl]}
                             update {insert node element rel {element defaultsvnurl {$defaultsvnurl},
                                                              element user {$username}} into .//control:rels},
    
    $result := if ($defaultsvnurl)
      then
       element result { element error {"Updated"}, element code{0}, element text{file:write("basex/webapp/control/control.xml",$updated-access)}}
      else
        element result { element error {"deafultsvnurl is empty."}, element code {1}},
        
    $btntarget :=
      if ($result/code = 0)
      then
        ($control:siteurl || '/user')
      else
        ($control:siteurl || '/user'),
    $btntext :=
      if ($result/code = 0)
      then
        ("OK")
      else
        ("Zurück"),
    $writetofile := control:writeauthtofile($updated-access)
return
  <html>
    <head>
      {control-widgets:get-html-head( )}
    </head>
    <body>
      {control-widgets:get-page-header( )}
      <div class="result">
        {$result/error}
        <br/>
         <a href="{$btntarget }">
          <input type="button" value="{$btntext}"/>
        </a>
      </div>
    </body>
  </html>
};
(:
 : set group result
 :)
declare
%rest:path("/control/user/setgroups")
%rest:query-param("svnurl", "{$svnurl}")
%output:method('html')
%output:version('5.0')
function control:setgroups($svnurl as xs:string) {

let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
    $username := $credentials[1],
    $password := $credentials[2], 
    
    $groups := request:parameter("groups"),
    $selected-user := request:parameter("users"),
    
    $file := doc("control.xml"),
    
    $added-rel := for $group in $groups 
                   return element rel {
                            element user {$selected-user},
                            element group {$group}
                          },
    $updated-access := $file update {delete node //control:rels//control:rel
                                          [control:group]
                                          [control:user = $selected-user]}
                                       update {insert nodes $added-rel into //control:rels},
    $result :=
      if (control-util:is-admin($username))
      then
       element result { element error {"Updated"}, element code{0}, element text {file:write("basex/webapp/control/control.xml",$updated-access)}}
      else
        element result { element error {"You are not an admin."}, element code {1}},
    $btntarget :=
      if ($result/code = 0)
      then
        ($control:siteurl || '?svnurl=' || $svnurl)
      else
        ($control:siteurl || '/user?svnurl=' || $svnurl),
    $btntext :=
      if ($result/code = 0)
      then
        ("OK")
      else
        ("Zurück"),
    $writetofile := control:writeauthtofile($updated-access)
return
  <html>
    <head>
      {control-widgets:get-html-head( )}
    </head>
    <body>
      {control-widgets:get-page-header( )}
      <div class="result">
        {$result/error}
        <br/>
         <a href="{$btntarget }">
          <input type="button" value="{$btntext}"/>
        </a>
      </div>
    </body>
  </html>
};

(:
 : delete group result
 :)
declare
%rest:path("/control/group/delete")
%rest:query-param("svnurl", "{$svnurl}")
%output:method('html')
%output:version('5.0')
function control:deletegroups($svnurl as xs:string) {

let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
    $username := $credentials[1],
    $password := $credentials[2], 
    
    $selected-group := request:parameter("groups"),
    
    $file := doc("control.xml"),
    
    $updated-access := $file update {delete node //control:rels/control:rel[control:user][control:group = $selected-group]}
                             update {delete node //control:rels/control:rel[control:repo][control:group = $selected-group]}
                             update {delete node //control:groups/control:group[control:name = $selected-group]},
    $result :=
      if (control-util:is-admin($username))
      then
       element result { element error {"Updated"}, element code{0}, element text{file:write("basex/webapp/control/control.xml",$updated-access)}}
      else
        element result { element error {"You are not an admin."}, element code {1}},
        
    $btntarget :=
      if ($result/code = 0)
      then
        ($control:siteurl || '?svnurl=' || $svnurl)
      else
        ($control:siteurl || '/user?svnurl=' || $svnurl),
    $btntext :=
      if ($result/code = 0)
      then
        ("OK")
      else
        ("Zurück"),
    $writetofile := control:writeauthtofile($updated-access)
return
  <html>
    <head>
      {control-widgets:get-html-head( )}
    </head>
    <body>
      {control-widgets:get-page-header( )}
      <div class="result">
        {$result/error}
        <br/>
         <a href="{$btntarget }">
          <input type="button" value="{$btntext}"/>
        </a>
      </div>
    </body>
  </html>
};
(:
 : set access result
 :)
declare
%rest:path("/control/group/setaccess")
%rest:query-param("svnurl", "{$svnurl}")
%rest:query-param("repopath", "{$repopath}")
%rest:query-param("filepath", "{$filepath}")
%output:method('html')
%output:version('5.0')
function control:setaccess($svnurl as xs:string, $repopath as xs:string?, $filepath as xs:string) {

let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
    $username := $credentials[1],
    $password := $credentials[2], 
    
    $selected-group := request:parameter("groups"),
    $selected-access := request:parameter("access"),
    
    $selected-repo := tokenize($svnurl,'/')[position() = 5],
    
    $selected-filepath := $filepath,
    
    $file := doc("control.xml"),
    $updated-access := $file update {delete node //control:rels/control:rel
                                      [control:repo = $selected-repo]
                                      [control:file = $selected-filepath]
                                      [control:group = $selected-group]}
                             update {insert node element rel {
                                      element group {$selected-group},
                                      element repo {$selected-repo},
                                      element file {$selected-filepath},
                                      element permission {$selected-access}} into .//control:rels},
    $result :=
      if (control-util:is-admin($username))
      then
       element result { element error {"Updated"}, element code{0}, element text{file:write("basex/webapp/control/control.xml",$updated-access)}}
      else
        element result { element error {"You are not an admin."}, element code {1}},
    $btntarget :=
      if ($result/code = 0)
      then
        ($control:siteurl || '/access?svnurl=' || $svnurl || '&amp;repopath=' || $repopath || '&amp;action=access' || '&amp;file=' || tokenize($filepath,'/')[last()] )
      else
        ($control:siteurl || '/user?svnurl=' || $svnurl),
    $btntext :=
      if ($result/code = 0)
      then
        ("OK")
      else
        ("Zurück"),
    $writetofile := control:writeauthtofile($updated-access)
return
  <html>
    <head>
      {control-widgets:get-html-head( )}
    </head>
    <body>
      {control-widgets:get-page-header( )}
      <div class="result">
        {$result/error}
        <br/>
         <a href="{$btntarget }">
          <input type="button" value="{$btntext}"/>
        </a>
      </div>
    </body>
  </html>
};

(:
 : rebuild index
 :)
declare
%rest:path("/control/config/rebuildindex")
%rest:query-param("svnurl", "{$svnurl}")
%rest:query-param("repopath", "{$repopath}")
%rest:query-param("name", "{$name}")
%output:method('html')
%output:version('5.0')
function control:rebuildindex($svnurl as xs:string, $repopath as xs:string?, $name as xs:string) {

let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
    $username := $credentials[1],
    $password := $credentials[2], 
    
    $selected-group := request:parameter("groups"),
    $selected-access := request:parameter("access"),
    
    $auth := map{'username':$credentials[1],'cert-path':'', 'password': $credentials[2]},
    $result :=
      if (control-util:is-admin($username))
      then
       element result { element error {"Index Rebuilt"}, element code{0}, element text{control-util:writeindextofile(control-util:create-path-index($control:svnbasehierarchy, '', $name, $auth, $name, '/data/svn/hierarchy',''))}}
      else
        element result { element error {"You are not an admin."}, element code {1}},
    $btntarget :=
      if ($result/code = 0)
      then
        ($control:siteurl || '/config?svnurl=' || $svnurl)
      else
        ($control:siteurl || '/config?svnurl=' || $svnurl),
    $btntext :=
      if ($result/code = 0)
      then
        ("OK")
      else
        ("Zurück")
return
  <html>
    <head>
      {control-widgets:get-html-head( )}
    </head>
    <body>
      {control-widgets:get-page-header( )}
      <div class="result">
        {$result/error}
        <br/>
         <a href="{$btntarget }">
          <input type="button" value="{$btntext}"/>
        </a>
      </div>
    </body>
  </html>
};

declare
%rest:path("/control/group/removepermission")
%rest:query-param("svnurl", "{$svnurl}")
%rest:query-param("repopath", "{$repopath}")
%rest:query-param("filepath", "{$filepath}")
%rest:query-param("group", "{$group}")
%output:method('html')
%output:version('5.0')
function control:removepermission($svnurl as xs:string, $repopath as xs:string?, $filepath as xs:string, $group as xs:string) {

let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
    $username := $credentials[1],
    $password := $credentials[2],
    
    $file := doc("control.xml"),
    $selected-repo := tokenize($svnurl,'/')[position() = 5],
    $selected-filepath := $filepath,
    $updated-access := $file update {delete node //control:rels/control:rel
                                      [control:repo = $selected-repo]
                                      [control:file = $selected-filepath]
                                      [control:group = $group]},
    $result :=
      if (control-util:is-admin($username))
      then
       element result { element error {"Updated"}, element code{0}, element text{file:write("basex/webapp/control/control.xml",$updated-access)}}
      else
        element result { element error {"You are not an admin."}, element code {1}},
    $btntarget :=
      if ($result/code = 0)
      then
        ($control:siteurl || '/access?svnurl=' || $svnurl || '&amp;repopath=' || $repopath || '&amp;action=access' || '&amp;file=' || tokenize($filepath,'/')[last()] )
      else
        ($control:siteurl || '/user?svnurl=' || $svnurl),
    $btntext :=
      if ($result/code = 0)
      then
        ("OK")
      else
        ("Zurück"),
    $writetofile := control:writeauthtofile($updated-access)
return
  <html>
    <head>
      {control-widgets:get-html-head( )}
    </head>
    <body>
      {control-widgets:get-page-header( )}
      <div class="result">
        {$result/error}
        <br/>
         <a href="{$btntarget }">
          <input type="button" value="{$btntext}"/>
        </a>
      </div>
    </body>
  </html>
};
(:
 : delete user result
 :)
declare
%rest:path("/control/user/delete")
%rest:query-param("svnurl", "{$svnurl}")
%output:method('html')
%output:version('5.0')
function control:deleteuser($svnurl as xs:string) {

let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
    $username := $credentials[1],
    $password := $credentials[2], 
    
    $selected-user := request:parameter("users"),
    
    $file := doc("control.xml"),
    
    $updated-access := $file update {delete node //control:rels/control:rel[control:group][control:user = $selected-user]}
                             update {delete node //control:users/control:user[control:name = $selected-user]},
    $result :=
      if (control-util:is-admin($username))
      then
       element result { element error {"Updated"}, element code{0}, element text{file:write("basex/webapp/control/control.xml",$updated-access)}}
      else
        element result { element error {"You are not an admin."}, element code {1}},
    $btntarget :=
      if ($result/code = 0)
      then
        ($control:siteurl || '?svnurl=' || $svnurl)
      else
        ($control:siteurl || '/user?svnurl=' || $svnurl),
    $btntext :=
      if ($result/code = 0)
      then
        ("OK")
      else
        ("Zurück"),
    $writetofile := control:writeauthtofile($updated-access)
return
  <html>
    <head>
      {control-widgets:get-html-head( )}
    </head>
    <body>
      {control-widgets:get-page-header( )}
      <div class="result">
        {$result/error}
        <br/>
         <a href="{$btntarget }">
          <input type="button" value="{$btntext}"/>
        </a>
      </div>
    </body>
  </html>
};
(:
 : create new user
 :)
declare function control:createuser-bg($newusername as xs:string, $newpassword as xs:string, $defaultsvnurl as xs:string?) {
  let $callres := proc:execute('htpasswd', ('-b', '/etc/svn/default.htpasswd', $newusername, $newpassword)),
      $fileupdate := file:write("basex/webapp/control/control.xml",
                     let $file := doc("control.xml")
                     return if (not($file//control:users/control:user[control:name = $newusername]))
                            then if ($defaultsvnurl)
                                 then $file update {insert node element user {element name {$newusername}} into .//*:users}
                                            update {insert node element rel  {element user {$newusername},
                                                                              element defaultsvnurl {$defaultsvnurl}} into .//*:rels}
                                 else $file update insert node element user {element name {$newusername}} into .//*:users
                            else $file
                      )
  return $callres
};
(:
 : create new user
 :)
declare
%rest:path("/control/user/createuser")
%rest:query-param("svnurl", "{$svnurl}")
%output:method('html')
%output:version('5.0')
function control:createuser($svnurl as xs:string) {
let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
    $username := $credentials[1],
    $password := $credentials[2],
    $newusername := request:parameter("newusername"),
    $newpassword := request:parameter("newpassword"),
    $defaultsvnurl := request:parameter("defaultsvnurl"),

    (: Checks if the user is an admin ~ :)
    $result :=
      if (control-util:is-admin($username))
      then
        control:createuser-bg($newusername, $newpassword, $defaultsvnurl)
      else
        element result { element error {"You are not an admin."}, element code {1}},
    $btntarget :=
      if ($result/code = 0)
      then
        ($control:siteurl || '?svnurl=' || $svnurl)
      else
        ($control:siteurl || '/user?svnurl=' || $svnurl),
    $btntext :=
      if ($result/code = 0)
      then
        ("OK")
      else
        ("Zurück")
return
  <html>
    <head>
      {control-widgets:get-html-head( )}
    </head>
    <body>
      {control-widgets:get-page-header( )}
      <div class="result">
        {$result/error}
        <br/>
         <a href="{$btntarget }">
          <input type="button" value="{$btntext}"/>
        </a>
      </div>
    </body>
  </html>
};
(:
 : create new group
 :)
declare function control:creategroup-bg($newgroupname as xs:string?,$newgroupreporegex as xs:string?) {
let $callres := element result { element error {"Group created."}, element code {0}},
    $fileupdate := file:write("basex/webapp/control/control.xml",
          let $file := doc("control.xml")
          return $file update {insert node element group {element name {$newgroupname}} into .//*:groups}
                       update {insert node element rel {element group {$newgroupname}, element repo {$newgroupreporegex}} into .//*:rels}
        )
return $callres
};
(:
 : create new group
 :)
declare
%rest:path("/control/group/creategroup")
%rest:query-param("svnurl", "{$svnurl}")
%output:method('html')
%output:version('5.0')
function control:creategroup($svnurl as xs:string) {
let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
    $username := $credentials[1],
    $password := $credentials[2],
    $newgroupname := request:parameter("newgroupname"),
    $newgroupreporegex := request:parameter("newgroupname"),

    (: Checks if the user is an admin ~ :)
    $result :=
      if (control-util:is-admin($username))
      then
        control:creategroup-bg(xs:string($newgroupname),xs:string($newgroupreporegex))
      else
        element result { element error {"You are not an admin."}, element code {1}},
    $btntarget :=
      if ($result/code = 0)
      then
        ($control:siteurl || '?svnurl=' || $svnurl)
      else
        ($control:siteurl || '/user?svnurl=' || $svnurl),
    $btntext :=
      if ($result/code = 0)
      then
        ("OK")
      else
        ("Zurück")
return
  <html>
    <head>
      {control-widgets:get-html-head( )}
    </head>
    <body>
      {control-widgets:get-page-header( )}
      <div class="result">
        {$result/error}
         <a href="{$btntarget }">
          <input type="button" value="{$btntext}"/>
        </a>
      </div>
    </body>
  </html>
};

(:
 : set reporegex result
 :)
declare
%rest:path("/control/group/setrepo")
%rest:query-param("svnurl", "{$svnurl}")
%output:method('html')
%output:version('5.0')
function control:setreporegex($svnurl as xs:string) {

let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
    $username := $credentials[1],
    $password := $credentials[2], 
    
    $reporegex := request:parameter("grouprepo"),
    $selected-group := request:parameter("groups"),
    
    $file := doc("control.xml"),
    
    $added-rel := element rel {
                    element group {$selected-group},
                    element repo {$reporegex}
                  },
    $updated-access := $file update {delete node //control:rels//control:rel
                                          [control:repo]
                                          [control:group = $selected-group]}
                             update {insert nodes $added-rel into //control:rels},
    
    $filedel := file:write("basex/webapp/control/control.xml",$updated-access),
    $result :=
      if (control-util:is-admin($username))
      then
       element result { element error {"Updated"}, element code{0}}
      else
        element result { element error {"You are not an admin."}, element code {1}},
    $btntarget :=
      if ($result/code = 0)
      then
        ($control:siteurl || '?svnurl=' || $svnurl)
      else
        ($control:siteurl || '/user?svnurl=' || $svnurl),
    $btntext :=
      if ($result/code = 0)
      then
        ("OK")
      else
        ("Zurück"),
    $writetofile := control:writeauthtofile($updated-access)
return
  <html>
    <head>
      {control-widgets:get-html-head( )}
    </head>
    <body>
      {control-widgets:get-page-header( )}
      <div class="result">
        {$result/error}
        <br/>
         <a href="{$btntarget }">
          <input type="button" value="{$btntext}"/>
        </a>
      </div>
    </body>
  </html>
};
(:
 : get groups for user
 :)
declare
%rest:path("/control/user/getgroups")
%rest:query-param("username", "{$username}")
%output:method('xml')
function control:getusergroups($username as xs:string) {
let $usergroups :=
      $control:access/control:rels/control:rel[control:user][control:group][control:user = $username]
return
<response>
  {$usergroups}
</response>
};
(:
 : get glob for group
 :)
declare
%rest:path("/control/group/getglob")
%rest:query-param("groupname", "{$groupname}")
%output:method('xml')
function control:getgrouprepoglob($groupname as xs:string) {
let $groupglob :=
      $control:access/control:rels/control:rel[control:group][control:repo][control:group = $groupname]
return
<response>
  {$groupglob}
</response>
};

declare 
function control:writeauthtofile($access) {
  file:write($control:svnauth,control:writetoauthz($access))
};

declare
function control:writetoauthz($access) {
  concat(control-util:writegroups($access),
    $control:nl,
    '[/]',
    $control:nl,
    '* = ',$control:default-permission,$control:nl,
    '@admin = rw',$control:nl,
    string-join(
      for $repo in file:list($control:svnbasewerke) (:repos:)
      return 
        let $repo-groups := 
          for $group in $access//control:groups/control:group (:groups:)
          let $permission := control-util:get-permission-for-group($group/control:name, replace($repo,'/',''), $access)
          where $access//control:rels/control:rel[control:user][control:group = $group] (: not empty groups:)
          return element permission {element group {$group/control:name},
                                     element permission {$permission}}
        return if ($repo-groups[permission != ''][permission != $control:default-permission])
               then
                  concat('[', replace($repo,'/',''),':/]',$control:nl,
                  string-join(
                    for $group in $repo-groups[permission != ''] (:groups:)
                    return
                      if ($group/permission != $control:default-permission)
                      then concat('@',$group/group,'=',$group/permission,$control:nl)
                  ),$control:nl)
    ),
    string-join(
      for $a in $access//control:rels/control:rel[control:repo][control:group][control:permission][control:file != '']
      let $selected-permission := if ($a/control:permission = 'none') then ''
                        else if ($a/control:permission = 'read') then 'r'
                        else if ($a/control:permission = 'write') then 'rw'
      return concat(
               '[',
               $a/control:repo,':/',
               $a/control:file,
               ']',
               $control:nl,
               concat('@',$a/control:group),' = ', $selected-permission,$control:nl
             )
    )
    )
};