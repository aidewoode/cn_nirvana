/* 控制导航栏样式*/
function activeLink() {
  var url = document.URL;
  var lasturl = url.slice(url.lastIndexOf("/")+1);

  if(lasturl == "") {
    var node = document.getElementById("home");
    node.parentNode.childNodes.className="";
    node.className="active";
  } else {
    var node = document.getElementById(lasturl);
    node.parentNode.childNodes.className="";
    node.className="active";
  } 

}

function getElementByClass(classname) {
  var element = document.getElementsByTagName("*");
  var s;
  for(var i= 0; i<element.length; i++){
    if(element[i].className == classname) {
        s = element[i];
        return s;
    }
  }
}

function replyOne(username) {
  var content = "<p><b class='atwho'>@"+username+"</b></p></br>" ;
  var input = getElementByClass("simditor-body");
  input.innerHTML = content;
}
