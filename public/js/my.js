(function dropList() {
  var click = document.querySelector(".drop_down")
  var list = document.querySelector(".drop_menu");
  click.onclick = function(event) {
    list.classList.add("drop_active");
    event.stopPropagation();
  };

  document.body.onclick = function(event) {
    list.classList.remove("drop_active");
  };
  
})();


function replyOne(username) {
  var content = "<p><b class='atwho'>@"+username+"</b></p></br>" ;
  var input = document.querySelector(".simditor-body");
  input.innerHTML = content;
}

