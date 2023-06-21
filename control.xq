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
import module namespace control-backend = 'http://transpect.io/control-backend' at '../control-backend/control-backend.xqm';

declare variable $control:config          := doc('config.xml')/control:config;
declare variable $control:locale          := $control:config/control:locale;
declare variable $control:customization as xs:string := $control:config/control:customization;
declare variable $control:host            := $control:config/control:host;
declare variable $control:port            := $control:config/control:port;
declare variable $control:path            := $control:config/control:path;
declare variable $control:datadir         := $control:config/control:datadir;
declare variable $control:db              := $control:config/control:db;
declare variable $control:max-upload-size := $control:config/control:max-upload-size;
declare variable $control:default-svnurl  := $control:config/control:defaultsvnurl;
declare variable $control:repos           := $control:config/control:repos;
declare variable $control:mgmtfile        := 'control.xml';
declare variable $control:mgmtdoc         := doc('control.xml');
declare variable $control:access          := control-util:get-current-authz()//control:access;
declare variable $control:conversions     := control-util:get-current-authz()//control:conversions;
declare variable $control:indexfile       := 'index.xml';
declare variable $control:index           := doc($control:indexfile)/root;
declare variable $control:svnurlhierarchy := $control:config/control:svnurlhierarchy;
declare variable $control:svnbasewerke    := $control:config/control:svnbasewerke;
declare variable $control:repobase        := "/content/hierarchy";
declare variable $control:protocol        := if ($control:port = '443') then 'https' else 'http';
declare variable $control:siteurl         := $control:protocol || '://' || $control:host || ':' || $control:port || $control:path;
declare variable $control:svnusername     := xs:string($control:config/control:svnusername);
declare variable $control:svnpassword     := xs:string($control:config/control:svnpassword);
declare variable $control:htpasswd        := $control:config/control:htpasswd;
declare variable $control:svnauth         := map{'username':$control:svnusername,'cert-path':'', 'password': $control:svnpassword};        
declare variable $control:svnurl          := (request:parameter('svnurl'), xs:string(doc('config.xml')/control:config/control:svnurl))[1];
declare variable $control:msg             := request:parameter('msg');
declare variable $control:msgtype         := request:parameter('msgtype');
declare variable $control:action          := request:parameter('action');
declare variable $control:file            := request:parameter('file');
declare variable $control:dest-svnurl     := request:parameter('dest-svnurl');
declare variable $control:authtype        := $control:config/control:authtype;
declare variable $control:search          := xs:boolean($control:config/control:search);
declare variable $control:svnauthfile     := $control:config/control:authz-file;
declare variable $control:htpasswd-script := "basex/webapp/control/scripts/htpasswd-wrapper.sh"; 
declare variable $control:htpasswd-group  := $control:config/control:htpasswd-group;
declare variable $control:htpasswd-file   := $control:config/control:htpasswd-file;
declare variable $control:converters      := $control:config/control:converters;
declare variable $control:tmp-path         := $control:config/control:tmp-path;
declare variable $control:default-permission
                                          := "r";
declare variable $control:nl              := "
";
declare variable $control:admingroupname   := "controladmin";

declare
%rest:path('/control')
%rest:query-param("svnurl", "{$svnurl}")
%rest:form-param("svnurl", "{$form-svnurl}")
%output:method('html')
%output:version('5.0')
function control:control($svnurl as xs:string?, $form-svnurl as xs:string?) {
  let $auth := control-util:parse-authorization(request:header("Authorization")),
      $used-svnurl := ($svnurl, $form-svnurl)[1]
  return 
    if ($used-svnurl and control-util:get-canonical-path($used-svnurl) eq $used-svnurl) 
    then control:main( $used-svnurl ,$auth)
    else web:redirect($control:siteurl || '?svnurl=' || control-util:get-canonical-path(control-util:get-current-svnurl(map:get($auth,'username'), $used-svnurl)))
};


(:
 : this is where the "fun" starts...
 :)
declare function control:main( $svnurl as xs:string?, $auth as map(*)) as element(html) {
  let $used-svnurl := control-util:get-canonical-path(control-util:get-current-svnurl($auth?username, $svnurl)),
      $search-widget-function as function(xs:string?, xs:string, map(xs:string, xs:string), map(*)?, map(xs:string, item()*)? ) as item()* 
        := (control-util:function-lookup('search-form-widget'), control-widgets:search-input#5)[1]
  return
  <html>
    <head>
      {control-widgets:get-html-head($used-svnurl)}
    </head>
    <body>
      {control-widgets:get-page-header( ),
       if( normalize-space($control:action) and normalize-space($control:file) )
       then control-widgets:manage-actions( $used-svnurl, ($control:dest-svnurl, $used-svnurl)[1], $control:action, $control:file )
       else ()}
      <main>{
         control:get-message( $control:msg, $control:msgtype),
         if(normalize-space( $used-svnurl ))
         then control-widgets:get-dir-list( $used-svnurl, $control:path, control-util:is-local-repo($used-svnurl), $auth)
         else 'URL parameter empty!',
         if ($control:search) then $search-widget-function( $used-svnurl, $control:path, $auth, 
                                  map:merge(request:parameter-names() ! map:entry(., request:parameter(.))),
                                  () )
                              else ()
      }</main>
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
%rest:query-param("file", "{$file}")
%output:method('html')
%output:version('5.0')
function control:get-svnlog($svnurl as xs:string?, $file as xs:string?) as element() {
  let $auth := control-util:parse-authorization(request:header("Authorization")),
      $svnlog := if ($file) then svn:log( control-util:virtual-path-to-svnurl($svnurl || '/' || $file),$auth,0,0,0)
                            else svn:log( control-util:virtual-path-to-svnurl($svnurl),$auth,0,0,0),
      $monospace-width := 75
  return <pre class="monospace">
  {for $le in $svnlog/*:logEntry
                   return
                     (' Revision | Author    | Date                                         ', 
                     <br/>,
                     ' ' || control-util:pad-text($le/@revision,8) || 
                     ' | ' || control-util:pad-text($le/@author,9) || 
                     ' | ' || $le/@date, <br/>,
                     ' ' ,(for $str in control-util:split-string-at-length($le/@message,$monospace-width - 2)
                             return ('' || $str, <br/>)),
                          (for $file in $le//*:changedPath
                             return (<a href="{$control:siteurl || '?svnurl=' || $svnurl 
                                            || string-join(tokenize(xs:string($file/@name),'/')[not(matches(.,'\....+$'))],'/')}">
                                             {control-util:get-short-string(xs:string($file/@type || ' ' || $file/@name), $monospace-width)}
                                     </a>)),<br/>,
                     '--------------------------------',<br/>)
   }
  </pre>
};
(:
 : Get SVN info for svnurl
 :)
declare
%rest:path('/control/getsvninfo')
%rest:query-param("svnurl", "{$svnurl}")
%rest:query-param("file", "{$file}")
%output:method('html')
%output:version('5.0')
function control:get-svninfo($svnurl as xs:string?, $file as xs:string?) as element() {
  let $auth := control-util:parse-authorization(request:header("Authorization")),
      $svninfo := svn:info( control-util:get-canonical-path(control-util:virtual-path-to-svnurl($svnurl || '/' || $file)),$control:svnauth),
      $monospace-width := 75
  return 
  <pre class="monospace">
   {
      let $date := xs:string($svninfo/*:param[matches(@name, 'date')]/@value),
          $path := xs:string($svninfo/*:param[matches(@name, 'path')]/@value),
          $rev  := xs:string($svninfo/*:param[matches(@name, 'rev')]/@value),
          $author := xs:string($svninfo/*:param[matches(@name, 'author')]/@value),
          $root-url  := xs:string($svninfo/*:param[matches(@name, 'root-url')]/@value),
          $url  := xs:string($svninfo/*:param[matches(@name, '^url')]/@value)
      return 
        ('Path: ', $path,<br/>,
'URL: ', control-util:svnurl-to-link($url),<br/>,
'Root URL: ', control-util:svnurl-to-link($root-url),<br/>,
'Revision: ', $rev,<br/>,
'Author: ', $author,<br/>,
'Date: ', $date)
    }
  </pre>
};
(:
 : displays a message
:)
declare function control:get-message( $message as xs:string?, $messagetype as xs:string?) as element(div )?{
  if( $message )
  then
    <div id="message-wrapper" class="{$messagetype}">
      <div id="message">
        <p>{control-util:decode-uri( $message )}</p>
      </div>
      <div id="messagebtns">
        <a id="messagebtn" href="{control-util:get-url-without-msg()}">
          OK<img class="small-icon" src="{$control:path || '/static/icons/open-iconic/svg/check.svg'}" alt="ok"/>
        </a>
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
let $auth := control-util:parse-authorization(request:header("Authorization")),
    $username := map:get($auth,'username')
return
  <html>
    <head>
      {control-widgets:get-html-head($svnurl)}
    </head>
    <body>
      {control:get-message($control:msg, $control:msgtype),
       control-widgets:get-page-header( ),
       control-widgets:get-pw-change($svnurl),
       control-widgets:get-defaultsvnurl-change($svnurl, $username),
       control-widgets:create-btn($svnurl, 'back', true())}
    </body>
  </html>
};

(:
 : Configuration main page
 :)
declare
%rest:path("/control/config")
%rest:query-param("svnurl", "{$svnurl}")
%output:method('html')
%output:version('5.0')
function control:configmgmt($svnurl as xs:string) as element(html) {
let $auth := control-util:parse-authorization(request:header("Authorization")),
    $username := map:get($auth,'username')
return
  <html>
    <head>
      {control-widgets:get-html-head($svnurl)
       }
    </head>
    <body>
      {control:get-message($control:msg, $control:msgtype),
       control-widgets:get-page-header(),
       if (control-util:is-admin($username))
       then (<div id="adminmgmt-wrapper"> {
              control-widgets:get-pw-change($svnurl),
              control-widgets:get-defaultsvnurl-change($svnurl, $username),
              control-widgets:get-access-table($svnurl),
              control-widgets:create-new-user($svnurl),
              (:control-widgets:customize-users($svnurl),:)
              (:control-widgets:remove-users($svnurl),:)
              control-widgets:create-new-group($svnurl),
              (:control-widgets:customize-groups($svnurl),:)
              (:control-widgets:remove-groups($svnurl),:)
              control-widgets:rebuild-index($svnurl, 'root'),
              (:control-widgets:manage-all-conversions($svnurl),:)
              control-widgets:create-btn($svnurl, 'back', true())
             }</div>,
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

let $auth := control-util:parse-authorization(request:header("Authorization")),
    $username := map:get($auth, 'username'),
    $password := map:get($auth, 'password'),
    $oldpw := request:parameter("oldpw"),
    $newpw := request:parameter("newpw"),
    $newpwre := request:parameter("newpwre"),

    (: checks if the user is logged in and provided the correct old password :)
    $iscorrectuser :=
      if ($password = $oldpw)
      then
        proc:execute( $control:htpasswd-script, ($control:htpasswd-file, 'vb', $username, $password, $control:htpasswd-group)) (:verify:)
      else
        element result { element error {"The provided old passwort is not correct."}, element code {1}},
    (: tries to set the new password and returns an error message if it fails :)
    $result :=
      if ($iscorrectuser/code = 0)
      then (
        if ($newpw = $newpwre)
        then
          proc:execute( $control:htpasswd-script, ($control:htpasswd-file, 'b', $username, $newpw, $control:htpasswd-group)) (:set new pw:)
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
      {control-widgets:get-html-head($svnurl)}
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
declare function control:user-setdefaultsvnurl-bg($username as xs:string, $defaultsvnurl as xs:string+) {
  let $fileupdate := control:overwrite-authz-with-mgmt(control-util:update-user-defaultsvnurl-in-mgmt($username, $defaultsvnurl),'user-setdefaultsvnurl-bg')
  return ($fileupdate)
};
(:
 : get set defaultsvnurl result
 :)
declare
%rest:path("/control/user/setdefaultsvnurl")
%rest:query-param("svnurl", "{$svnurl}")
%output:method('html')
%output:version('5.0')
function control:setdefaultsvnurl($svnurl) {
let $auth := control-util:parse-authorization(request:header("Authorization")),
    $username := map:get($auth, 'username'),
    $defaultsvnurl := request:parameter("defaultsvnurl"),
    $result :=
      if (control-util:is-admin($username))
      then (element result {attribute msg {'user-updated'},
                            attribute msgtype {'info'}},
            control:user-setdefaultsvnurl-bg($username, $defaultsvnurl))
      else element result {attribute msg {'not-admin'},
                           attribute msgtype {'error'}}
return
  web:redirect(control-util:get-back-to-config($svnurl, $result))
};

declare function control:user-setgroups-bg($username as xs:string, $groups as xs:string+) {
  let $fileupdate := control:overwrite-authz-with-mgmt(control-util:update-user-groups-in-mgmt($username, $groups),'user-setgroups-bg')
  return ($fileupdate)
};
(:
 : set groups result
 :)
declare
%rest:path("/control/user/setgroups")
%rest:query-param("svnurl", "{$svnurl}")
%output:method('html')
%output:version('5.0')
function control:user-setgroups($svnurl as xs:string) {

let $auth := control-util:parse-authorization(request:header("Authorization")),
    $username := map:get($auth, 'username'),
    
    $groups := request:parameter("groups"),
    $selected-user := request:parameter("users"),
    
    $result :=
      if (control-util:is-admin($username))
      then (element result {attribute msg {'user-updated'},
                            attribute msgtype {'info'}},
            control:user-setgroups-bg($selected-user, $groups))
      else element result {attribute msg {'not-admin'},
                           attribute msgtype {'error'}}
return
  web:redirect(control-util:get-back-to-config($svnurl, $result))
};

(:
 : delete group 
 :)
declare function control:delete-group-bg($groupname as xs:string) {
  let $fileupdate := control:overwrite-authz-with-mgmt(control-util:delete-group-from-mgmt($groupname),'delete-group-bg')
  return ($fileupdate)
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
let $auth := control-util:parse-authorization(request:header("Authorization")),
    $username := map:get($auth, 'username'),
    $groupname := request:parameter("group"),
    $group := $control:access//*:groups/*:group[xs:string(@name) = $groupname],
    $errors :=
      (if (not(control-util:is-admin($username)))
       then control-util:get-error('not-admin'),
       
       if ( count(for $u in $group/*:user/xs:string(@name)
                  return 
                    if (exists($control:access//*:group//*:group[not(@name = $groupname)]/*:user[@name = $u/@name])) 
                    then ()
                    else <last/>) gt 0) (:group of user:) 
       then  control-util:get-error('error-last-group-of-user')
      ),
    $result :=
      if ($errors) then $errors[1]
      else (control-util:get-info('group-deleted'),
            control:delete-group-bg($groupname))
return
  web:redirect(control-util:get-back-to-config($svnurl, $result))
};
(:
 : set permissions 
 :)
declare function control:set-perm-bg($svnurl as xs:string, $file as xs:string, $perm as xs:string, $groupname as xs:string) {
  let $fileupdate := control:overwrite-authz-with-mgmt(control-util:set-permission-for-file-mgmt($svnurl, $file, $perm, $groupname),'set-perm-bg')
  return ($fileupdate)
};
(:
 : set access result
 :)
declare
%rest:path("/control/group/setpermissions")
%rest:query-param("svnurl", "{$svnurl}")
%rest:query-param("file", "{$file}")
%output:method('html')
%output:version('5.0')
function control:setperm($svnurl as xs:string, $file as xs:string) {
let $auth := control-util:parse-authorization(request:header("Authorization")),
    $username := map:get($auth, 'username'),
    $selected-group := request:parameter("groups"),
    $selected-permission := request:parameter("access"),
    
    $errors :=
      (if (not(control-util:is-admin($username)))
       then control-util:get-error('not-admin')
      ),
    $result :=
      if ($errors) then $errors[1]
      else (control-util:get-info('updated'),
              control:set-perm-bg($svnurl, $file, $selected-permission, $selected-group))
return
  web:redirect(control-util:get-back-to-access($svnurl, $file, $result))
};

(:
 : Conversion mgmt page
 :)
declare
%rest:path("/control/convert")
%rest:query-param("svnurl", "{$svnurl}")
%rest:query-param("file", "{$file}")
%rest:query-param("type", "{$type}")
%output:method('html')
%output:version('5.0')
function control:convert($svnurl as xs:string, $file as xs:string, $type as xs:string) as element(html) {
  <html>
    <head>
      {control-widgets:get-html-head($svnurl)}
    </head>
    <body>
      {control:get-message($control:msg, $control:msgtype),
       control-widgets:get-page-header(),
       control-widgets:manage-conversions($svnurl, $file, $type)}
    </body>
  </html>
};

(:
 : Conversion mgmt page
 :)
declare
%rest:path("/control/conversions")
%rest:query-param("svnurl", "{$svnurl}")
%output:method('html')
%output:version('5.0')
function control:conversions($svnurl as xs:string) as element(html) {
  <html>
    <head>
      {control-widgets:get-html-head($svnurl)}
    </head>
    <body>
      {control:get-message($control:msg, $control:msgtype),
       control-widgets:get-page-header(),
       control-widgets:manage-all-conversions($svnurl)}
    </body>
  </html>
};

(:
 : start conversion result
 :)
 declare function control:start-conversion-bg($started-conversion as element(*),$svnurl,$file,$type) {
  let $fileupdate := control:overwrite-authz-with-mgmt(control-util:add-conversion-to-mgmt($started-conversion,$svnurl,$file,$type),'start-conversion-bg')
  return ($fileupdate)
};
 
(:
 : start conversion result
 :)
declare
%rest:path("/control/convert/start")
%rest:query-param("svnurl", "{$svnurl}")
%rest:query-param("file", "{$file}")
%rest:query-param("type", "{$type}")
%output:method('html')
%output:version('5.0')
function control:startconversion($svnurl as xs:string, $file as xs:string, $type as xs:string) {
let $auth := control-util:parse-authorization(request:header("Authorization")),
    $username := map:get($auth, 'username'),
    $selected-group := request:parameter("groups"),
    $selected-repo := tokenize(svn:info($svnurl, $control:svnauth)/*:param[@name = 'root-url']/@value,'/')[last()],
    $selected-filepath := replace(
                                string-join(
                                  ($svnurl,$file)
                                  ,'/')
                                ,svn:info($svnurl, $control:svnauth)/*:param[@name = 'root-url']/@value ||'/',''),
    $started-conversion := control-util:start-new-conversion($svnurl, $file, $type),
    
     $errors :=
      (if (not(control-util:is-admin($username)))
       then control-util:get-error('not-admin')
      ),
    $result :=
      if ($errors) then $errors[1]
      else (control-util:get-info('started'),
            control:start-conversion-bg($started-conversion,$svnurl,$file,$type))
return
  web:redirect($control:siteurl || '/convert?svnurl='|| $svnurl || '&amp;file=' || $file || '&amp;type=' || $type || control-util:get-message-url($result/xs:string(@msg),$result/xs:string(@msgtype),false(), false()))
};

(:
 : rebuild index
 :)
declare
%rest:path("/control/config/rebuildindex")
%rest:form-param("svnurl", "{$form-svnurl}")
%rest:form-param("name", "{$form-name}")
%rest:query-param("svnurl", "{$svnurl}")
%rest:query-param("name", "{$name}")
%output:method('html')
%output:version('5.0')
function control:rebuildindex($svnurl as xs:string*, $name as xs:string*, $form-svnurl as xs:string*, $form-name as xs:string*) {
let $auth := control-util:parse-authorization(request:header("Authorization")),
    $username := map:get($auth, 'username'),
    $used-svnurl := ($form-svnurl, $svnurl)[1],
    $used-name := ($form-name, $name)[1],
    $result :=
      if (control-util:is-admin($username))
      then (element result {attribute msg {'index-build'},
                            attribute msgtype {'info'},
            control-util:create-path-index($control:svnurlhierarchy, $used-name, $used-name, $control:svnurlhierarchy,'')})
      else element result {attribute msg {'not-admin'},
                           attribute msgtype {'error'}}
return
  web:redirect(control-util:get-back-to-config($used-svnurl, $result))
};

(:
 : remove permission 
 :)
declare function control:remove-permission-bg($svnurl as xs:string, $file as xs:string, $groupname as xs:string) {
  let $fileupdate := control:overwrite-authz-with-mgmt(control-util:remove-permission-for-file-mgmt($svnurl, $file, $groupname),'set-perm-bg')
  return ($fileupdate)
};
declare
%rest:path("/control/group/removepermission")
%rest:query-param("svnurl", "{$svnurl}")
%rest:query-param("file", "{$file}")
%rest:query-param("group", "{$group}")
%output:method('html')
%output:version('5.0')
function control:removepermission($svnurl as xs:string, $file as xs:string, $group as xs:string) {

let $auth := control-util:parse-authorization(request:header("Authorization")),
    $username := map:get($auth, 'username'),
    
    $errors :=
      (if (not(control-util:is-admin($username)))
       then control-util:get-error('not-admin')
       ),
    $result :=
      if ($errors) then $errors[1]
      else (control-util:get-info('permission-updated'),
            control:remove-permission-bg($svnurl, $file, $group))
return
  web:redirect(control-util:get-back-to-access($svnurl, $file, $result))
};
declare
%rest:path("/control/convert/cancel")
%rest:query-param("svnurl", "{$svnurl}")
%rest:query-param("file", "{$file}")
%rest:query-param("type", "{$type}")
%output:method('html')
%output:version('5.0')
function control:cancelconversion($svnurl as xs:string, $file as xs:string, $type as xs:string) {
let $auth       := control-util:parse-authorization(request:header("Authorization")),
    $username   := map:get($auth, 'username'),
    $conversion := control-util:get-running-conversions($svnurl, $file, $type),
    $delete     := proc:execute('curl',('-u', $control:svnusername||':'||$control:svnpassword,control-util:get-converter-function-url(control-util:get-converter-for-type($type)/@name,'delete')||'?input_file='||$file||'&amp;type='||$type)),
    $delete_res := json:parse($delete/output),
    $mgmt := $control:mgmtdoc,
    $updated-access := $mgmt update {delete node //control:conversion[control:id = $conversion/control:id]},
    $result :=
      if (xs:string(control-util:or(($delete_res/*:status/text() = 'success',matches(xs:string($delete_res/*:error/text()),'Invalid request: No such file or directory'),matches(xs:string($delete_res/*:error/text()),'Invalid request: File not found')))))
      then (element result {attribute msg {'deleted'},
                            attribute msgtype {'info'}},
            file:write("basex/webapp/control/"||$control:mgmtfile, $updated-access))
      else element result {attribute msg {string-join($delete_res//text(),',')},
                           attribute msgtype {'error'}}
return
  web:redirect($control:siteurl || '/convert?svnurl='|| $svnurl || '&amp;file='|| $file|| '&amp;type='|| $type || control-util:get-message-url($result/@msg,$result/@msgtype,false(), false()))
};

(:
 : delete user 
 :)
declare function control:delete-user-bg($username as xs:string) {
  let $fileupdate := control:overwrite-authz-with-mgmt(control-util:delete-user-from-mgmt($username),'delete-user-bg')
  return ($fileupdate)
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
let $auth := control-util:parse-authorization(request:header("Authorization")),
    $username := map:get($auth, 'username'),
    $selected-user := request:parameter("user"),
    $errors :=
      (if (not(control-util:is-admin($username)))
       then control-util:get-error('not-admin'),
       
       if (control-util:get-current-authz()//*:groups/*:group[count(*:user[not(xs:string(@name) = $selected-user)]) = 0]) (:last user in group:) 
       then  control-util:get-error('error-last-user')
      ),
    $result :=
      if ($errors) then $errors[1]
        else (control-util:get-info('user-deleted'),
              control:delete-user-bg($selected-user))
return
  web:redirect(control-util:get-back-to-config($svnurl, $result))
};
(:
 : create new user
 :)
declare function control:create-user-bg($newusername as xs:string, $newpassword as xs:string, $defaultsvnurl as xs:string?, $groups as xs:string+) {
  let $callres := proc:execute('htpasswd', ('-b', $control:htpasswd, $newusername, $newpassword)), (:add to htpasswd:)
      $fileupdate := control:overwrite-authz-with-mgmt(control-util:add-user-to-mgmt($newusername, $defaultsvnurl, $groups),'create-user-bg')
  return ($callres,$fileupdate)
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
let $auth := control-util:parse-authorization(request:header("Authorization")),
    $username := map:get($auth, 'username'),
    $newusername := request:parameter("newusername"),
    $newpassword := request:parameter("newpassword"),
    $defaultsvnurl := request:parameter("defaultsvnurl"),
    $groups := request:parameter("newusergroups"),
    $errors :=
      (if (not(control-util:is-admin($username)))
       then control-util:get-error('not-admin'),
       
       if (control-util:get-current-authz()//*:groups/*:group/*:user[xs:string(@name) = $newusername]) (:user exists:) 
       then  control-util:get-error('user-exists')
      ),
    $result :=
      if ($errors) then $errors[1]
      else (control-util:get-info('user-created'),
            if (control:create-user-bg($newusername, $newpassword, $defaultsvnurl, $groups)) then () else ())
return
  web:redirect(control-util:get-back-to-config($svnurl, $result))
};
(:
 : create new group
 :)
declare function control:create-group-bg($newgroupname as xs:string?, $newgroupusers as xs:string*) {
let $callres := 
      if ($newgroupusers != ())
      then element result { element error {"Group created."}, element code {0}}
      else element result { element error {"Users for Group cannot be empty"}, element code {1}},
    $fileupdate := control:overwrite-authz-with-mgmt(control-util:add-group-to-mgmt($newgroupname,$newgroupusers),'create-group-bg')
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
let $auth := control-util:parse-authorization(request:header("Authorization")),
    $username := map:get($auth, 'username'),
    $newgroupname := request:parameter("newgroupname"),
    $newgroupusers := request:parameter("newgroupusers"),
    $errors :=
      (if (not(control-util:is-admin($username)))
       then control-util:get-error('not-admin')
      ),
   $result :=
      if ($errors) then $errors[1]
      else (control-util:get-info('group-created'),
            control:create-group-bg(xs:string($newgroupname),$newgroupusers))
return
  web:redirect(control-util:get-back-to-config($svnurl, $result))
};

declare function control:update-users-in-group-bg($groupname as xs:string?, $groupusers as xs:string+) {
let $fileupdate := control:overwrite-authz-with-mgmt(control-util:update-users-in-group-mgmt($groupname,$groupusers),'update-users-in-group-bg')
return $fileupdate
};

declare function control:add-user-to-group-bg($groupname as xs:string, $username as xs:string) {
let $fileupdate := control:overwrite-authz-with-mgmt(control-util:add-user-to-group-mgmt($groupname,$username),'add-user-to-group-bg')
return $fileupdate
};

declare function control:remove-user-from-group-bg($groupname as xs:string, $username as xs:string) {
let $fileupdate := control:overwrite-authz-with-mgmt(control-util:remove-user-from-group-mgmt($groupname,$username),'remove-user-from-group-bg')
return $fileupdate
};

(:
 : add group users result
 :)
declare
%rest:path("/control/group/addusers")
%rest:query-param("svnurl", "{$svnurl}")
%output:method('html')
%output:version('5.0')
function control:addusers($svnurl as xs:string) {

let $auth := control-util:parse-authorization(request:header("Authorization")),
    $username := map:get($auth, 'username'),
    $addedusers := request:parameter("customizegroupusers"),
    $selected-group := request:parameter("groups"),
    $file := $control:mgmtdoc,
    $result :=
      if (control-util:is-admin($username))
      then (element result {attribute msg {'user-updated'},
                            attribute msgtype {'info'}},
            control:update-users-in-group-bg($selected-group,$addedusers))
      else element result {attribute msg {'not-admin'},
                           attribute msgtype {'error'}}
return
  web:redirect(control-util:get-back-to-config($svnurl, $result))
};
(:
 : add user to group result
 :)
declare
%rest:path("/control/group/users/add")
%rest:query-param("svnurl", "{$svnurl}")
%output:method('html')
%output:version('5.0')
function control:adduser($svnurl as xs:string) {

let $auth := control-util:parse-authorization(request:header("Authorization")),
    $username := map:get($auth, 'username'),
    $addeduser := request:parameter("user"),
    $selected-group := request:parameter("group"),
    
    $errors :=
      (if (not(control-util:is-admin($username)))
       then control-util:get-error('not-admin')
      ),
    $result :=
      if ($errors) then $errors[1]
      else (control-util:get-info('updated'),
            control:add-user-to-group-bg($selected-group,$addeduser))
return
  web:redirect(control-util:get-back-to-config($svnurl, $result))
};
(:
 : remove user from group result
 :)
declare
%rest:path("/control/group/users/remove")
%rest:query-param("svnurl", "{$svnurl}")
%output:method('html')
%output:version('5.0')
function control:removeuser($svnurl as xs:string) {
let $auth := control-util:parse-authorization(request:header("Authorization")),
    $username := map:get($auth, 'username'),
    $removeduser := request:parameter("user"),
    $selected-group := request:parameter("group"),
    
    $errors :=
      (if (not(control-util:is-admin($username)))
       then control-util:get-error('not-admin')
      ),
    $result :=
      if ($errors) then $errors[1]
      else (control-util:get-info('updated'),
            control:remove-user-from-group-bg($selected-group,$removeduser))
return
  web:redirect(control-util:get-back-to-config($svnurl, $result))
};
(:
 : get groups for user
 :)
declare
%rest:path("/control/user/groups/get")
%rest:query-param("username", "{$username}")
%output:method('xml')
function control:getusergroups($username as xs:string) {
let $usergroups :=
      $control:access//control:groups/control:group[control:user[xs:string(@name) = $username]]
return
<response>
  {$usergroups}
</response>
};

(:
 : get users for group:)
declare
%rest:path("/control/group/users/get")
%rest:query-param("groupname", "{$groupname}")
%output:method('xml')
function control:getgroupusers($groupname as xs:string) {
let $usergroups :=
      $control:access//control:groups/control:group[xs:string(@name) = $groupname]/control:user
return
<response>
  {$usergroups}
</response>
};

declare function control:overwrite-authz-with-mgmt($access,$reason as xs:string) {
  (file:write("basex/webapp/control/"||$control:mgmtfile,$access),
   admin:write-log(concat('AUTH Updated: ', $reason),'AUTH'),
   control:write-authz-to-file(control:mgmttoauthz($access)))
};

declare function control:write-authz-to-file($authz as xs:string) {
  let $authz-backup := 
        let $backup-path := concat(file:parent(db:system()//webpath),'/authz-backup'),
           $backup-directory := file:create-dir($backup-path),
           $read-old-authz := file:read-text($control:svnauthfile),
           $timestamp := concat(current-date(),current-time()),
           $write-file := if ($read-old-authz) 
                          then file:write-text(string-join(($backup-path,concat($timestamp,'backup.authz')),file:dir-separator()),$read-old-authz)
        return $write-file,
      $write-file := file:write($control:svnauthfile,$authz)
  return ($authz-backup, $write-file)
};

declare function control:mgmttoauthz($access) {
  concat(control-util:writegroups($access),
    $control:nl,
    string-join(
      for $e in $access//self::*:access/*:entry
      return
      (concat(
        '[',
        $e/xs:string(@name),
        ']',$control:nl),
        for $g in $e/*:group
        let $perm := if ($g/text() = 'none') then ''
                        else if ($g/text() = 'read') then 'r'
                        else if ($g/text() = 'write') then 'rw'
                        else $g/text() 
        return 
            replace(
                concat('@',$g/xs:string(@name),' = ', $perm,$control:nl),'@_all','*')
      )
    ))
};


declare
%rest:path("/ctl/{$id}")
function control:forward-short-link($id){
  let $auth := control-util:parse-authorization(request:header("Authorization"))
  return web:redirect(control-util:get-short-target($id)/xs:string(@target))
};

declare
%rest:path("/control/testipopesti")
%rest:query-param("svnurl", "{$svnurl}")
%output:method('xml')
function control:testipopesti($svnurl as xs:string) {
<doc>
<e>{control-util:get-local-path($svnurl)}</e>
<e>{(db:attribute('INDEX', control-util:get-local-path($svnurl), 'svnpath'))[1]/../@virtual-path}</e>
<e>{(db:attribute('INDEX', control-util:get-local-path($svnurl), 'path'))[1]/../@mount-point}</e>
<e>{$svnurl ! control-util:get-virtual-path(.)}</e>
<e>{$svnurl ! control-util:get-local-path(.) ! (db:attribute('INDEX', ., 'svnpath'))[1]/../@virtual-path}</e>
</doc>
};

declare
%rest:path("/ctl/index")
%output:method('html')
function control:get-index() {
let $index := $control:index,
    $updated-index-pre := control-util:get-size($index,0),
    $updated-index := control-util:get-coord($updated-index-pre,0),
    $slices as map(*):= control-util:get-all-slices($updated-index),
    $compl-size := sum($updated-index/*/@size)
return 
  <html>
  <div class="hidden">{$updated-index}</div>
    <table>
      { for $counter in (0 to xs:integer($compl-size))
        let $slice := map:get($slices,$counter)
        return
          <tr>
          { for $e in $slice
            return 
              <td rowspan="{$e/xs:integer(@size)}">
                {xs:string($e/@name)}
                <div class="hidden">
                {$e}</div>
              </td>}
          </tr>
      }
    </table>
  </html>
};