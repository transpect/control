module namespace control-util        = 'control-util';
import module namespace svn          = 'io.transpect.basex.extensions.subversion.XSvnApi';
import module namespace control      = 'control' at '../control.xq';
import module namespace control-i18n = 'control-i18n' at 'control-i18n.xq';
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
  else concat('static/icons/flat-remix/Flat-Remix-Blue-Dark/mimetypes/scalable/',
              control-util:ext-to-mimetype( $ext ),
              '.svg' )
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