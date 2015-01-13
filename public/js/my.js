(function dropList() {
  var click = document.querySelector(".drop_down");
  var list = document.querySelector(".drop_menu");
  click.onclick = function(event) {
    list.classList.add("drop_active");
    event.stopPropagation();
  };

  document.body.onclick = function(event) {
    list.classList.remove("drop_active");
  };
  
})();

(function changeCommentRoute() {
  var post = document.querySelector(".comment_submit");
  post.onclick = function() {
    var atwho = document.querySelector("a.simditor-mention");
    if(atwho.dataset.mention) {
      var attr = atwho.getAttribute("href");
      var postForm = document.querySelector("form.comment");
      postForm.setAttribute("action",postForm.getAttribute("action") + attr.slice(8));
    } 
    
  };
})();
