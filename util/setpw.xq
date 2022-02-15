module namespace page = 'http://basex.org/examples/web-page';
import module namespace request = "http://exquery.org/ns/request";
declare
%rest:path("/setpw")
%rest:form-param("oldpw","{$oldpw}")
%rest:form-param("newpw","{$newpw}")
%rest:form-param("newpwre","{$newpwre}")
function page:host($oldpw as xs:string?, $newpw as xs:string?, $newpwre as xs:string?) {

let $credentials := request:header("Authorization")
                    => substring(6)
                    => xs:base64Binary()
                    => bin:decode-string()
                    => tokenize(':'),
    $username := $credentials[1],
    $password := $credentials[2],

    (: checks if the user is logged in and provided the correct old password :)
    $iscorrectuser :=
      if ($password = $oldpw)
      then proc:execute(
             'htpasswd', ('-vb', '/etc/svn/default.htpasswd', $username, $password))
      else element error {"The input old passwort is not correct", element code {1}},
    (: tries to set the new password and returns an error message if it fails :)
    $result :=
      if ($iscorrectuser/code = 0)
      then proc:execute(
             'htpasswd', ('-b', '/etc/svn/default.htpasswd', $username, $newpw))/error
      else $iscorrectuser

return $result

};