(:
 : functions that evaluate form fields and queries
 : and redirect to the main function with web:redirect()
 : messages and their status are returned with $msg and $msgtype
 :)
module namespace control-rest           = 'control-rest';
import module namespace svn             = 'io.transpect.basex.extensions.subversion.XSvnApi';
import module namespace control         = 'control' at '../control.xq';
import module namespace control-i18n    = 'control-i18n' at 'control-i18n.xq';
import module namespace control-util    = 'control-util' at 'control-util.xq';
import module namespace control-widgets = 'control-widgets' at 'control-widgets.xq';
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
       then web:redirect(concat( '/control?svnurl=', 
                                 $svnurl, '?msgtype=warning?msg=', 
                                 encode-for-uri(control-i18n:localize('dir-exists', $control:locale )))
                                 )
       else for $i in svn:mkdir( $svnurl, $control:svnusername, $control:svnpassword, $dirname, true(), 'control: create dir')
            return if( $i/local-name() ne 'errors' )
                   then web:redirect('/control?svnurl=' || $svnurl )
                   else web:redirect(concat('/control?svnurl=', $svnurl, '?msgtype=error?msg=',
                                            encode-for-uri(control-i18n:localize('cannot-create-dir', $control:locale ))))
  else web:redirect('/control?svnurl=' || $svnurl || '?msg=' || encode-for-uri(control-i18n:localize('empty-value', $control:locale )) || '?msgtype=warning' )
};
declare
  %rest:path("/control/new-file")
  %rest:query-param("svnurl", "{$svnurl}")
  %output:method('html')
function control-rest:new-file( $svnurl as xs:string ) {
  <html>
    <head>
      {control-widgets:get-html-head( $control:dir || '/../')}
        <script src="{$control:dir || '/../static/lib/dropzone/dropzone.min.js'}" type="text/javascript"></script>
        <link rel="stylesheet" href="{$control:dir || '/../static/lib/dropzone/dropzone.min.css'}"></link>
    </head>
    <body>
      {control-widgets:get-page-header( $control:dir || '/../' )}
      <main>
        <div class="directory-list-wrapper">
          <div class="svnurl">
            {control-widgets:get-svnhome-button( $svnurl, $control:dir || '/..' ),
             control-widgets:get-back-to-svndir-button($svnurl, $control:dir || '/..' )}
          <div class="path">{tokenize( $svnurl, '/')[last()]}</div>
            {control-widgets:create-dir-form( $svnurl, $control:dir || '/../' )}
          </div>
        </div>
        <form action="/upload"
              class="dropzone"
              id="dropzone" method="post" enctype="multipart/form-data">
          <div class="fallback">
            <input name="file" type="file" multiple="multiple">Or select file</input>
            <input type="hidden" name="svnurl" value="{$svnurl}"/>
          </div>
        </form>        
      </main>
      {control-widgets:get-page-footer()}
      <!--<script src="{$control:dir || '/../static/js/control.js'}" type="text/javascript"></script>-->
        <script>
          Dropzone.options.dropzone = 
            {{ maxFilesize: {$control:max-upload-size}, // MB
               dictDefaultMessage:"{control-i18n:localize('drop-files', $control:locale )}",
               params:{{svnurl:"{$svnurl}"}}
            }};
      </script>
    </body>
  </html>
};
(:
 : process uploaded file
 :)
declare
  %rest:POST
  %rest:path("/upload")
  %rest:form-param("file", "{$file}")
  %rest:form-param("svnurl", "{$svnurl}")
function control-rest:upload($file, $svnurl) {
  for $name    in map:keys($file)
  let $content := $file($name)
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
function control-rest:download-as-zip( $svnurl as xs:string ) {
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
(:
 : copy files
 :)
declare
  %rest:path("/control/copy")
  %rest:query-param("svnurl", "{$svnurl}")
  %rest:query-param("file", "{$file}")
  %output:method('html')
function control-rest:copy( $svnurl as xs:string, $file as xs:string ) {
<html>
  <head>
    {control-widgets:get-html-head( $control:dir || '/../')}
  </head>
  <body>
    {control-widgets:get-page-header( $control:dir || '/../' ),
     if( normalize-space($control:action) and normalize-space($control:file) )
     then control-widgets:manage-file-actions( $svnurl, ($control:alt-svnurl, $svnurl)[1], $control:action, $control:file )
     else ()}
    <main>
      {control:get-message( $control:msg, $control:msgtype ),
       if(normalize-space( $svnurl ))
       then control-widgets:get-dir-list( $svnurl, $control:dir || '/../' )
       else 'URL parameter empty!'}
    </main>
    {control-widgets:get-page-footer()}
  </body>
</html>
};