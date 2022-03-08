/* 
 * Functions
 */

function reveal(id) {
  document.getElementById(id).style.visibility  = "visible"; 
}
function hide(id) {
  document.getElementById(id).style.visibility  = "hidden"; 
}
function createRenameForm(svnurl, file, controlPath) {
  const id = 'direntry-' + file
  const form = '<div id="rename-form-wrapper">'
    + '  <form id="rename-form" action="/control/rename" method="POST">'
    + '    <input type="text" value="'+ file + '" id="target" name="target"/>'
    + '    <input type="hidden" name="svnurl" value="' + svnurl + '"/>'
    + '    <input type="hidden" name="file" value="' + file + '"/>'
    + '    <button class="btn ok" value="ok">'
    + '      OK'
    + '      <span class="spacer"/><img class="small-icon" src="' + controlPath + '/static/icons/open-iconic/svg/check.svg" alt="ok"/>'
    + '    </button>'
    + '  </form>'
    + '  <button class="btn cancel" value="cancel" onclick="cancelRenameForm(\'' + svnurl + '\', \'' + file + '\', \'' + controlPath + '\')">'
    + '    Cancel'
    + '    <span class="spacer"/><img class="small-icon" src="' + controlPath + '/static/icons/open-iconic/svg/ban.svg" alt="cancel"/>'
    + '  </button>'
    + '</div>'
    const formWrapper = document.createElement("div");
    formWrapper.setAttribute("id", "renameform-" + file);
    anchor = document.getElementById(id);
    anchor.replaceWith( formWrapper );
    formWrapper.innerHTML = form;
}
function setUserGroupSelection(username, selectId){
  console.log("http://localhost:9081//basex/control/user/getgroups?username=" + username);
  fetch("http://localhost:9081//basex/control/user/getgroups?username=" + username)
  .then(response => {return response.body})
  .then(stream => {return new Response(stream, { headers: { "Content-Type": "text/html" } }).text()})
  .then(result => {
    groupoptions = document.querySelectorAll("#" + selectId + " option");
    parser = new DOMParser();
    xmlDoc = parser.parseFromString(result,"text/xml");
    items = xmlDoc.getElementsByTagName("group");
    for (let sel of groupoptions) {
      sel.selected = false;
    }
    for (let item of items) {
      document.querySelector("#" + selectId + " option[value='" + item.innerHTML + "']").selected = true;
    }
  })
}
function setGroupSelection(groupname, inputId){
  console.log("http://localhost:9081//basex/control/group/getglob?groupname=" + groupname);
  fetch("http://localhost:9081//basex/control/group/getglob?groupname=" + groupname)
  .then(response => {return response.body})
  .then(stream => {return new Response(stream, { headers: { "Content-Type": "text/html" } }).text()})
  .then(result => {
    grouprepo = document.querySelectorAll("#" + inputId + " text");
    parser = new DOMParser();
    xmlDoc = parser.parseFromString(result,"text/xml");
    repo = xmlDoc.getElementsByTagName("repo");
    grouprepo.value = repo;
  })
}

function cancelRenameForm(svnurl, file, controlPath) {
  const id = "renameform-" + file;
  const txt = document.createTextNode(file);
  var formWrapper = document.getElementById(id);
  var anchor = document.createElement("a");
  anchor.setAttribute("id", "direntry-" + file);
  anchor.setAttribute("href", controlPath + "?svnurl=" + svnurl);
  anchor.appendChild(txt);
  formWrapper.replaceWith( anchor );
}
/* 
 * Register event listener
 */
window.onload = function() {
  var details = document.querySelector("details");
  var summary = document.querySelector("summary");
  var userselect = document.querySelector("#userselect");
  var groupselect = document.querySelector("#groupselect");
  
  if (summary !== null) {
    summary.addEventListener("click", function(event) {
  	// first a guard clause: don't do anything 
  	// if we're already in the middle of closing the menu.
  	if (details.classList.contains("summary-closing")) {
  		return;
  	}
  	// but, if the menu is open ...
  	if (details.open) {
  		// prevent default to avoid immediate removal of "open" attribute
  		event.preventDefault();
  		// add a CSS class that contains the animating-out code
  		details.classList.add("summary-closing");
  		// when enough time has passed (in this case, 500 milliseconds),
  		// remove both the "open" attribute, and the "summary-closing" CSS 
  		setTimeout(function() {
  			details.removeAttribute("open");
  			details.classList.remove("summary-closing");
  		}, 500);
  	}
    });
  
  
    // when user hovers over the summary element, 
    // add the open attribute to the details element
    summary.addEventListener("mouseenter", event => {
    	details.setAttribute("open", "open");
    });
  }
    // when the user moves the mouse away from the details element,
    // perform the out-animation and delayed attribute-removal
    // just like in the click handler
  if (details !== null) {
    details.addEventListener("mouseleave", event => {
    	details.classList.add("summary-closing");
    	setTimeout(function() {
    		details.removeAttribute("open");
    		details.classList.remove("summary-closing");
    	}, 500);
    	details.setAttribute("open", "open");
    });
  }
  if (userselect !== null) {
    userselect.addEventListener("change", event => {
      setUserGroupSelection(userselect
        .selectedOptions[0].value, "groups")
    });
    setUserGroupSelection(userselect
      .selectedOptions[0].value, "groups")
  }
  if (groupselect !== null) {
    groupselect.addEventListener("change", event => {
      setGroupSelection(groupselect
        .selectedOptions[0].value, "repoglob")
    });
    setGroupSelection(groupselect
      .selectedOptions[0].value, "repoglob")
  }
}