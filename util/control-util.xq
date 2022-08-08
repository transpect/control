module namespace control-util        = 'http://transpect.io/control/util/control-util';
import module namespace svn          = 'io.transpect.basex.extensions.subversion.XSvnApi';
import module namespace control      = 'http://transpect.io/control' at '../control.xq';
import module namespace control-i18n = 'http://transpect.io/control/util/control-i18n' at 'control-i18n.xq';

declare namespace control-widgets = 'http://transpect.io/control/util/control-widgets';
declare namespace control-custom = 'http://transpect.io/control/control-customization';

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
  file:write('basex/webapp/control/'||$control:indexfile,$index)
};

declare function control-util:create-path-index($svnurl as xs:string,
                                                $name as xs:string?,
                                                $type as xs:string, 
                                                $virtual-path as xs:string,
                                                $mount-point as xs:string?){
  if (svn:list($svnurl, $control:svnauth, false())[not(*:error)])
  then 
    element {$type} {
(:      attribute raw {$svnurl || '--' || $name || '--' || $type || '--' || $virtual-path || '--' ||$mount-point},:)
      attribute name {$name},
      if ($type = 'directory') then prof:dump(string-join((convert:integer-to-dateTime(prof:current-ms()), $svnurl, control-util:get-local-path($svnurl)), ' ')) else (),
      attribute svnpath {control-util:get-local-path($svnurl)},
      attribute virtual-path {control-util:get-local-path($virtual-path)},
      for $d in svn:list($svnurl,$control:svnauth, false())/*[not(self::*:error)]
      let $sub := control-util:create-path-index(concat($svnurl,'/',$d/@name),
                                                 $d/@name,
                                                 $d/local-name(), 
                                                 $virtual-path || '/' || $d/@name,
                                                 $mount-point)
      return $sub,
      for $e in control-util:parse-externals-property(svn:propget($svnurl, $control:svnauth, 'svn:externals', 'HEAD'))
      return 
        <external name="{$e/@mount}" path="{control-util:get-local-path($e/@url)}" 
                  mount-point="{control-util:get-local-path($svnurl || '/' || $e/@mount)}" 
                  svnpath="{control-util:get-local-path($svnurl)}"
                  virtual-path="{control-util:get-local-path($virtual-path) || '/' || $e/@mount}">
          {for $f in svn:list(xs:string($e/@url),$control:svnauth, false())/*
           let $subf := control-util:create-path-index(string-join((xs:string($e/@url),$f/@name),'/'),
                                                       $f/@name,
                                                       $f/local-name(),
                                                       $virtual-path || '/' || $e/@mount ||  '/' || $f/@name,
                                                       $svnurl || '/' || $e/@mount)
           return $subf}
        </external>
    }
};

declare function control-util:get-svnurl-parent-from-index($svnurl as xs:string) {
  db:open('INDEX')//*[@svnurl eq $svnurl]/parent::*/@svnurl
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
  let $result := string-join((control-util:get-canonical-path($svnurl),$file),'/')
  return $result
};

declare function control-util:get-local-path($svnurl as xs:string) as xs:string{
let $repo := control-util:get-repo-for-svnurl($svnurl),
    $repourl := if ($repo/@parent-path) then $repo/@parent-path else $repo/@path,
    $local-path := replace($repourl,'/$',''),
    $canon-path := replace($repo/@canon-path,'/$','')
return if ($repo)  then replace($svnurl,'^'||$canon-path, $local-path) else $svnurl
};

declare function control-util:get-canonical-path($svnurl as xs:string) as xs:string{
let $repo := control-util:get-repo-for-svnurl($svnurl),
    $repourl := if ($repo/@parent-path) then $repo/@parent-path else $repo/@path,
    $local-path := replace($repourl,'/$',''),
    $canon-path := replace($repo/@canon-path,'/$','')
return if ($repo) then replace($svnurl, '^'||$local-path, $canon-path) else $svnurl
};

declare function control-util:get-repo-for-svnurl($svnurl as xs:string) as element(control:repo)?{
  let $path-repos := $control:repos/control:repo[@path][contains($svnurl, replace(@path,'/$',''))],
      $parent-path-repos := $control:repos/control:repo[@parent-path][contains($svnurl, replace(@parent-path,'/$',''))],
      $canon-path-repos := $control:repos/control:repo[@canon-path][contains($svnurl, replace(@canon-path,'/$',''))],
      $all-repos := ($path-repos,$parent-path-repos, $canon-path-repos)
  return if (count($all-repos) gt 0) then $all-repos[1] else ()
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
    $control:default-svnurl,
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

declare function control-util:post-file-to-converter($svnurl as xs:string, $file as xs:string, $converter as xs:string, $type as xs:string) as element(conversion) {
(: $converter := hobots, $type := idml2tex:)
  let $filepath      := '/home/transpect-control/upload',
      $remove-folder := proc:execute('rm -r', ($filepath)),
      $prepare-file  := proc:execute('mkdir', ($filepath, '-p')),
      $checkout      := proc:execute('svn',('co', $svnurl, $filepath, '--username',$control:svnusername,'--password',$control:svnpassword)),
      $upload-call   := ('-F', 'type='||$type, '-F','input_file=@'||$filepath||'/'||$file, '-u', $control:svnusername||':'||$control:svnpassword,control-util:get-converter-function-url($converter,'upload')),
      $upload        := proc:execute('curl',('-F', 'type='||$type, '-F','input_file=@'||$filepath||'/'||$file, '-u', $control:svnusername||':'||$control:svnpassword,control-util:get-converter-function-url($converter,'upload'))),
      $upload_res    := json:parse($upload/output),
      $status        := proc:execute('curl',('-u', $control:svnusername||':'||$control:svnpassword,control-util:get-converter-function-url($converter,'status')||'?input_file='||$file||'&amp;type='||$type)),
      $status_res    := json:parse($status/output),
      $result_xml    := 
        <conversion>
          <id>{random:uuid()}</id>
          <type>{$upload_res/json/conversion__type/text()}</type>
          <file>{$file}</file>
          <svnurl>{$svnurl}</svnurl>
          <status>{if ($upload_res/json/status/text()) then $upload_res/json/status/text() else 'failed'}</status>
          <callback>{$upload_res/json/callback__uri/text()}</callback>
          <delete>{$status_res/json/delete__uri/text()}</delete>
          <result_list>{$status_res/json/r1esult__list__uri/text()}</result_list>
        </conversion>
  return $result_xml
};

(:
 : get running conversions
 :)
 declare function control-util:get-running-conversions($svnurl as xs:string, $file as xs:string, $type as xs:string) {
  let $conversions := $control:conversions//control:conversion[control:type = $type][control:file = $file][control:svnurl = $svnurl]
  return $conversions
};

(:
 : start new conversion and save it
 :)
declare function control-util:start-new-conversion($svnurl as xs:string, $file as xs:string, $type as xs:string) {
  let $conv := control-util:post-file-to-converter($svnurl, $file, control-util:get-converter-for-type($type)/@name, $type)
  return $conv
};

declare function control-util:get-converters-for-file($file as xs:string) as xs:string* {
     let $ext := replace($file,'.*\.([^\.]+)','$1')
  return $control:converters//type[matches(@name,concat('^',$ext))]/@type
};

declare function control-util:add-conversion($conv as element(conversion)) {
  let $file := doc($control:mgmtfile),
      $updated-conversions := $file update {insert node $conv into //control:conversions}
      
  return file:write("basex/webapp/control/"||$control:mgmtfile, $updated-conversions)
};

declare function control-util:update-conversion($id as xs:string) as element(conversion){
  let $conversion := $control:conversions//control:conversion[id/text() eq $id],
      $converter  := control-util:get-converter-for-type($conversion/control:type),
      $type  := $conversion/control:type,
      $file       := $conversion/control:file/text(),
      $status     := proc:execute('curl',('-u', $control:svnusername||':'||$control:svnpassword,control-util:get-converter-function-url($converter,'status')||'?input_file='||$file||'&amp;type='||$type)),
      $status_res := json:parse($status/output),
      $updated-conversion := 
        copy $old := $conversion
        modify (
          replace value of node $old//control:status with if ($status_res/json/status/text()) then $status_res/json/status/text() else 'failed'
        )
        return $old,
      $file := doc($control:mgmtfile),
      $updated-access := $file update {delete node //control:conversion[control:id = $id]}
                               update {insert node $updated-conversion into .//control:rels},
      $updated-file := file:write("basex/webapp/control/"||$control:mgmtfile, $updated-access)
  return $updated-conversion
};

declare function control-util:get-converter-for-type($type as xs:string) {
  $control:converters/converter[descendant::type[@type = $type]]
};

declare function control-util:get-converter-function-url($name as xs:string, $type as xs:string){
  let $converter := $control:converters/converter[@name = $name]
  return $converter/base/text()||$converter/endpoints/*[local-name(.) = $type]/text()
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

declare function control-util:function-lookup ( $role as xs:string ) as function(*)? {
  $control:config/control:functions/control:function[@role = $role]
    ! function-lookup(xs:QName(@name), @arity)
};

declare function control-util:parse-authorization($header as xs:string?) as map(xs:string, xs:string)? {
  for $h in $header
  let $credentials := $h => substring(6)
                         => xs:base64Binary()
                         => bin:decode-string()
                         => tokenize(':')
  return map{'username':$credentials[1],'cert-path':'', 'password': $credentials[2]}
};