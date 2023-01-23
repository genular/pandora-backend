# -*- coding: utf-8 -*-
# @Author: LogIN-
# @Date:   2019-05-16 11:45:27
# @Last Modified by:   LogIN-
# @Last Modified time: 2019-05-17 11:44:10
from flask import Flask

from source.config.configuration import app_config

# import user_api blueprint
# from source.middlewares.authorization import user_api as user_blueprint # add this line



def create_app():
    """
    Create app
    """

    # app initiliazation
    app = Flask(__name__)
    app.debug = True
    app.config.from_object(app_config)

    @app.route('/', methods=['GET'])
    
    def index():
        """
        example endpoint
        """
        return 'Congratulations! Your first endpoint is working'

    return app
