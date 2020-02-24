module namespace control-util = 'control-util';
import module namespace svn = 'io.transpect.basex.extensions.subversion.XSvnApi';
import module namespace control = 'control' at '../control.xq';
import module namespace control-i18n = 'control-i18n' at 'control-i18n.xq';
(: 
 : gets the html head
 :)
declare function control-util:get-html-head( $control-dir as xs:string ) as element()+ {
  <meta charset="utf-8"></meta>,
  <title>control</title>,
  <script src="{$control-dir || '/static/js/control.js'}" type="text/javascript"></script>,
  <link rel="stylesheet" type="text/css" href="{$control-dir || '/static/style.css'}"></link>
};
declare function control-util:get-page-footer( ) as element(footer) {
  <footer>
    
  </footer>
};
(:
 : get the fancy page head
 :)
declare function control-util:get-page-header( $control-dir as xs:string ) as element(header) {
  <header>
    <div class="header-wrapper">
      <div id="logo">
        <img src="{$control-dir || '/static/icons/transpect.svg'}" alt="transpect logo"/>
      </div>
      <h1><span class="thin">transpect</span>control</h1>
    </div>
  </header>
};
declare function control-util:get-svnhome-button( $svnurl as xs:string, $control-dir as xs:string ) as element(div){
  <div class="home">
    <a href="{concat($control-dir,
                     '?svnurl=',
                     svn:info($svnurl, 
                              $control:svnusername, 
                              $control:svnpassword )/*:param[@name eq 'root-url']/@value
                              )}">
      <button class="create-dir action btn">
        <img class="small-icon" src="{$control:dir || '/static/icons/open-iconic/svg/home.svg'}" alt="home"/>
      </button>
    </a>
  </div>
};
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
