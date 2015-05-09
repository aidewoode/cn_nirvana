// a function to control drop menu style
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

// a function to change comment from route
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

// to check user's input in sign in page
function mycheckInput(form) {
  var reallyTrue = [];
  for (var i = 0; i < form.elements.length - 1; i++) {
    switch (i) {
      case 0:
        var element = form.elements[0];
        var input = element.value;
        if (input === "") {
          element.classList.add("error");
          element.setAttribute("placeholder", "ID 不能为空");
          reallyTrue.push(false);
        } else if (input.length > 25){
          element.classList.add("error");
          element.setAttribute("placeholder", "长度不能大于25个字符");
          reallyTrue.push(false);
        } else {
          var legalId = /^\w+$/;
          if (legalId.test(input)) {
            reallyTrue.push(true);
            element.classList.remove("error");
            element.setAttribute("placeholder", "只能为数字和字母的组合");
          } else {
            element.classList.add("error");
            element.setAttribute("placeholder", "只能为数字和字母的组合");
            reallyTrue.push(false);
          }
        }
        break;
      case 1:
        var element = form.elements[1];
        var input = element.value;
        if (input === "") {
          element.classList.add("error");
          element.setAttribute("placeholder", "Email 不能为空");
          reallyTrue.push(false);
        }else {
          var legalEmail = /^[a-z0-9](\w|\.|-)*@([a-z0-9]+-?[a-z0-9]+\.){1,3}[a-z]{2,4}$/i;
          if (legalEmail.test(input)) {
            reallyTrue.push(true);
            element.classList.remove("error");
            element.setAttribute("placeholder", "注册后不能更改");
          } else {
            element.classList.add("error");
            element.setAttribute("placeholder", "Email 格式不正确");
            reallyTrue.push(false);
          }
        }

        break;
      case 2:
        var element = form.elements[2];
        var input = element.value;
        if (input === "") {
          element.classList.add("error");
          element.setAttribute("placeholder", "密码不能为空");
          reallyTrue.push(false);
        }else {
          if (input.length >= 6) {
            reallyTrue.push(true);
            element.classList.remove("error");
            element.removeAttribute("placeholder");
          } else {
            element.classList.add("error");
            element.setAttribute("placeholder", "密码最少6 位");
            reallyTrue.push(false);
          }
        }
        break;
      case 3:
        var element = form.elements[3];
        var input = element.value;
        if (input === "") {
          element.classList.add("error");
          element.setAttribute("placeholder", "密码不能为空");
          reallyTrue.push(false);
        }else {
          if (input === form.elements[2].value) {
            reallyTrue.push(true);
            element.classList.remove("error");
            element.removeAttribute("placeholder");
          } else {
            element.classList.add("error");
            element.setAttribute("placeholder", "密码不相同");
            reallyTrue.push(false);
          }
        }

        break;
    }

  }
    if (reallyTrue.every(function(item, index, array) {
      return item;
    })) {
      return true;
    } else {
      form.reset();
      return false;
    }
}


(function formSubmit() {
  var form = document.querySelectorAll("form.submit_form");
  var input = document.querySelectorAll("input.submit_form");
  if (form.length === 1) {
    if (form[0].classList[0] === "signup_form") {
      var changeSubmitButton = function(event) {
        input[0].disabled = true;
        input[0].classList.add("disable");
        if (!mycheckInput(form[0])) {
          input[0].disabled = false;
          input[0].classList.remove("disable");
          event.preventDefault();
          form[0].removeEventListener("submit", changeSubmitButton,false);
          form[0].addEventListener("submit", changeSubmitButton, false);
        }
      };
      form[0].addEventListener("submit", changeSubmitButton, false);

    } else {
      form[0].onsubmit = function() {
        input[0].disabled = true;
        input[0].classList.add("disable");
      };
    }
  } else {
    for (var i = 0; i < form.length; i++) {
      (function(k) {
        form[k].onsubmit = function() {
          input[k].disabled = true;
          input[k].classList.add("disable");
        }; 
      })(i);
    }
    
  }
    
})();

// moment.js function

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

