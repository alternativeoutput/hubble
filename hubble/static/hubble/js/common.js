$.ajaxSetup({
  crossDomain: false, // obviates need for sameOrigin test
  beforeSend: function(xhr, settings) {
    if (!csrfSafeMethod(settings.type)) {
      xhr.setRequestHeader("X-CSRFToken", Cookies.get('csrftoken'));
      xhr.setRequestHeader("x-csrf-token", "fetch");
    }
  }
});

function login_success_cb(content, y, xhr)
{
  if (typeof authbox_render != undefined)
    authbox_render(content.is_auth);
 }

function csrfSafeMethod(method) {
  // these HTTP methods do not require CSRF protection
  return (/^(GET|HEAD|OPTIONS|TRACE)$/.test(method));
}

function logout_success_cb(content, y, xhr)
{
  if (typeof authbox_render != undefined)
    authbox_render(false);
}

function logout_cb(e) {
  console.log('logout_cb common');
  $("div[name='check-ajax-res']").html("");
  $.ajax({
    type: "GET",
    url: "logout/",
    success: logout_success_cb});

  if (typeof(chatSocket) != 'undefined') {
    chatSocket.send(JSON.stringify({
      'type': 'logout'
    }));
  }
}

function login_cb(e) {
  var $form = $("form[name='form_login']");
  var user = $form.find("input[name='username']").val();
  var passwd = $form.find("input[name='password']").val();

  $("div[name='check-ajax-res']").html("");
  $.ajax({
    type: "POST",
    cache: 'FALSE',
    error: function() {
      console.log('error fired');
    },
    statusCode: {
      302: function() {
        console.log( "page redir" );
        return(false);
      }
    },
    url: "login/",
    data: {username: user,
           password: passwd},
    success: login_success_cb
  });
}

function check_ajax_success_cb(content, b, c) {
  console.log("check_ajax_success_cb");
  $("div[name='check-ajax-res']").html(
    content.is_auth == true ? "IS AUTH" : "IS NOT AUTH");
}

function check_ajax_cb(e) {
  $("div[name='check-ajax-res']").html("TO BE SET");
  var $form = $("form[name='form-check-ajax']");
  $.ajax({
    type: "POST",
    cache: 'FALSE',
    error: function() {
      console.log('error fired');
    },
    statusCode: {
      302: function() {
        console.log( "page redir" );
        return(false);
      }
    },
    url: "/chat/check_ajax/",
    success: check_ajax_success_cb
  });
}
