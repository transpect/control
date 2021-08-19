module namespace control-util        = 'http://transpect.io/control/util/control-util';
import module namespace svn          = 'io.transpect.basex.extensions.subversion.XSvnApi';
import module namespace control      = 'http://transpect.io/control' at '../control.xq';
import module namespace control-i18n = 'http://transpect.io/control/util/control-i18n' at 'control-i18n.xq';

declare namespace c = 'http://www.w3.org/ns/xproc-step';

(: 
 : prints the parent directory of a path,
 : e.g. /home/parentdir/mydir/ => /home/parentdir/ 
 :)  
declare function control-util:path-parent-dir( $path as xs:string ) as xs:string? {
  string-join(
              remove(
                     tokenize($path, '/'),
                     count(tokenize($path, '/'))
                     ),
              '/')
};
(:
 : decode escaped characters within an URI 
 :)
declare function control-util:decode-uri( $uri as xs:string ) {
  for $i in analyze-string($uri, '%\d{2}')/*
  return string-join(if($i/self::fn:match )
                     then codepoints-to-string(convert:integer-from-base(replace($i, '%(\d{2})', '$1'), 16))
                     else $i, 
                     '')
};
(:
 : get icon url for an icon name
 :)
declare function control-util:get-mimetype-url( $ext as xs:string? ) as xs:string {
  if (( $ext ) eq 'folder')
  then 'static/icons/flat-remix/Flat-Remix-Blue-Dark/places/scalable/folder-black.svg'
    else if ($ext = 'external')
    then 'static/icons/flat-remix/Flat-Remix-Blue-Dark/places/scalable/folder-black-documents.svg'
    else 'static/icons/flat-remix/Flat-Remix-Blue-Dark/mimetypes/scalable/' || control-util:ext-to-mimetype( $ext ) || '.svg' 
};
(:
 : get mimetype for file extension
 :)
declare function control-util:ext-to-mimetype( $ext as xs:string ) as xs:string {
     if ( $ext eq 'xml')              then 'text-xml'
else if ( $ext eq 'text')             then 'text-plain'
else if ( $ext = ('Makefile', 'bat')) then 'text-x'
else                                      'text-plain'
};
declare function control-util:normalize-repo-url( $url as xs:string ) as xs:string {
  replace($url, '\p{P}', '_')
};
declare function control-util:get-checkout-dir($svnusername as xs:string, $svnurl as xs:string, $svnpassword as xs:string) as xs:string {
  let $svninfo := svn:info($svnurl, $svnusername, $svnpassword)
  let $repo := control-util:normalize-repo-url($svninfo/*:param[@name eq 'root-url']/@value)
  let $path := $svninfo/*:param[@name eq 'path']/@value
  return $control:datadir || file:dir-separator() || $svnusername || file:dir-separator() || $repo || file:dir-separator() || $path
};
declare function control-util:parse-externals-property($prop as element(*)) as element(external)* {
  for $line in 
    ($prop/self::c:param-set[c:param[@name='property'][@value='svn:externals']]/c:param[@name='value']/@value
     => tokenize('[&#xa;&#xd;]+'))[normalize-space()]
  return <external> {
    let $tokens as xs:string+ := $line => tokenize('\s+'),
        $url-plus-rev := $tokens[matches(., '^https?:')],
        $mount as xs:string* := $tokens[not(matches(., '^https?:'))],
        $rev as xs:string* := ($url-plus-rev[contains(., '@')] => tokenize('@'))[last()],
        $url := replace($url-plus-rev, '^(.+)(@.*)?$', '$1')
    return (attribute url { $url },
            if(exists($rev)) then attribute rev { $rev } else (),
            attribute mount { $mount })
  }</external>
};
