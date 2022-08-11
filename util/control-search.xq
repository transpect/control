(:
 : functions that evaluate form fields and queries
 : and redirect to the main function with web:redirect()
 : messages and their status are returned with $msg and $msgtype
 :)
module namespace control-search         = 'http://transpect.io/control/util/control-search';
import module namespace svn             = 'io.transpect.basex.extensions.subversion.XSvnApi';
import module namespace control         = 'http://transpect.io/control' at '../control.xq';
import module namespace control-i18n    = 'http://transpect.io/control/util/control-i18n' at 'control-i18n.xq';
import module namespace control-util    = 'http://transpect.io/control/util/control-util' at 'control-util.xq';
import module namespace control-widgets = 'http://transpect.io/control/util/control-widgets' at 'control-widgets.xq';

declare 
%rest:path('/control/ftsearch-raw')
%rest:query-param("term", "{$term}")
%rest:query-param("lang", "{$lang}")
%rest:query-param("details", "{$details}", 'true')
%rest:query-param("svn-path-constraint", "{$svn-path-constraint}")
%output:method('xml')
function control-search:ftsearch-raw($term as xs:string, $lang as xs:string*, 
                                      $svn-path-constraint as xs:string?, $details as xs:boolean) {
  let $base-virtual-path := control-util:get-local-path($control:svnurlhierarchy),
      $virtual-constraint as xs:string? := $svn-path-constraint => control-util:get-virtual-path(),
      $ftdbs := $control:config/control:ftindexes/control:ftindex[@lang = $lang],
      $normalized := ft:normalize($term),
      $results 
         := for $ftdb in $ftdbs
            return
              for $result score $score in ft:search(string($ftdb), $term, map{'wildcards':'true', 'mode':'all words'})
              let $path := '/' || $result/db:path(.),
                  $breadcrumbs := ( ($result/ancestor::doc/*[1]/self::title, <title>[title missing]</title>)[1], 
                                    $result/ancestor::div/*[1]/self::title ),
              $virtual-path := $path => control-util:get-virtual-path()
              where if ($svn-path-constraint) then starts-with($virtual-path, $virtual-constraint) else true()
              return <result> {
                $result/../@id,
                $result/../@path,
                substring-after($virtual-path, $base-virtual-path) ! (
                  attribute virtual-path { . },
                  attribute virtual-steps { count(tokenize(., '/')[normalize-space()]) }
                ),
                attribute dbpath { $path },
                attribute svnurl { control-util:get-canonical-path($path) },
                attribute lang { $ftdb/@lang },
                attribute ftdb { string($ftdb) },
                attribute score { $score },
                attribute breadcrumbs-signature { string-join($breadcrumbs ! generate-id(.), '_') },
                element breadcrumbs {
                  $breadcrumbs
                },
                if ($details) then
                element context {
                  ft:extract($result[. contains text {$normalized} using wildcards])
                }
                else ()
              } </result>
    return
    <search-results term="{$normalized}" count="{count($results)}" 
      path-constraint="{$svn-path-constraint}" virtual-constraint="{$virtual-constraint}">{
      $results
    }</search-results>
};

declare 
%rest:path('/control/ftsearch')
%rest:query-param("term", "{$term}")
%rest:query-param("lang", "{$lang}")
%rest:query-param("svnurl", "{$svnurl}")
%rest:query-param("restrict_path", "{$restrict_path}", 'false')
%rest:query-param("details", "{$details}", 'true')
%output:method('html')
%output:version('5.0')
function control-search:ftsearch($svnurl as xs:string?, $term as xs:string, $lang as xs:string*, 
                                 $restrict_path as xs:boolean, $details as xs:boolean) {
  let $auth := control-util:parse-authorization(request:header("Authorization")),
      $used-svnurl := control-util:get-canonical-path(control-util:get-current-svnurl($auth?username, $svnurl)),
      $search-widget-function as function(xs:string?, xs:string, map(xs:string, xs:string), map(*)?) as item()* 
        := (control-util:function-lookup('search-form-widget'), control-widgets:search-input#4)[1]
  return  
  <html>
    <head>
      {control-widgets:get-html-head($used-svnurl)}
    </head>
    <body>
      {control-widgets:get-page-header( )}
      <main>{
         $search-widget-function( $used-svnurl, $control:path, $auth, 
                                  map:merge(request:parameter-names() ! map:entry(., request:parameter(.))) ),  
         control-search:ftsearch-raw($term, $lang, control-util:get-local-path($svnurl)[$restrict_path = true()],
                                     $details) 
           => xslt:transform('../../control-backend/fulltext/render-results.xsl', 
                             map{'svnbaseurl': $control:svnurlhierarchy,
                                 'siteurl': $control:siteurl})
      }</main>
      {control-widgets:get-page-footer(),
       control-widgets:create-infobox()}
    </body>
  </html>
};
