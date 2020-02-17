module namespace control-util = 'control-util';

(: 
 : prints the parent directory of a path , 
 : e.g. /home/parentdir/mydir/ => /home/parentdir/ 
 :)
declare function control-util:path-parent-dir( $path as xs:string ){
  string-join(
              remove(
                     tokenize($path, '/'),
                     count(tokenize($path, '/'))
                     ),
              '/')
};