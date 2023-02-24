import module namespace svn             = 'io.transpect.basex.extensions.subversion.XSvnApi';
import module namespace control         = 'http://transpect.io/control' at '../control/control.xq';
import module namespace control-i18n    = 'http://transpect.io/control/util/control-i18n' at '../control/util/control-i18n.xq';
import module namespace control-util    = 'http://transpect.io/control/util/control-util' at '../control/util/control-util.xq';
import module namespace control-widgets = 'http://transpect.io/control/util/control-widgets' at '../control/util/control-widgets.xq';
import module namespace control-backend = 'http://transpect.io/control-backend' at '../control-backend/control-backend.xqm';

let $result := control-util:writeindextofile(control-util:create-path-index($control:svnurlhierarchy, 'root', 'root', $control:svnurlhierarchy,''))
return db:create('INDEX', 'basex/webapp/control/index.xml')
