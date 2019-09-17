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
    chatSocket = new WebSocket(
        'ws://' + window.location.host +
            '/ws/chat/' + roomName + '/');

    chatSocket.onmessage = function(e) {
        var data = JSON.parse(e.data);
        var message = data['message'];
        document.querySelector('#chat-log').value += (message + '\n');
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

chatsocket_start()

document.querySelector('#chat-message-input').focus();
document.querySelector('#chat-message-input').onkeyup = function(e) {
    if (e.keyCode === 13) {  // enter, return
        document.querySelector('#chat-message-submit').click();
    }
};

document.querySelector('#chat-message-submit').onclick = function(e) {
    var messageInputDom = document.querySelector('#chat-message-input');
    var message = messageInputDom.value;
    chatSocket.send(JSON.stringify({
        'type': 'chat-message',
        'message': message
    }));

    messageInputDom.value = '';
};

function logout_success_cb(content)
{
    Cookies.set('csrftoken', content['csrf']);

    // debugger;
    console.log('logout_success_cb');
    chatSocket.send(JSON.stringify({'type': 'logout'}));
    // window.location.href = "../";
}

function logout_cb(e) {
    console.log('here');
    $.ajax({
        type: "GET",
        url: "/chat/accounts/logout?next=/chat/login_landing/",
        success: logout_success_cb});
}

$("button[name='logout-submit']").click(logout_cb);
$("button[name='check-ajax']").click(check_ajax_cb);
