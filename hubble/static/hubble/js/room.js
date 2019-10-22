function csrfSafeMethod(method) {
  // these HTTP methods do not require CSRF protection
  return (/^(GET|HEAD|OPTIONS|TRACE)$/.test(method));
}

$.ajaxSetup({
  crossDomain: false, // obviates need for sameOrigin test
  beforeSend: function(xhr, settings) {
    if (!csrfSafeMethod(settings.type)) {
      xhr.setRequestHeader("X-CSRFToken", Cookies.get('csrftoken'));
    }
  }
});

var chatSocket = null;

function chatsocket_start()
{
  var url = window.location.href;
  var arr = url.split("/");
  var ws_proto = 'ws';
  if (arr[0] == 'https:')
    ws_proto = 'wss';
  
  chatSocket = new WebSocket(
    ws_proto + '://' + window.location.host +
      '/ws/chat/single_chat/');
  
  chatSocket.onmessage = function(e) {
    var data = JSON.parse(e.data);
    var message = data['message'];
    var lis = document.querySelector('#chat-log');
    if (lis != undefined)
      lis.value += (message + '\n');
  };
  
  chatSocket.onclose = function(e) {
    console.error('Chat socket closed unexpectedly');
  };
}

function chatsocket_restart()
{
  chatSocket.close();
  chatsocket_start()
}

// $("button[name='logout-submit']").click(logout_cb);
// $("button[name='check-ajax']").click(check_ajax_cb);
