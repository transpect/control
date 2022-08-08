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
%output:method('xml')
function control-search:ftsearch-raw($term, $lang) {
  let $base-virtual-path := $control:svnurlhierarchy,
      $ftdb := $control:config/control:ftindexes/control:ftindex[@lang = $lang] => string(),
      $normalized := ft:normalize($term),
      $total := count(ft:search($ftdb,
                                $normalized, 
                                map{'wildcards':'true', 'mode':'all words'})),
  $results := 
    for $result score $score in ft:search('hobotscontrol_FT_de', $term,
    map{'wildcards':'true', 'mode':'all words'})
    let $path := '/' || $result/db:path(.),
    $virtual-path := (db:attribute('INDEX', $path, 'svnpath'))[1]/../@virtual-path
    order by $score descending
    return <result> {
      $result/../@id,
      $result/../@path,
      attribute virtual-path { substring-after($virtual-path, $base-virtual-path) },
      attribute xml:base { $path },
      attribute score { $score },
      element breadcrumbs {
        $result/ancestor::doc/title, $result/../parent::div/ancestor-or-self::div/title
      },
      element context {
        ft:mark($result[. contains text {$normalized} using wildcards])
      }
    } </result>
    return
    <search-results term="{$normalized}" count="{$total}" actual="{count($results)}">{
      $results
    }</search-results>
};

