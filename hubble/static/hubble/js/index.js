function authbox_render(is_auth)
{
  var $authbox = $("div[name='authbox']");

  if (is_auth) {
    $authbox.html('<h2>IS AUTHENTICATED</h2>\
\
    <textarea id="chat-log" cols="100" rows="20"></textarea><br/>\
    <input id="chat-message-input" type="text" size="100"/><br/>\
    <input id="chat-message-submit" type="button" value="Send"/>\
\
<h2>Logout</h2>\
<button type="button" name="logout_submit">Logout</button>\
');
    $("button[name='logout_submit']").click(logout_cb);


    document.querySelector('#chat-message-input').focus();
    document.querySelector('#chat-message-input').onkeyup = function(e) {
      if (e.keyCode === 13) {  // enter, return
        document.querySelector('#chat-message-submit').click();
      }
    };

    document.querySelector('#chat-message-submit').onclick = function(e) {
      var messageInputDom = document.querySelector('#chat-message-input');
      var message = messageInputDom.value;
      console.log('onclick send');
      chatsocket_send(JSON.stringify({
        'type': 'chat-message',
        'message': message
      }));

      messageInputDom.value = '';
    };
  }
  else {
    $authbox.html('<h2>IS NOT AUTHENTICATED</h2>\
<h2>Login</h2>\
\
<form name="form_login" method="post" action="/chat/accounts/login/">\
<div>\
  <td><label for="id_username">Username:</label></td>\
  <td><input type="text" name="username" maxlength="254" autofocus required id="id_username" /></td>\
</div>\
<div>\
  <td><label for="id_password">Password:</label></td>\
  <td><input type="password" name="password" id="id_password" required /></td>\
</div>\
\
<div>\
  <button name="login_submit" type="button">Login</button>\
  <input type="hidden" name="next" value="" />\
</div>\
</form>');
    $("button[name='login_submit']").click(login_cb);
  }
}

authbox_render(user_is_auth);
if (user_is_auth) {
  chatsocket_start();
}
$("button[name='check-ajax']").click(check_ajax_cb);
