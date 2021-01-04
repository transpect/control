(:
 : functions that evaluate form fields and queries
 : and redirect to the main function with web:redirect()
 : messages and their status are returned with $msg and $msgtype
 :)
module namespace control-api            = 'http://transpect.io/control/util/control-api';
declare namespace c                     = 'http://www.w3.org/ns/xproc-step';
import module namespace svn             = 'io.transpect.basex.extensions.subversion.XSvnApi';
import module namespace control         = 'http://transpect.io/control' at '../control.xq';
import module namespace control-i18n    = 'http://transpect.io/control/util/control-i18n' at 'control-i18n.xq';
import module namespace control-util    = 'http://transpect.io/control/util/control-util' at 'control-util.xq';
import module namespace control-widgets = 'http://transpect.io/control/util/control-widgets' at 'control-widgets.xq';
(:
 : control-api:list()
 :
 : return svn:list as xml
 :)
declare
  %rest:GET
  %rest:path("/control/api/list")
  %rest:query-param("svnurl", "{$svnurl}")
  %rest:query-param("svnusername", "{$svnusername}")
  %rest:query-param("svnpassword", "{$svnpassword}")
  %output:method('xml')
function control-api:list( $svnurl as xs:string?, $svnusername as xs:string?, $svnpassword as xs:string? ) as element(c:files) {
  let $checkoutdir := control-util:get-checkout-dir($svnusername, $svnurl, $svnpassword)
  let $svninfo := svn:info($checkoutdir, $svnusername, $svnpassword)
  let $path := $svninfo/*:param[@name eq 'path']/@value
  let $checkout-or-update := if(file:exists($checkoutdir)) 
                             then svn:update($svnusername, $svnpassword, $checkoutdir, 'HEAD')
                             else svn:checkout($svnurl, $svnusername, $svnpassword, $checkoutdir, 'HEAD') 
  return svn:list( $checkoutdir, $svnusername, $svnpassword, false())
};
(:
 :  control-api:checkout()
 :    
 :  checkout a svn path according to this scheme:
 :  /workdir/username/repo/path
:)
declare
  %rest:GET
  %rest:path("/control/api/checkout")
  %rest:query-param("svnurl", "{$svnurl}")
  %rest:query-param("svnusername", "{$svnusername}")
  %rest:query-param("svnpassword", "{$svnpassword}")
  %output:method('xml')
function control-api:checkout( $svnurl as xs:string, $svnusername as xs:string, $svnpassword as xs:string ) as element(c:param-set) {
  let $checkoutdir := control-util:get-checkout-dir($svnusername, $svnurl, $svnpassword) 
  return svn:checkout($svnurl, $svnusername, $svnpassword, $checkoutdir, 'HEAD')  
};
(:
 :  control-api:copy()
 :    
 :  copies a file or directory
:)
declare
  %rest:GET
  %rest:path("/control/api/copy")
  %rest:query-param("svnurl", "{$svnurl}")
  %rest:query-param("svnusername", "{$svnusername}")
  %rest:query-param("svnpassword", "{$svnpassword}")
  %rest:query-param("path", "{$path}")
  %rest:query-param("target", "{$target}")
  %output:method('xml')
function control-api:copy( $svnurl as xs:string, $svnusername as xs:string, $svnpassword as xs:string, $path as xs:string, $target as xs:string ) {
  let $commitmsg := '[control] ' || $svnusername || ': copy ' || $path || ' => ' || $target
  let $checkoutdir := control-util:get-checkout-dir($svnusername, $svnurl, $svnpassword)
  let $checkout-or-update := if(file:exists($checkoutdir)) 
                             then svn:update($svnusername, $svnpassword, $checkoutdir, 'HEAD')
                             else svn:checkout($svnurl, $svnusername, $svnpassword, $checkoutdir, 'HEAD') 
  return svn:copy($checkoutdir, $svnusername, $svnpassword, $path, $target, ())/svn:commit($svnusername, $svnpassword, $checkoutdir, $commitmsg)
};
(:
 :  control-api:delete
 :    
 :  delete a file or directory
:)
declare
  %rest:GET
  %rest:path("/control/api/delete")
  %rest:query-param("svnurl", "{$svnurl}")
  %rest:query-param("svnusername", "{$svnusername}")
  %rest:query-param("svnpassword", "{$svnpassword}")
  %rest:query-param("path", "{$path}")
  %output:method('xml')
function control-api:delete( $svnurl as xs:string, $svnusername as xs:string, $svnpassword as xs:string, $path as xs:string ) {
  let $commitmsg := '[control] ' || $svnusername || ': delete ' || $path
  let $checkoutdir := control-util:get-checkout-dir($svnusername, $svnurl, $svnpassword)
  let $checkout-or-update := if(file:exists($checkoutdir)) 
                             then svn:update($svnusername, $svnpassword, $checkoutdir, 'HEAD')
                             else svn:checkout($svnurl, $svnusername, $svnpassword, $checkoutdir, 'HEAD') 
  return svn:delete($checkoutdir, $svnusername, $svnpassword, $path, true(), ())/svn:commit($svnusername, $svnpassword, $checkoutdir, $commitmsg)
};
(:
 :  control-api:move
 :    
 :  delete a file or directory
:)
declare
  %rest:GET
  %rest:path("/control/api/move")
  %rest:query-param("svnurl", "{$svnurl}")
  %rest:query-param("svnusername", "{$svnusername}")
  %rest:query-param("svnpassword", "{$svnpassword}")
  %rest:query-param("path", "{$path}")
  %rest:query-param("target", "{$target}")
  %output:method('xml')
function control-api:move( $svnurl as xs:string, $svnusername as xs:string, $svnpassword as xs:string, $path as xs:string, $target as xs:string ) {
  let $commitmsg := '[control] ' || $svnusername || ': copy ' || $path || ' => ' || $target
  let $checkoutdir := control-util:get-checkout-dir($svnusername, $svnurl, $svnpassword)
  let $checkout-or-update := if(file:exists($checkoutdir)) 
                             then svn:update($svnusername, $svnpassword, $checkoutdir, 'HEAD')
                             else svn:checkout($svnurl, $svnusername, $svnpassword, $checkoutdir, 'HEAD') 
  return svn:move($checkoutdir, $svnusername, $svnpassword, $path, $target, ())/svn:commit($svnusername, $svnpassword, $checkoutdir, $commitmsg)
};
