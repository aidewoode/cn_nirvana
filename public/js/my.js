
function activeLink() {
  var url = document.URL;

/* 需改进url 的匹配*/
  if( url == "http://localhost:9393/") {
    document.getElementById("home").className="active";
    document.getElementById("about").className="";
  }
  if(url == "http://localhost:9393/about") {
    document.getElementById("about").className="active";
    document.getElementById("home").className="";
     
  }
}

activeLink();
