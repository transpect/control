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
    return (
            file:write-binary($path, $content),
            if( svn:checkout($svnurl, $control:svnusername, $control:svnpassword, $checkoutdir, 'HEAD')/local-name() ne 'errors' )
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
  let $temp    := file:temp-dir() || file:dir-separator()  || random:uuid() || file:dir-separator() 
  let $checkoutdir := $temp || $name
  let $zip-name := $name || '.zip' 
  let $zip-path := $temp || $zip-name 
  return (
          if( svn:checkout($svnurl, $control:svnusername, $control:svnpassword, $checkoutdir, 'HEAD')/local-name() ne 'errors' )
          then (zip:zip-file(
                         <file xmlns="http://expath.org/ns/zip" href="{$zip-path}">
                          {for $file in file:list($checkoutdir)[not(starts-with(., '.svn'))]
                           return <entry src="{$checkoutdir || file:dir-separator() || $file}"/>
                           }
                         </file>
                         ),
                         web:response-header(map { 'media-type': web:content-type( $zip-path )},
                                             map { 'content-disposition': concat('attachement;filename=', $zip-name)}
                                             )
                )
          else web:redirect('/control?svnurl=' || $svnurl || '?msg=' || encode-for-uri(control-i18n:localize('svn-checkout-error', $control:locale )) || '?msgtype=error' )
         )
};
declare
  %rest:path("/control/copy")
  %rest:query-param("svnurl", "{$svnurl}")
  %rest:query-param("file", "{$file}")
  %output:method('html')
function control-actions:copy( $svnurl as xs:string, $file as xs:string ) {
<html>
  <head>
    {control-widgets:get-html-head( )}
  </head>
  <body>
    {control-widgets:get-page-header(),
     if( normalize-space($control:action) and normalize-space($control:file) )
     then control-widgets:manage-actions( $svnurl, ($control:dest-svnurl, $svnurl)[1], $control:action, $control:file )
     else ()}
    <main>
      {control:get-message( $control:msg, $control:msgtype ),
       if(normalize-space( $svnurl ))
       then control-widgets:get-dir-list( $svnurl, $control:path || '/../' )
       else 'URL parameter empty!'}
    </main>
    {control-widgets:get-page-footer()}
  </body>
</html>
};