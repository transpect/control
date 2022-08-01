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
 : check if svnurl is a local repo
 :)
declare function control-util:is-svn-repo( $svnurl as xs:string ) as xs:boolean {
  let $children := svn:list($svnurl, $control:svnusername, $control:svnpassword, false())//*:directory
  return count($children[@name = ("locks", "hooks", "db")]) ge 3
};

(:
 : check if svnurl is a local repo with external url
 :)
declare function control-util:is-local-repo( $svnurl as xs:string ) as xs:boolean {
  false()};

declare
function control-util:writeindextofile($index) {
  file:write("/home/transpect-control/basex/webapp/control/index.xml",$index)
};

declare function control-util:create-path-index($svnurl as xs:string,
                                                $name as xs:string?,
                                                $type as xs:string, 
                                                $virtual-path as xs:string,
                                                $mount-point as xs:string?){
  element {$type} {
    attribute name {$name},
    attribute svnurl {control-util:get-local-path($svnurl)},
    attribute virtual-path {control-util:get-local-path($virtual-path)},
    if ($type = 'file') then attribute mount-point {$mount-point}
    else (
    for $d in svn:list($svnurl,$control:svnauth, false())/*
    let $sub := control-util:create-path-index(concat($svnurl,'/',$d/@name),
                                               $d/@name,
                                               $d/local-name(), 
                                               $virtual-path || '/' || $d/@name,
                                               $mount-point)
    return $sub,
    for $e in control-util:parse-externals-property(svn:propget($svnurl, $control:svnauth, 'svn:externals', 'HEAD'))
    return 
      <external name="{$e/@mount}" path="{control-util:get-local-path($e/@url)}" mount-point="{control-util:get-local-path($svnurl || '/' || $e/@mount)}" svnurl="{control-util:get-local-path($svnurl)}">
        {for $f in svn:list(xs:string($e/@url),$control:svnauth, false())/*
         let $subf := control-util:create-path-index(string-join((xs:string($e/@url),$f/@name),'/'),
                                                     $f/@name,
                                                     $f/local-name(),
                                                     $virtual-path || '/' || $e/@mount ||  '/' || $f/@name,
                                                     $svnurl || '/' || $e/@mount)
         return $subf}
      </external>)
  }
};

declare function control-util:get-permissions-for-file($svnurl as xs:string,
                                                       $file as xs:string,
                                                       $access){
  let $selected-repo := tokenize(svn:info($svnurl, $control:svnauth)/*:param[@name = 'root-url']/@value,'/')[last()],
      $selected-filepath := replace(replace(replace(string-join(($svnurl,$file),'/'),'/$',''),svn:info($svnurl, $control:svnauth)/*:param[@name = 'root-url']/@value,''),'^/',''),
      $admin-group := $access//control:groups/control:group[control:name = 'admin'],
      $explicit-permissions := for $group in $access//control:groups/control:group except $admin-group
                               let $p := $access//control:rels/control:rel[control:file = $selected-filepath]
                                                                          [control:repo = $selected-repo]
                                                                          [control:permission]
                                                                          [control:group = $group/control:name]
                               return if ($p) 
                                      then element permission { element g {$group/control:name/text()},
                                                                element p {$p/control:permission/text()},
                                                                element i {false()}},
      $implicit-permissions := for $group in $access//control:groups/control:group except $admin-group
                               let $writeable-repos := $access//control:rels/control:rel[control:group = $group]
                                                                                        [control:repo]
                                                                                        [not(control:file)],
                                   $p := if (control-util:or(for $r in $writeable-repos return matches($selected-repo,$r/control:repo)))
                                         then 'write'
                                         else 'read'
                               return element permission { element g {$group/control:name/text()},
                                                           element p {$p},
                                                           element i {true()}}
  return for $group in $access//control:groups/control:group
         return ($explicit-permissions[g = $group/control:name], $implicit-permissions[g = $group/control:name])[1]
         
};

declare function control-util:or($bools as xs:boolean*) as xs:boolean{
  count($bools[. = true()]) > 0
};

declare function control-util:is-file($file as xs:string?) as xs:boolean{
  matches($file,'\.')
};
declare function control-util:split-string-at-length($str as xs:string?, $length as xs:integer) as xs:string* {
  for $i in (1 to (xs:integer(ceiling(string-length($str) div $length))))
  return substring($str, ($i - 1) * $length + 1, $length)
};

declare function control-util:svnurl-to-link($svnurl as xs:string) as element(a){
  <a href="{$control:siteurl || '?svnurl=' || $svnurl}">{$svnurl}</a>
};

declare function control-util:get-short-string($str as xs:string, $length as xs:integer) as xs:string {
  concat(
    control-util:split-string-at-length(xs:string($str),$length - 5)[1],
      if (string-length(xs:string($str)) gt ($length - 5))  
      then '...' 
      else '')
};

declare function control-util:update-path-index-at-svnurl($index, $svnurl as xs:string){
  let $updated-index :=  
       copy $ind := $index
       modify (
         for $t in $ind//*[@svnurl eq $svnurl]
         return replace node $t with
           control-util:create-path-index($svnurl,
                                          tokenize($svnurl,'/')[last()],
                                          $t/local-name(), 
                                          $t/@virtual-path, 
                                          $t/@mount-point)
       )
       return $ind
  return $updated-index
};

declare function control-util:pad-text($string as xs:string?, $length as xs:integer) as xs:string{
  concat($string, string-join(for $x in 1 to ($length - string-length($string)) return ' ', ""))
};

declare function control-util:create-download-link($svnurl as xs:string, $file as xs:string?) as xs:string{
  let $result := string-join((replace(replace($svnurl,'127.0.0.1','localhost:' || $control:port),$control:svnbasewerke,$control:repobase),$file),'/')
  return $result
};
declare function control-util:get-local-path($svnurl as xs:string) as xs:string{
  let $result := replace($svnurl,'http://127.0.0.1/content/','/data/svn/')
  return $result
};

declare function control-util:get-permission-for-group($group as xs:string, $repo as xs:string, $access) as xs:string?{
  let $writeable-repos := $access//control:rels/control:rel[control:group = $group]
                                                      [control:repo]
                                                      [not(control:file)],
      $indirect-permission := if (control-util:or(for $r in $writeable-repos return matches($repo,$r/control:repo)))
                              then 'write'
                              else 'read',
      $direct-permission := $access//control:rels/control:rel[control:group = $group]
                                                              [control:repo  =$repo]
                                                              [control:permission]
                                                              [control:file = '']/control:permission,
      $combined-permission := ($direct-permission,$indirect-permission)[1],
      $selected-permission := if ($combined-permission = 'none') then ''
                              else if ($combined-permission = 'read') then 'r'
                              else if ($combined-permission = 'write') then 'rw'
  return $selected-permission
};
declare function control-util:get-permission-for-user($user as xs:string, $repo as xs:string, $access) as xs:string?{
  for $group in $access/control:groups/control:group/control:name
  let $rels := $access//control:rels/control:rel[control:user = $user]
                                               [control:group],
      $permission := control-util:get-permission-for-group($group, $repo, $access)
  where exists($access/control:rels/control:rel[control:user = $user][control:group = $group])
  return $permission
};
(:
 : get mimetype for file extension
 :)
declare function control-util:ext-to-mimetype( $ext as xs:string? ) as xs:string {
     if ( $ext eq 'xml')              then 'text-xml'
else if ( $ext eq 'text')             then 'text-plain'
else if ( $ext = ('Makefile', 'bat')) then 'text-x'
else                                      'text-plain'
};
(:
 : is user admin
 :)
declare function control-util:is-admin( $username as xs:string) as xs:boolean {
let $user := $control:access//*:users/*:user[*:name=$username],
    $grouprels := $control:access//*:rels/*:rel[*:user][*:user=$user/*:name]
 return "admin" = $grouprels/*:group
};
(:
 : get read/write for username and repo
 :)
declare function control-util:get-rights( $username as xs:string, $repotitle as xs:string? ) as xs:string {
let  $user := $control:access//*:users/*:user[*:name=$username],
 $grouprel := $control:access//*:rels/*:rel[*:user][*:user=$user/*:name],
    $group := $control:access//*:groups/*:group[*:name = $grouprel/*:group],
     $rels := $control:access//*:rels/*:rel[*:repo][*:group=$group],
    $repos := $control:access//*:repos/*:repo[matches(*:title,string-join($rels/*:repo/text(),"|"))]
 return if ((control-util:is-admin($username)) or ($repotitle = $repos/*:title))
        then "write"
        else "read"
};

declare function control-util:normalize-repo-url( $url as xs:string ) as xs:string {
  replace($url, '\p{P}', '_')
};

declare function control-util:get-defaultsvnurl-from-user($username as xs:string) as xs:string?{
  $control:access//control:rels/control:rel[control:user = $username][control:defaultsvnurl]/control:defaultsvnurl/text()
};

declare function control-util:get-current-svnurl($username as xs:string, $svnurl as xs:string?) as xs:string {
  ($svnurl,
    session:get('svnurl'),
    control-util:get-defaultsvnurl-from-user($username),
    $control:svnurlhierarchy)[. != ''][1]
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
        $url := replace(replace($url-plus-rev, '^(.+)(@.*)?$', '$1'),'localhost:'|| $control:port,'127.0.0.1')
    return (attribute url { $url },
            if(exists($rev)) then attribute rev { $rev } else (),
            attribute mount { $mount })
  }</external>
};

declare function control-util:writegroups($access) as xs:string {
    string-join(('[groups]',
    for $group in $access//control:groups/control:group (:groups:)
    where $access//control:rels/control:rel[control:user][control:group=$group/control:name]
    return concat($group/control:name,' = ',string-join(
      for $rel in $access//control:rels/control:rel[control:user][control:group = $group/control:name] (:user:)
      return $rel/*:user,', ')
    )),$control:nl)
};