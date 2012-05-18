<?lassoscript

	library_once('/_libraries/app__app.lasso')
	library_once('/_models/_path_mod.lasso')
	library_once('/_views/_path_view.lasso')

	define _path_cont => type {

		parent _app_controller

		public main() => {

			.model('_pathname'=_path_mod)
			.view(_path_view)

			.view->template('/_templates/default.lasso')

			.view->title('_pathname - _appname')
			.view->mainbody('<p>This page is used to test the proper operation of your automatically generated scaffold. If you can read this page, and follow the provided links to your other pages, it means that the Arm framework, and your generated scaffold, is working properly. You may now begin development of your web application with the files in the directory ' + response_root + '. Note that until you do so, people visiting your website will see these pages, and not your content.</p>
					<p>You are free to display the images below in any web application based on the Arm framework. Thank you, for using Arm!</p>')

		}

	}

?>