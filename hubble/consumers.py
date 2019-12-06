# chat/consumers.py
from asgiref.sync import async_to_sync
from channels.generic.websocket import WebsocketConsumer
from channels.auth import get_user, logout
import json
import os

from channels.consumer import SyncConsumer


class Room(SyncConsumer):
    def mytest(self, event):
        print('here we are')
        print(event['sender'])
        async_to_sync(self.channel_layer.send)(
            event['sender'],
            {
                'type': 'mytestreply',
                'sender': self.channel_name
            }
        )

    def mytestreply(self, msg):
        print('mytestreply here')

    def connect(self, event):
        print('Room connect')
        return super().connect(event)
        #self.send({
        #    "type": "websocket.accept",
        #})

    def receive(self, event):
        print('Room receive')
        return super().receive(event)
        #self.send({
        #    "type": "websocket.send",
        #    "text": event["text"],
        #})


class ChatConsumer(WebsocketConsumer):
    def connect(self):
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
                'type': 'mytest',
                'sender': self.channel_name
            }
        )

        # if not logged in special "AnonymousUser" is returned
        self.accept()

    def mytestreply(self, msg):
        print('mytestreply here 2')

    def disconnect(self, close_code):
        # Leave room group
        print('Disconnect')
        async_to_sync(self.channel_layer.group_discard)(
            self.room_group_name,
            self.channel_name
        )

    # Receive message from WebSocket
    def receive(self, text_data):
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
