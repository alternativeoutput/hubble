import json
from django.shortcuts import render
from django.utils.safestring import mark_safe
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse
from django.middleware.csrf import get_token
from time import ctime


def index(request):
    return render(request, 'hubble/index.html', {'date_cur': ctime()})


def room(request, room_name):
    return render(request, 'hubble/room.html', {
        'room_name_json': mark_safe(json.dumps(room_name))
    })


def check_ajax(request):
    print(request.user.is_authenticated)
    return JsonResponse({'is_auth': request.user.is_authenticated})


# @login_required
def login_landing(request):
    csrf = get_token(request)
    return JsonResponse({'csrf': csrf})
