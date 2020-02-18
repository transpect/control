(:
 : functions that evaluate form fields and queries
 : and redirect to the main function with web:redirect()
 : messages and their status are returned with $msg and $msgtype
 :)
module namespace control-rest = 'control-rest';
import module namespace svn = 'io.transpect.basex.extensions.subversion.XSvnApi';
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
  %rest:form-param("svnusername", "{$svnusername}")
  %rest:form-param("svnpassword", "{$svnpassword}")
  %rest:form-param("locale", "{$locale}")
function control-rest:create-dir($dirname as xs:string?, $svnurl as xs:string, $svnusername as xs:string, $svnpassword as xs:string, $locale as xs:string) {
  (: check if dir already exists :)
  if(normalize-space($dirname))
  then if(svn:info(concat($svnurl, '/', $dirname), $svnusername, $svnpassword)/local-name() ne 'errors')
       then web:redirect(concat('/control?url=', $svnurl, '?msgtype=warning?msg=', encode-for-uri(control-i18n:localize('dir-exists', $locale))))
       else for $i in svn:mkdir($svnurl, $svnusername, $svnpassword, $dirname, true(), 'control: create dir')
            return if($i/local-name() ne 'errors')
                   then web:redirect('/control?url=' || $svnurl)
                   else web:redirect(concat('/control?url=', $svnurl, '?msgtype=error?msg=',
                                            encode-for-uri(control-i18n:localize('cannot-create-dir', $locale))))
  else web:redirect('/control?url=' || $svnurl || '?msg=' || encode-for-uri(control-i18n:localize('empty-value', $locale)) || '?msgtype=warning' )
};
declare
  %rest:path("/control/new-file")
  %rest:query-param("svnurl", "{$svnurl}")
  %rest:query-param("svnusername", "{$svnusername}")
  %rest:query-param("svnpassword", "{$svnpassword}")
  %rest:query-param("locale", "{$locale}")
  %output:method('html')
function control-rest:new-file($svnurl as xs:string?, $svnusername as xs:string?, $svnpassword as xs:string?, $locale as xs:string?) {
  <html>
    <head>
    </head>
    <body>
      hrz    
      {$svnurl}<br/>
      {$svnusername}<br/>
    </body>
  </html>
};