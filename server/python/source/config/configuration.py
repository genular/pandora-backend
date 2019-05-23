# -*- coding: utf-8 -*-
# @Author: LogIN-
# @Date:   2019-05-16 11:15:13
# @Last Modified by:   LogIN-
# @Last Modified time: 2019-05-17 11:43:41
import yaml
import os

class Configuration(object):
    """
    Development environment configuration
    """
    with open('./config.yml', 'r') as configFile:
        config = yaml.load(configFile)

    CONFIG = config["default"]
    DEBUG = True
    TESTING = False
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY')
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL')

app_config = Configuration