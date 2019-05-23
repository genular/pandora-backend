# -*- coding: utf-8 -*-
# @Author: LogIN-
# @Date:   2019-05-16 12:07:46
# @Last Modified by:   LogIN-
# @Last Modified time: 2019-05-16 12:14:32
from flask import app, g, session, Blueprint

user_api = Blueprint('users', __name__)

@app.before_request
def before_request():
    try:
        g.user = User.query.filter_by(username=session['username']).first()
    except Exception:
        g.user = None