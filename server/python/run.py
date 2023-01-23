# -*- coding: utf-8 -*-
# @Author: LogIN-
# @Date:   2019-05-16 09:26:07
# @Last Modified by:   LogIN-
# @Last Modified time: 2019-05-16 12:00:48
from source.app import create_app

if __name__ == '__main__':
	
	app = create_app()

	app.run(host=app.config["CONFIG"]["analysis_python"]["server"]["proxy_host"], 
		port=app.config["CONFIG"]["analysis_python"]["server"]["proxy_port"], 
		debug=app.config["CONFIG"]["analysis_python"]["server"]["debug"], 
		threaded=True)
