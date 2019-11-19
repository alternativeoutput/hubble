import json
from django.shortcuts import render
from django.utils.safestring import mark_safe
from django.http import JsonResponse
from time import ctime
from django.contrib.auth import authenticate, login, logout
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.csrf import ensure_csrf_cookie


def index(request):
    return render(request, 'hubble/index.html', {'date_cur': ctime()})


def room(request, room_name):
    return render(request, 'hubble/room.html', {
        'room_name_json': mark_safe(json.dumps(room_name))
    })


def check_ajax(request):
    print(request.user.is_authenticated)
    return JsonResponse({'is_auth': request.user.is_authenticated})


def proof_view(request):
    if hasattr(request, 'user'):
        if hasattr(request.user, 'is_authenticated'):
            return JsonResponse({'username': request.user.username,
                                 'is_auth': request.user.is_authenticated})
    return JsonResponse({'username': 'anonymous', 'is_auth': False})


@csrf_exempt
@ensure_csrf_cookie
def login_view(request):
    username = request.POST['username']
    password = request.POST['password']
    user = authenticate(request, username=username, password=password)
    if user is not None:
        login(request, user)
        # Redirect to a success page.
        return JsonResponse({'username': username, 'is_auth': True})
    else:
        return JsonResponse({'is_auth': False})


def logout_view(request):
    print('My Logout')
    logout(request)
    return JsonResponse({'success': True})
