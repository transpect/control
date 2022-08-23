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

declare namespace css                   = 'http://www.w3.org/1996/css';

declare 
%rest:path('/control/cssa-rule-search-raw')
%rest:query-param("name-regex", "{$name-regex}")
%rest:query-param("occurrences", "{$occurrences}", "false")
%rest:query-param("svn-path-constraint", "{$svn-path-constraint}")
%output:method('xml')
function control-search:css-rule-search-raw($name-regex as xs:string, $occurrences as xs:boolean,
                                            $svn-path-constraint as xs:string?) {
  let $base-virtual-path := control-util:get-local-path($control:svnurlhierarchy),
      $virtual-constraint as xs:string? := $svn-path-constraint => control-util:get-virtual-path(),
      $db := db:open($control:config/control:db),
      $results 
         := for $result in $db//css:rule[matches(@native-name, $name-regex, 'i')]
            let $path := '/' || $result/db:path(.),
                $virtual-path := $path => control-util:get-virtual-path()
            where if ($svn-path-constraint) then starts-with($virtual-path, $virtual-constraint) else true()
            return <result> {
              substring-after($virtual-path, $base-virtual-path) ! (
                attribute virtual-path { . },
                attribute virtual-steps { count(tokenize(., '/')[normalize-space()]) }
              ),
              attribute dbpath { $path },
              attribute svnurl { control-util:get-canonical-path($path) },
              $result,
              if ($occurrences = true()) then 
                let $root := root($result),
                    $att-names := ($root/*/@css:rule-selection-attribute => tokenize()) 
                return for $att-name in $att-names 
                       return <xpath>{ $root//@*[name() = $att-name][. = $result/@name]/../path() }</xpath>
            } </result>
    return
    <search-results css-rule-regex="{$name-regex}" count="{count($results)}" 
      path-constraint="{$svn-path-constraint}" virtual-constraint="{$virtual-constraint}">{
      $results
    }</search-results>
};

declare 
%rest:path('/control/xpathsearch-raw')
%rest:query-param("xpath", "{$xpath}")
%rest:query-param("svn-path-constraint", "{$svn-path-constraint}")
%output:method('xml')
function control-search:xpathsearch-raw($xpath as xs:string, $svn-path-constraint as xs:string?) {
  let $base-virtual-path := control-util:get-local-path($control:svnurlhierarchy),
      $virtual-constraint as xs:string? := $svn-path-constraint => control-util:get-virtual-path(),
      $db := db:open($control:config/control:db),
      $results 
        := for $result in xquery:eval($xpath, map { '': $db } ) 
           let $path := '/' || $result/db:path(.),
               $virtual-path := $path => control-util:get-virtual-path()
           where if ($svn-path-constraint) 
                 then if ($virtual-constraint) 
                      then starts-with($virtual-path, $virtual-constraint) 
                      else false() (: the constraint could not be resolved to a path in the virtual hierarchy :)
                 else true()
           return <result> {
              attribute path {$result/path(.) => replace('/Q\{\}', '/') },
              substring-after($virtual-path, $base-virtual-path) ! (
                attribute virtual-path { . },
                attribute virtual-steps { count(tokenize(., '/')[normalize-space()]) }
              ),
              attribute dbpath { $path },
              attribute svnurl { control-util:get-canonical-path($path) }
            } </result>
    return
    <search-results xpath="{$xpath}" count="{count($results)}" 
      path-constraint="{$svn-path-constraint}" virtual-constraint="{$virtual-constraint}">{
      $results
    }</search-results>
};

declare 
%rest:path('/control/ftsearch-raw')
%rest:query-param("term", "{$term}")
%rest:query-param("lang", "{$lang}")
%rest:query-param("xpath", "{$xpath}")
%rest:query-param("details", "{$details}", 'true')
%rest:query-param("svn-path-constraint", "{$svn-path-constraint}")
%output:method('xml')
function control-search:ftsearch-raw($term as xs:string, $lang as xs:string*, $xpath as xs:string?, 
                                      $svn-path-constraint as xs:string?, $details as xs:boolean) {
  let $base-virtual-path := control-util:get-local-path($control:svnurlhierarchy),
      $virtual-constraint as xs:string? := $svn-path-constraint => control-util:get-virtual-path(),
      $ftdbs := $control:config/control:ftindexes/control:ftindex[@lang = $lang ! normalize-space(.)],
      $db := db:open($control:config/control:db),
      $normalized-term := ft:normalize($term),
      $normalized-xpath := $xpath => normalize-space(),
      (: absolute paths – this should not be combined with full-text search as it is highly inefficient :)
      $xpath-results := if (starts-with($normalized-xpath, '/') or not($term)) then 
                        for $xpath-result in xquery:eval($normalized-xpath, map { '': $db } )
                        let $path := '/' || $xpath-result/db:path(.),
                            $virtual-path := $path => control-util:get-virtual-path()
                        where if ($svn-path-constraint) 
                          then if ($virtual-constraint) 
                               then starts-with($virtual-path, $virtual-constraint) 
                               else false() (: the constraint could not be resolved to a path in the virtual hierarchy :)
                          else true()
                       return $xpath-result
                       else (),
      $xpath-results-xpaths := $xpath-results ! path(.) ! replace(., '/Q\{\}', '/'),
      $results 
         := for $ftdb in $ftdbs
            return
              for $result score $score in ft:search(string($ftdb), $term, map{'wildcards':'true', 'mode':'all words'})
              let $path := '/' || $result/db:path(.),
                  $result-xpath as xs:string? := string($result/../@path)[normalize-space()],
                  $breadcrumbs := ( ($result/ancestor::doc/*[1]/self::title, <title>[title missing]</title>)[1], 
                                    $result/ancestor::div/*[1]/self::title ),
                  $virtual-path := $path => control-util:get-virtual-path()
              where (if ($svn-path-constraint) then starts-with($virtual-path, $virtual-constraint) else true())
                    and
                      (: this is the inefficient part that should be avoided :)
                      (if (starts-with(normalize-space($xpath), '/')) 
                       then some $xpx in $xpath-results-xpaths satisfies contains($result-xpath, $xpx)
                       else if (matches($normalized-xpath, '^(\i|\.|\*)')) (: this is highly efficient :)
                            then let $modified-xpath := if (matches(tokenize($normalized-xpath, '/')[1], '^[a-z-]+::'))
                                                        then $normalized-xpath
                                                        else if (starts-with($normalized-xpath, '.'))
                                                             then $normalized-xpath
                                                             else 'ancestor-or-self::' || $normalized-xpath,
                                     $corresponding-doc as document-node(element(*)) := db:open($control:config/control:db, $result/db:path(.))[last()], 
                                     $corresponding-elt as element(*)? := if (empty($result-xpath)) then ()
                                                                          else xquery:eval($result-xpath, map { '': $corresponding-doc})
                                 return if (empty($result-xpath)) then true()
                                        else exists(xquery:eval($modified-xpath, map { '': $corresponding-elt } ))
                            else true() )
              return <result> {
                $result/../@id,
                $result/../@path,
                if (empty($result-xpath)) then attribute path {},
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
                  ft:extract($result[. contains text {$normalized-term} using wildcards])
                }
                else ()
              } </result>
    return
    <search-results term="{$normalized-term}" count="{count($results)}" 
      path-constraint="{$svn-path-constraint}" virtual-constraint="{$virtual-constraint}">{
      $results
    }</search-results>
};

declare 
%rest:path('/control/ftsearch')
%rest:query-param("term", "{$term}")
%rest:query-param("lang", "{$lang}")
%rest:query-param("xpath", "{$xpath}")
%rest:query-param("svnurl", "{$svnurl}")
%rest:query-param("restrict_path", "{$restrict_path}", 'false')
%rest:query-param("details", "{$details}", 'true')
%output:method('html')
%output:version('5.0')
function control-search:ftsearch($svnurl as xs:string?, $term as xs:string, $lang as xs:string*, $xpath as xs:string?, 
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
         control-search:ftsearch-raw($term, $lang, $xpath, control-util:get-local-path($svnurl)[$restrict_path = true()],
                                     $details) 
           => xslt:transform('../../control-backend/fulltext/render-results.xsl', 
                             map{'svnbaseurl': $control:svnurlhierarchy,
                                 'siteurl': $control:siteurl,
                                 'langs': string-join($lang ! normalize-space(.), ','),
                                 'term': $term,
                                 'xpath': $xpath})
      }</main>
      {control-widgets:get-page-footer(),
       control-widgets:create-infobox()}
    </body>
  </html>
};
