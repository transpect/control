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
    + '  <form id="rename-form" action="/control/rename?file=' + file + '" method="POST">'
    + '    <input type="text" value="'+ file + '" id="rename-target" name="rename-target"/>'
    + '    <input type="hidden" name="svnurl" value="' + svnurl + '"/>'
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

let details = document.querySelector("details");
let summary = document.querySelector("summary");

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

// when the user moves the mouse away from the details element,
// perform the out-animation and delayed attribute-removal
// just like in the click handler
details.addEventListener("mouseleave", event => {
	details.classList.add("summary-closing");
	setTimeout(function() {
		details.removeAttribute("open");
		details.classList.remove("summary-closing");
	}, 500);
	details.setAttribute("open", "open");
});
Copy