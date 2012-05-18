<?lassoscript

	library_once('/_libraries/app__app.lasso')
	library_once('/_models/_path_mod.lasso')
	library_once('/_views/_path_view.lasso')

	define _path_cont => type {

		parent _app_controller

		public main()::void => {

			.model('_pathname'=_path_mod)
			.view(_path_view)

			.view->template('/_templates/default.lasso')

			.view->title('_pathname - _appname')

			arm_request(
					-method='GET',
					-route='/') => {
				if(.session_var('crudalert') == 3) => {
					.view->alert(9)
				}
				.session_removevar('crudalert')
				.view->list(.model('_pathname')->list, -keyfield=.model('_pathname')->keyfield)
			}

			arm_request(
					-method='GET',
					-route='/new') => { .view->form(.model('_pathname')->columns, -keyfield=.model('_pathname')->keyfield) }

			arm_request(
					-method='POST',
					-route='/') => {

				local(o = .model('_pathname')->create(arm_request->params))
				if(#o) => {
					.session_var('crudalert'=1)
					redirect_url('/' + arm_request->path + '/' + encode_url(#o))
				else
					.view->alert(10, error_msg + ' (' + error_code + ')')
					.view->form(.model('_pathname')->columns(arm_request->params), -keyfield=.model('_pathname')->keyfield)
				}
			}

			arm_request(
					-method='GET',
					-route='/!new') => {
				if(.session_var('crudalert') == 2) => {
					.view->alert(8)
				else(.session_var('crudalert') == 1)
					.view->alert(7)
				}
				.session_removevar('crudalert')
				.view->detail(.model('_pathname')->show(arm_request->route(1)), -keyfield=.model('_pathname')->keyfield)
			}

			arm_request(
					-method='GET',
					-route='/:any/edit') => { .view->form(.model('_pathname')->show(arm_request->route(1)), -keyfield=.model('_pathname')->keyfield) }

			arm_request(
					-method='PUT',
					-route='/:any') => {

				local(o = .model('_pathname')->update(arm_request->params, -key=arm_request->route(1)))
				if(#o) => {
					.session_var('crudalert'=2)
					redirect_url('/' + arm_request->path + '/' + encode_url(arm_request->route(1)))
				else
					.view->alert(11, error_msg + ' (' + error_code + ')')
					.view->form(.model('_pathname')->show(arm_request->route(1)), -keyfield=.model('_pathname')->keyfield)
				}

			}

			arm_request(
					-method='DELETE',
					-route='/:any') => {

				local(o = .model('_pathname')->delete(arm_request->route(1)))
				if(#o) => {
					.session_var('crudalert'=3)
					redirect_url('/' + arm_request->path)
				else
					.view->alert(12, error_msg + ' (' + error_code + ')')
					.view->form(.model('_pathname')->show(arm_request->route(1)), -keyfield=.model('_pathname')->keyfield)
				}

			}

		}

	}

?>



