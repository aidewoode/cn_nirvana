(function dropList() {
  var click = document.querySelector(".drop_down");
  var list = document.querySelector(".drop_menu");
  if (click) {
    click.onclick = function(event) {
      list.classList.add("drop_active");
      event.stopPropagation();
    };

    document.body.onclick = function(event) {
      list.classList.remove("drop_active");
    };
  
}})();

(function changeCommentRoute() {
  var post = document.querySelector(".comment_submit");
  if (post) {
    post.onclick = function() {
      var atwho = document.querySelector("a.simditor-mention");
      if(atwho.dataset.mention) {
        var attr = atwho.getAttribute("href");
        var postForm = document.querySelector("form.comment");
        postForm.setAttribute("action",postForm.getAttribute("action") + attr.slice(8));
      } 

    };
}})();

(function formSubmit() {
  var form = document.querySelector("form.submit_form");
  var input = document.querySelector("input.submit_form");
  if (form) {
    form.onsubmit = function() {
      input.setAttribute("disabled", "disabled");
      input.classList.add("disable");
    };
  } 
})();

// moment.js function
//
(function prettyTime() {
  var createAt = document.querySelectorAll("div.data_time");
  if (createAt) {
  for (var i=0; i < createAt.length ; i++) {
    if (createAt[i].dataset.time) {
      var time = createAt[i].dataset.time;
      var formatTime = moment(time).format("L");
      createAt[i].innerHTML = formatTime;
    }
      
  }
}})();

(function timeAgo() {
  var createAt = document.querySelectorAll("span.data_time_ago");
  if (createAt) {
    for (var i=0; i < createAt.length; i++) {
      if (createAt[i].dataset.time) {
        var time = createAt[i].dataset.time;
        var formatTime = moment(time).startOf("hourse").fromNow();
        createAt[i].innerHTML = formatTime;
      }
    }
  }
})();
