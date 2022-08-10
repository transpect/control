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
    + '  <form id="rename-form" action="control/rename" method="POST">'
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

function closebox(){
  var ids = ['infobox']
  for (let i = 0; i <  ids.length; i++)
  {hide(ids[i])}
}

function showLogForm(svnurl, file, controlPath) {
  fetch('control/getsvnlog?svnurl=' + svnurl + '&file=' + file, {credentials: 'include'})
    .then(response => response.text())
    .then(data => fillInfoBox(data));
}

function showInfoForm(svnurl, file, controlPath) {
  fetch('control/getsvninfo?svnurl=' + svnurl + '&file=' + file, {credentials: 'include'})
    .then(response => response.text())
    .then(data => fillInfoBox(data));
}

function fillInfoBox(content)
{
  console.log('fill');
  document.getElementById('infobox').getElementsByClassName('content')[0].innerHTML = content;
  reveal('infobox')
}

function setUserGroupSelection(username, selectId){
  fetch("user/getgroups?username=" + username)
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
  fetch("group/getglob?groupname=" + groupname)
  .then(response => {return response.body})
  .then(stream => {return new Response(stream, { headers: { "Content-Type": "text/html" } }).text()})
  .then(result => {
    grouprepo = document.querySelectorAll("#" + inputId)[0];
    parser = new DOMParser();
    xmlDoc = parser.parseFromString(result,"text/xml");
    repo = xmlDoc.getElementsByTagName("repo");
    grouprepo.value = repo[0].innerHTML;
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

function addEventToSummary(summary) {
  var details = summary.parentElement;
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
function addEventToDetail(detail) {
  detail.addEventListener("mouseleave", event => {
    	detail.classList.add("summary-closing");
    	setTimeout(function() {
    		detail.removeAttribute("open");
    		detail.classList.remove("summary-closing");
    	}, 1);
    	detail.setAttribute("open", "open");
    });
}

function addEventToXpath(p) {
  p.setAttribute('title', 'click to copy');
  p.addEventListener("click", event => {
    	navigator.clipboard.writeText(event.target.innerText);
    });
}

/* 
 * Register event listener
 */
window.onload = function() {
  var details = document.querySelectorAll("details.autocollapse");
  var summaries = document.querySelectorAll("details.autocollapse > summary");
  var userselect = document.querySelector("#userselect");
  var groupselect = document.querySelector("#groupselect");
  var xpaths = document.querySelectorAll(".search-xpath");
  
  for (let summary of summaries){
    addEventToSummary(summary)
  }
 
  for (let detail of details){
    addEventToDetail(detail)
  }
  
  for (let xpath of xpaths){
    addEventToXpath(xpath)
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
        .selectedOptions[0].value, "grouprepo")
    });
    setGroupSelection(groupselect
      .selectedOptions[0].value, "grouprepo")
  }
  document.body.addEventListener("click", function(event) {
    var closestA = event.target.closest('div.infobox');
    if (closestA || document.getElementById('infobox').style.visibility == 'hidden') {
      return;
    } else {
      hide('infobox')
    }
  });
}