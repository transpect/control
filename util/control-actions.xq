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
  %rest:path("/control/upload")
  %rest:form-param("file", "{$file}")
  %rest:form-param("svnurl", "{$svnurl}")
function control-actions:upload($file, $svnurl) {
  for $name    in map:keys($file)
  let $content := $file($name),
      $auth := control-util:parse-authorization(request:header("Authorization")),
      $username := map:get($auth,'username'),
      $path    := $control:tmp-path || file:dir-separator() || $name,
      $checkoutdir := ( $control:tmp-path || file:dir-separator() || random:uuid() || file:dir-separator() ),
      $commitpath := ( $checkoutdir || $name ),
      $revision := 'HEAD',
      $depth := '1'
  return (
    file:write-binary($path, $content),
    let $checkout :=svn:checkout($svnurl, $auth, $checkoutdir, $revision, $depth)
    return 
      if ($checkout/local-name() eq 'errors') then web:redirect('/control?svnurl=' || $svnurl || '?msg=' || encode-for-uri(control-i18n:localize('svn-checkout-error', $control:locale )) || '?msgtype=error' )
      else (
        let $toadd := not(file:exists($checkoutdir || file:dir-separator() || $name)),
            $add := if ($toadd) 
                    then (file:move($path, $checkoutdir), svn:add($checkoutdir, $auth, $name, false()))
                    else file:move($path, $checkoutdir)
        return 
          if ($add /local-name() eq 'errors') then web:redirect('/control?svnurl=' || $svnurl || '?msg=' || encode-for-uri(control-i18n:localize('svn-add-error', $control:locale )) || '?msgtype=error' )
          else (
            let $commit := svn:commit($auth, $checkoutdir, $name || ' added by ' || $username )
            return 
              if ($commit/local-name() eq 'errors') then web:redirect('/control?svnurl=' || $svnurl || '?msg=' || encode-for-uri(control-i18n:localize('svn-commit-error', $control:locale )) || '?msgtype=error' )
              else (
                file:delete($checkoutdir, true())(:,
                web:redirect('/control?svnurl=' || $svnurl ):)
              )
          )
      )
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
  let $temp    := $control:tmp-path || file:dir-separator() || random:uuid() || file:dir-separator(),
      $checkoutdir := $temp || $name,
      $zip-name := $name || '.zip',
      $zip-path := $temp || $zip-name
  return (admin:write-log($zip-path),
          if( svn:checkout($svnurl, $control:svnauth, $checkoutdir, 'HEAD', 'infinity')/local-name() ne 'errors' )
          then (file:write-binary($zip-path,archive:create-from($checkoutdir,())),
                web:response-header(map { 'media-type': web:content-type( $zip-path )},
                                    map { 'Content-Disposition': concat('attachement;filename=', $zip-name)}
                                   ),
                admin:write-log(concat('create-from: ',$checkoutdir, " ", $zip-path)),
                file:read-binary($zip-path),
                file:delete($temp, true())
               )
          else web:redirect($control:siteurl || '?svnurl=' || $svnurl || '?msg=' || encode-for-uri(control-i18n:localize('svn-checkout-error', $control:locale )) || '&amp;msgtype=error' )
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
  let $temp    := $control:tmp-path || file:dir-separator()  || random:uuid() || file:dir-separator(),
      $checkoutdir := $temp || 'file'
  return (
          if( svn:checkout($svnurl, $control:svnauth, $checkoutdir, 'HEAD', 'infinity')/local-name() ne 'errors' )
          then (web:response-header(map { 'media-type': web:content-type( $checkoutdir  || file:dir-separator() || $file )},
                                    map { 'Content-Disposition': concat('attachement; filename=', $file)}
                                   ),
                 file:read-binary($checkoutdir  || file:dir-separator() || $file),
                 file:delete($temp, true())
                )
          else web:redirect($control:siteurl || '?svnurl=' || $svnurl || '?msgtype=error' )
         )
};

(:
 : download conversion result file
 :)
declare
  %rest:path("/control/download-conversion-result")
  %rest:query-param("result_file", "{$result_file}")
  %rest:query-param("svnurl", "{$svnurl}")
  %rest:query-param("file", "{$file}")
  %rest:query-param("type", "{$type}")
function control-actions:download-result-file( $result_file as xs:string,$svnurl as xs:string, $type as xs:string, $file as xs:string ) {
  let $temp    := $control:tmp-path || file:dir-separator()  || random:uuid(),
      $checkoutdir := $temp,
      $create-dir := file:create-dir($checkoutdir),
      $converter := control-util:get-converter-for-type($type),
      $url := control-util:get-converter-function-url($converter/@name,'results')|| "?file=" || $result_file || "&amp;input_file=" || $file ||"&amp;type=" || $type,
      $get-file :=proc:execute('curl',('-u',$control:svnusername||':'||$control:svnpassword,$url,'--output',$checkoutdir||file:dir-separator()||$result_file)) 
  return (
          if( $get-file/*:code eq "0" )
          then (web:response-header(map { 'media-type': web:content-type( $checkoutdir  || file:dir-separator() || $result_file )},
                                    map { 'Content-Disposition': concat('attachement; filename=', $result_file)}
                                   ),
                 file:read-binary($checkoutdir  || file:dir-separator() || $result_file)
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
  %rest:query-param("file", "{$file}")
  %output:method('html')
function control-actions:delete( $svnurl as xs:string, $file as xs:string ) {
let 
    $auth := control-util:parse-authorization(request:header("Authorization")),
    $resu as element() := svn:delete(control-util:get-canonical-path($svnurl), $control:svnauth, $file, true(), 'deleted via control')
return if ($resu[descendant::*:param[@name = 'delete']])
       then web:redirect($control:siteurl || '?svnurl=' || $svnurl)
       else web:redirect($control:siteurl || '?svnurl=' || $svnurl || '?msg=' || encode-for-uri(control-i18n:localize('deletion-error', $control:locale )) || '?msgtype=error' )
};

(:
 : renames a file
 :)
declare
  %rest:POST
  %rest:path("/control/rename") 
  %rest:form-param("svnurl", "{$svnurl}")
  %rest:form-param("file", "{$file}")
  %rest:form-param("target", "{$target}")
  %output:method('html')
function control-actions:rename( $svnurl as xs:string, $file as xs:string, $target as xs:string ) {
let $auth := control-util:parse-authorization(request:header("Authorization")),
    $resu := svn:move(control-util:get-canonical-path($svnurl), $auth, $file, $target, 'renamed via control' )
return web:redirect($control:siteurl || '?svnurl=' || $svnurl || '?msg=' || encode-for-uri($resu) || '?msgtype=info' )
};


(:
 : renames a external mount
 :)
declare
  %rest:POST
  %rest:path("/control/change-mountpoint") 
  %rest:form-param("svnurl", "{$svnurl}")
  %rest:form-param("url", "{$url}")
  %rest:form-param("name", "{$name}")
  %output:method('html')
function control-actions:change-mountpoint( $svnurl as xs:string, $url as xs:string, $name as xs:string ) {
let $auth := control-util:parse-authorization(request:header("Authorization")),
    $propget := svn:propget($svnurl, $control:svnauth, 'svn:externals', 'HEAD'),
    $temp    := $control:tmp-path || file:dir-separator() || random:uuid() || file:dir-separator(),
    $checkoutdir := $temp || 'Propset',
    $checkout := svn:checkout($svnurl, $control:svnauth, $checkoutdir, 'HEAD', 'immediates'),
    $parsed := element externals {control-util:parse-externals-property($propget)},
    $updated-externals :=  
       copy $e := $parsed
       modify (
         replace node $e/external[@url eq $url] with
           element external {attribute url {$url}, attribute mount {$name}}
       )
       return $e,
    $propvalue := control-util:parsed-external-to-string($updated-externals),
    $res := svn:propset($checkoutdir, $control:svnauth, 'svn:externals', xs:string($propvalue),'HEAD'),
    $resco := svn:commit($auth, $checkoutdir, 'updated externals prop'),
    $deldir := file:delete($temp, true())
return web:redirect($control:siteurl || '?svnurl=' || $svnurl || '?msg=' || encode-for-uri($resco) || '?msgtype=info' )
};

(:
 : removed a external mount
 :)
declare
  %rest:GET
  %rest:path("/control/external/remove") 
  %rest:query-param("svnurl", "{$svnurl}")
  %rest:query-param("mount", "{$mount}")
  %output:method('html')
function control-actions:remove-external( $svnurl as xs:string, $mount as xs:string ) {
let $auth := control-util:parse-authorization(request:header("Authorization")),
    $propget := svn:propget($svnurl, $control:svnauth, 'svn:externals', 'HEAD'),
    $temp    := $control:tmp-path || file:dir-separator()  || random:uuid() || file:dir-separator(),
    $checkoutdir := $temp || 'Propset',
    $checkout := svn:checkout($svnurl, $control:svnauth, $checkoutdir, 'HEAD', 'immediates'),
    $parsed := element externals {control-util:parse-externals-property($propget)},
    $updated-externals :=  
       copy $e := $parsed
       modify (
         delete node $e/external[@mount eq $mount] 
       )
       return $e,
    $propvalue := control-util:parsed-external-to-string($updated-externals),
    $res := svn:propset($checkoutdir, $control:svnauth, 'svn:externals', xs:string($propvalue),'HEAD'),
    $resco := svn:commit($auth, $checkoutdir, 'updated externals prop'),
    $deldir := file:delete($temp, true())
return web:redirect($control:siteurl || '?svnurl=' || $svnurl || '?msg=' || encode-for-uri($resco) || '?msgtype=info' )
};
