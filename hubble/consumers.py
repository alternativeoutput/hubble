# chat/consumers.py
from asgiref.sync import async_to_sync
from channels.generic.websocket import WebsocketConsumer
from channels.auth import get_user, logout
import json
import os

from channels.consumer import SyncConsumer


class Room(SyncConsumer):
    def __init__(self, *args, **kwargs):
        print('Room::__init__')
        self.rooms = {}
        super().__init__(*args, **kwargs)

    def table_join(self, event):
        if event['room_name'] not in self.rooms:
            self.rooms[event['room_name']] = {
                'group_name': event['room_name'],
                'users': {}
            }

            # Join room group
            async_to_sync(self.channel_layer.group_add)(
                'chat_%s' % event['room_name'],
                self.channel_name
            )
        room = self.rooms[event['room_name']]

        if event['login'] not in room['users']:
            room['users'][event['login']] = {
                'login': event['login'],
                'channel': event['sender']
                }
            msg = 'joined'
        else:
            msg = 'rejoined'

        user = room['users'][event['login']]
        user['channel'] = event['sender']

        for user_key in room['users']:
            user_cur = room['users'][user_key]
            if user_cur['login'] == event['login']:
                continue
            # Send message to room group
            async_to_sync(self.channel_layer.send)(
                user_cur['channel'],
                {
                    'type': 'chat_message',
                    'username': 'Bot',
                    'message': ('User ' + user['login'] +
                                ' %s stercorario' % msg)
                }
            )

    def table_leave(self, event):
        print('table_leave')
        print(event)

        # 'room_name': self.room_name,
        # 'login': self.user.username
        if event['room_name'] not in self.rooms:
            return
        room = self.rooms[event['room_name']]
        if event['login'] not in room['users']:
            return
        user_leaving = room['users'].pop(
            event['login'])

        users = room['users']
        for user_key in users:
            user_cur = room['users'][user_key]

            # Send message to room group
            async_to_sync(self.channel_layer.send)(
                user_cur['channel'],
                {
                    'type': 'chat_message',
                    'username': 'Bot',
                    'message': (
                        'User ' + user_leaving['login'] +
                        ' leave stercorario')
                }
            )
        if len(users.keys()) > 0:
            return

        async_to_sync(self.channel_layer.group_discard)(
            'chat_%s' % event['room_name'],
            self.channel_name
        )
        self.rooms.pop(event['room_name'])
        print('table_leave: end')

    def chat_message(self, event):
        pass

    def connect(self, event):
        print('Room connect')
        print(event)
        return super().connect(event)

    def receive(self, event):
        print('Room receive')
        return super().receive(event)


class ChatConsumer(WebsocketConsumer):
    def connect(self):
        print("connect:begin")
        print("CHNAME: %s" % self.channel_name)

        self.room_name = self.scope['url_route']['kwargs']['room_name']
        self.room_group_name = 'chat_%s' % self.room_name

        self.user = self.scope["user"]
        if not self.user.is_authenticated:
            print('mop: not authorized')
            self.close()

        # Join room group
        async_to_sync(self.channel_layer.group_add)(
            self.room_group_name,
            self.channel_name
        )

        async_to_sync(self.channel_layer.send)(
            'room',
            {
                'type': 'table_join',
                'login': self.user.username,
                'room_name': self.room_name,
                'sender': self.channel_name
            }
        )

        # if not logged in special "AnonymousUser" is returned
        self.accept()

    def disconnect(self, close_code):
        # Leave room group
        print('Disconnect')
        print(self)

        async_to_sync(self.channel_layer.group_discard)(
            self.room_group_name,
            self.channel_name
        )

    # Receive message from WebSocket
    def receive(self, text_data):
        print('receive')
        # print(text_data)
        # print(self.user.username)
        text_data_json = json.loads(text_data)
        if text_data_json['type'] == 'chat-message':
            message = text_data_json['message']
            # user = async_to_sync(get_user)(self.scope)

            # Send message to room group
            async_to_sync(self.channel_layer.group_send)(
                self.room_group_name,
                {
                    'type': 'chat_message',
                    'username': self.user.username,
                    # 'username': user.username,
                    'message': message
                }
            )
        elif text_data_json['type'] == 'logout':
            print('logout')

            async_to_sync(self.channel_layer.send)(
                'room',
                {
                    'type': 'table_leave',
                    'room_name': self.room_name,
                    'login': self.user.username
                }
            )
            self.disconnect(0)
            async_to_sync(logout)(self.scope)

    # Receive message from room group
    def chat_message(self, event):
        user = async_to_sync(get_user)(self.scope)
        print("IS AUTH" if user.is_authenticated else
              "NOT AUTH")
        if not user.is_authenticated:
            # to add a code use code=<value> as close parameter
            self.close()
            return
        message = event['message']
        user = event['username']

        # Send message to WebSocket
        self.send(text_data=json.dumps({
            'username': user,
            'message': message
        }))
