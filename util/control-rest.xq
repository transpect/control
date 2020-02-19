(:
 : functions that evaluate form fields and queries
 : and redirect to the main function with web:redirect()
 : messages and their status are returned with $msg and $msgtype
 :)
module namespace control-rest = 'control-rest';
import module namespace svn = 'io.transpect.basex.extensions.subversion.XSvnApi';
import module namespace control = 'control' at '../control.xq';
import module namespace control-i18n = 'control-i18n' at 'control-i18n.xq';
import module namespace control-util = 'control-util' at 'control-util.xq';
(:
 : create dir
 :)
declare
  %rest:POST
  %rest:path("/control/create-dir")
  %rest:form-param("dirname", "{$dirname}")
  %rest:form-param("svnurl", "{$svnurl}")
function control-rest:create-dir( $dirname as xs:string?, $svnurl as xs:string ) {
  (: check if dir already exists :)
  if(normalize-space( $dirname ))
  then if(svn:info(concat( $svnurl, '/', $dirname ), $control:svnusername, $control:svnpassword )/local-name() ne 'errors')
       then web:redirect(concat( '/control?url=', 
                                 $svnurl, '?msgtype=warning?msg=', 
                                 encode-for-uri(control-i18n:localize('dir-exists', $control:locale )))
                                 )
       else for $i in svn:mkdir( $svnurl, $control:svnusername, $control:svnpassword, $dirname, true(), 'control: create dir')
            return if( $i/local-name() ne 'errors' )
                   then web:redirect('/control?url=' || $svnurl )
                   else web:redirect(concat('/control?url=', $svnurl, '?msgtype=error?msg=',
                                            encode-for-uri(control-i18n:localize('cannot-create-dir', $control:locale ))))
  else web:redirect('/control?url=' || $svnurl || '?msg=' || encode-for-uri(control-i18n:localize('empty-value', $control:locale )) || '?msgtype=warning' )
};
declare
  %rest:path("/control/new-file")
  %rest:query-param("svnurl", "{$svnurl}")
  %output:method('html')
function control-rest:new-file( $svnurl as xs:string ) {
  <html>
    <head>
    </head>
    <body>
      
      <form action="/upload" method="POST" enctype="multipart/form-data">
        <input type="file" name="files"  multiple="multiple"/>
        <input type="hidden" name="svnurl" value="{$svnurl}"/>
        <input type="submit"/>
</form>
      
    </body>
  </html>
};
(:
 : process uploaded file
 :)
declare
  %rest:POST
  %rest:path("/upload")
  %rest:form-param("files", "{$files}")
  %rest:form-param("svnurl", "{$svnurl}")
function control-rest:upload($files, $svnurl) {
  for $name    in map:keys($files)
  let $content := $files($name)
  let $path    := file:temp-dir() || $name
  return 
    let $checkoutdir := ( file:temp-dir() || random:uuid() || file:dir-separator() )
    let $commitpath := ( $checkoutdir || $name )
    return (
            file:write-binary($path, $content),
            if( svn:checkout($svnurl, $control:svnusername, $control:svnpassword, $checkoutdir, 'HEAD')/local-name() ne 'errors' )
            then (file:move($path, $checkoutdir), 
                  if(svn:add($checkoutdir, $control:svnusername, $control:svnpassword, $name, false()))
                  then if( svn:commit($control:svnusername, $control:svnpassword, $checkoutdir, $name || ' added by ' || $control:svnusername )/local-name() ne 'errors' )
                       then (file:delete($checkoutdir, true()),
                             web:redirect('/control?url=' || $svnurl )
                             )
                       else web:redirect('/control?url=' || $svnurl || '?msg=' || encode-for-uri(control-i18n:localize('svn-commit-error', $control:locale )) || '?msgtype=error' )
                  else web:redirect('/control?url=' || $svnurl || '?msg=' || encode-for-uri(control-i18n:localize('svn-add-error', $control:locale )) || '?msgtype=error' )                  
                  )
            else web:redirect('/control?url=' || $svnurl || '?msg=' || encode-for-uri(control-i18n:localize('svn-checkout-error', $control:locale )) || '?msgtype=error' )
            )
};
