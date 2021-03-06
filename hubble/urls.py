# chat/urls.py
from django.conf.urls import url
from django.urls import path, include

from . import views

urlpatterns = [
    url(r'^$', views.index, name='index'),
    url(r'^proof/', views.proof_view, name='proof'),
    url(r'^login/', views.login_view, name='login_landing'),
    url(r'^logout/', views.logout_view, name='logout'),
    url(r'^check_ajax/', views.check_ajax, name='check_ajax'),
#    url(r'^(?P<room_name>[^/]+)/$', views.room, name='room'),
    path('accounts/', include('django.contrib.auth.urls'))
]
