(:
 : functions that evaluate form fields and queries
 : and redirect to the main function with web:redirect()
 : messages and their status are returned with $msg and $msgtype
 :)
module namespace control-actions        = 'http://transpect.io/control/util/control-actions';
import module namespace svn             = 'io.transpect.basex.extensions.subversion.XSvnApi';
import module namespace control         = 'http://transpect.io/control' at '../control.xq';
import module namespace control-i18n    = 'http://transpect.io/control/util/control-i18n' at 'control-i18n.xq';
import module namespace control-util    = 'http://transpect.io/control/util/control-util' at 'control-util.xq';
import module namespace control-widgets = 'http://transpect.io/control/util/control-widgets' at 'control-widgets.xq';
(:
 : receive and commit file
 :)
declare
  %rest:POST
  %rest:path("/upload")
  %rest:form-param("file", "{$file}")
  %rest:form-param("svnurl", "{$svnurl}")
function control-actions:upload($file, $svnurl) {
  for $name    in map:keys($file)
  let $content := $file($name)
  let $path    := file:temp-dir() || $name
  let $checkoutdir := ( file:temp-dir() || random:uuid() || file:dir-separator() )
  let $commitpath := ( $checkoutdir || $name )
  let $revision := 'HEAD'
  let $depth := 'empty'
    return (
            file:write-binary($path, $content),
            if( svn:checkout($svnurl, $control:svnusername, $control:svnpassword, $checkoutdir, $revision, $depth)/local-name() ne 'errors' )
            then (file:move($path, $checkoutdir), 
                  if(svn:add($checkoutdir, $control:svnusername, $control:svnpassword, $name, false()))
                  then if( svn:commit($control:svnusername, $control:svnpassword, $checkoutdir, $name || ' added by ' || $control:svnusername )/local-name() ne 'errors' )
                       then (file:delete($checkoutdir, true()),
                             web:redirect('/control?svnurl=' || $svnurl )
                             )
                       else web:redirect('/control?svnurl=' || $svnurl || '?msg=' || encode-for-uri(control-i18n:localize('svn-commit-error', $control:locale )) || '?msgtype=error' )
                  else web:redirect('/control?svnurl=' || $svnurl || '?msg=' || encode-for-uri(control-i18n:localize('svn-add-error', $control:locale )) || '?msgtype=error' )                  
                  )
            else web:redirect('/control?svnurl=' || $svnurl || '?msg=' || encode-for-uri(control-i18n:localize('svn-checkout-error', $control:locale )) || '?msgtype=error' )
           )
};
(:
 : download as zip
 :)
declare
  %rest:path("/control/download")
  %rest:query-param("svnurl", "{$svnurl}")
function control-actions:download-as-zip( $svnurl as xs:string ) {
  for $name    in tokenize($svnurl, '/')[last()]
  let $temp    := file:temp-dir() || file:dir-separator()  || random:uuid() || file:dir-separator(),
      $checkoutdir := $temp || $name,
      $zip-name := $name || '.zip',
      $zip-path := $temp || $zip-name
  return (
          if( svn:checkout($svnurl, $control:svnauth, $checkoutdir, 'HEAD', 'infinity')/local-name() ne 'errors' )
          then (zip:zip-file(
                         <file xmlns="http://expath.org/ns/zip" href="{$zip-path}">
                          {for $file in file:list($checkoutdir)[not(starts-with(., '.svn'))]
                           return <entry src="{$checkoutdir || file:dir-separator() || $file}"/>
                           }
                         </file>
                         ),
                         web:response-header(map { 'media-type': web:content-type( $zip-path )},
                                             map { 'Content-Disposition': concat('attachement;filename=', $zip-name)}
                                             )
                )
          else web:redirect($control:siteurl || '?svnurl=' || $svnurl || '?msg=' || encode-for-uri(control-i18n:localize('svn-checkout-error', $control:locale )) || '?msgtype=error' )
         )
};

(:
 : download single file
 :)
declare
  %rest:path("/control/download-file")
  %rest:query-param("svnurl", "{$svnurl}")
  %rest:query-param("file", "{$file}")
function control-actions:download-single-file( $svnurl as xs:string, $file as xs:string ) {
  let $temp    := file:temp-dir() || file:dir-separator()  || random:uuid() || file:dir-separator(),
      $checkoutdir := $temp || 'file'
  return (
          if( svn:checkout($svnurl, $control:svnauth, $checkoutdir, 'HEAD', 'infinity')/local-name() ne 'errors' )
          then (file:read-binary($checkoutdir  || file:dir-separator() || $file),
                web:response-header(map { 'media-type': web:content-type( $checkoutdir  || file:dir-separator() || $file )},
                                    map { 'Content-Disposition': concat('attachement; filename=', $file)}
                                   )
                )
          else web:redirect($control:siteurl || '?svnurl=' || $svnurl || '?msgtype=error' )
         )
};
(:
 : choose target path and copy file
 :)
declare
  %rest:path("/control/copy")
  %rest:query-param("svnurl", "{$svnurl}")
  %rest:query-param("repopath", "{$repopath}")
  %rest:query-param("file", "{$file}")
  %output:method('html')
function control-actions:copy( $svnurl as xs:string, $repopath as xs:string?, $file as xs:string ) {
  let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
      $username := $credentials[1],
      $auth := map{'username':$credentials[1],'cert-path':'', 'password': $credentials[2]}
  return
<html>
  <head>
    {control-widgets:get-html-head($svnurl)}
  </head>
  <body>
    {control-widgets:get-page-header(),
     if( normalize-space($control:action) and normalize-space($control:file) )
     then control-widgets:manage-actions( $svnurl, ($control:dest-svnurl, $svnurl)[1], $control:action, $control:file )
     else ()}
    <main>
      {control:get-message( $control:msg, $control:msgtype ),
       control-widgets:get-dir-list( $svnurl, $control:path || '/../',control-util:is-svn-repo($svnurl), $auth)}
    </main>
    {control-widgets:get-page-footer()}
  </body>
</html>
};
(:
 : choose access control for selected file
 :)
declare
  %rest:path("/control/access")
  %rest:query-param("svnurl", "{$svnurl}")
  %rest:query-param("file", "{$file}")
  %output:method('html')
function control-actions:access( $svnurl as xs:string, $file as xs:string) {
<html>
  <head>
    {control-widgets:get-html-head($svnurl)}
  </head>
  <body>
    {control-widgets:get-page-header()}
    <main>
      {control-widgets:file-access( $svnurl, $file )}
    </main>
    {control-widgets:get-page-footer()}
  </body>
</html>
};

(:
 : quietly deletes a file -> needs url http://localhost:9081/content/werke/01991/images/
 :)
declare
  %rest:path("/control/delete")
  %rest:query-param("svnurl", "{$svnurl}")
  %rest:query-param("repopath", "{$repopath}")
  %rest:query-param("file", "{$file}")
  %output:method('html')
function control-actions:delete( $svnurl as xs:string, $repopath as xs:string, $file as xs:string ) {
let 
    $auth := map {"username": $control:svnusername, 
                  'password': $control:svnpassword},
    $resu := svn:delete(concat('http://127.0.0.1/', control-util:create-download-link($svnurl, '')), $auth, $file, true(), 'deleted by me')
return <html>
<head>Deleted; Go Back In Browser and Reload</head>
<body>
</body></html>
};

declare
  %rest:path("/control/delete-not-working")
  %rest:query-param("svnurl", "{$svnurl}")
  %rest:query-param("repopath", "{$repopath}")
  %rest:query-param("file", "{$file}")
  %output:method('html')
function control-actions:delete-not-working( $svnurl as xs:string, $repopath as xs:string, $file as xs:string ) {
let 
    $auth := map {"username": xs:string(doc('../config.xml')/control:config/control:svnusername), 
                  'password': xs:string(doc('../config.xml')/control:config/control:svnpassword)},
    $resu := svn:delete(concat('http://127.0.0.1/', control-util:create-download-link($svnurl, '')), $auth, $file, true(), 'deleted by me')
return <html>
<head>{control-widgets:get-html-head($svnurl)}</head>
<body>
</body></html>
};

(:
 : renames a file
 :)
declare
  %rest:POST
  %rest:path("/control/rename") 
  %rest:form-param("svnurl", "{$svnurl}")
  %rest:form-param("repopath", "{$repopath}")
  %rest:form-param("file", "{$file}")
  %rest:form-param("target", "{$target}")
  %output:method('html')
function control-actions:rename( $svnurl as xs:string, $repopath as xs:string?, $file as xs:string, $target as xs:string ) {
let $auth := map {"username": xs:string(doc('../config.xml')/control:config/control:svnusername), 
                  'password': xs:string(doc('../config.xml')/control:config/control:svnpassword)},
    $resu := svn:move(concat('http://127.0.0.1/', control-util:create-download-link($svnurl, '')), $auth, $file, $target, 'renamed by' || $control:svnusername )
return <html>
<head>Renamed; Go Back In Browser</head>
<body>
</body></html>
};
