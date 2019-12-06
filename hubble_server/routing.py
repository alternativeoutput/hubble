# server/routing.py
from channels.auth import AuthMiddlewareStack
from channels.routing import (
    ProtocolTypeRouter, URLRouter, ChannelNameRouter)
import hubble.routing

application = ProtocolTypeRouter({
    # (http->django views is added by default)
    'websocket': AuthMiddlewareStack(
        URLRouter(
            hubble.routing.websocket_urlpatterns
        )
    ),

    'channel': ChannelNameRouter({
        'room': hubble.consumers.Room
    }),
})
