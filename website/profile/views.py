import httplib as http

from framework import (
    get_current_user,
    get_user,
    must_be_logged_in,
    request
)
from framework.exceptions import HTTPError
from framework.forms.utils import sanitize

from website.models import ApiKey, User
from website.views import _render_nodes
from website.project.serializers import UserSerializer


def get_public_projects(uid=None, user=None):
    user = user or User.load(uid)
    return _render_nodes([
        node
        for node in user.node__contributed
        if node.category == 'project'
            and node.is_public
            and not node.is_registration
            and not node.is_deleted
    ])


def get_public_components(uid=None, user=None):
    user = user or User.load(uid)
    return _render_nodes([
        node
        for node in user.node__contributed
        if node.category != 'project'
            and node.is_public
            and not node.is_registration
            and not node.is_deleted
    ])


def _profile_view(uid=None):
    user = get_current_user()
    profile = get_user(id=uid or user)

    if not (uid or user):
        raise HTTPError(http.UNAUTHORIZED)

    if profile:
        profile_user_data = UserSerializer(profile).data
        return {
            'profile': profile_user_data,
            'user': {
                "can_edit": None,  # necessary for rendering nodes
                "is_profile": user == profile,
            },
        }
    raise HTTPError(http.NOT_FOUND)


def profile_view():
    return _profile_view()

def profile_view_id(uid):
    return _profile_view(uid)

@must_be_logged_in
def edit_profile(*args, **kwargs):
    user = kwargs['user']

    form = request.form

    response_data = {'response' : 'success'}
    if form.get('name') == 'fullname' and form.get('value', '').strip():
        user.fullname = sanitize(form['value'])
        user.save()
        response_data['name'] = user.fullname
    return response_data

def get_profile_summary(user_id, formatter='long'):

    user = User.load(user_id)
    return user.get_summary(formatter)

@must_be_logged_in
def profile_settings(*args, **kwargs):
    user = kwargs['user']
    return {
        'user_id' : user._primary_key,
    }


@must_be_logged_in
def profile_addons(*args, **kwargs):
    user = kwargs['user']
    return {
        'user_id' : user._primary_key,
    }


@must_be_logged_in
def get_keys(*args, **kwargs):
    user = kwargs['user']
    return {
        'keys' : [
            {
                'key' : key._id,
                'label' : key.label,
            }
            for key in user.api_keys
        ]
    }

@must_be_logged_in
def create_user_key(*args, **kwargs):

    # Generate key
    api_key = ApiKey(label=request.form['label'])
    api_key.save()

    # Append to user
    user = get_current_user()
    user.api_keys.append(api_key)
    user.save()

    # Return response
    return {
        'response' : 'success',
    }

@must_be_logged_in
def revoke_user_key(*args, **kwargs):

    # Load key
    api_key = ApiKey.load(request.form['key'])

    # Remove from user
    user = get_current_user()
    user.api_keys.remove(api_key)
    user.save()

    # Return response
    return {'response' : 'success'}

@must_be_logged_in
def user_key_history(*args, **kwargs):

    api_key = ApiKey.load(kwargs['kid'])
    return {
        'key' : api_key._id,
        'label' : api_key.label,
        'route' : '/settings',
        'logs' : [
            {
                'lid' : log._id,
                'nid' : log.node__logged[0]._id,
                'route' : log.node__logged[0].url,
            }
            for log in api_key.nodelog__created
        ]
    }
