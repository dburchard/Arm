<?lassoscript

	define _app_model => type { parent arm_model }

	define _app_view => type { parent arm_view

		public nav(-active::string='') => {
			local(o = string)
			protect => {
				local('links' = xml(include_raw('/_libraries/plugin_sitenav.lasso')))
			}
			if(#links->type != void->type) => {
				if(#links->getelementsbytagname('link')->length > 0) => {
					#o += '<ol class="nav">'
					iterate(#links->getelementsbytagname('link'), local(i)) => {
						local(n = #i->getelementsbytagname('label')->item(0)->nodevalue)
						local(v = #i->getelementsbytagname('href')->item(0)->nodevalue)
						#o += '<li>'
						if( string(#v)->split('/')->last == #active ) => {
							#o += #n
						else
							#o += '<a href="' + #v + '">' + #n + '</a>'
						}
						#o += '</li>'
					}
					#o += '</ol>'
				}
			}
			.'values'->insert('nav'=#o)
		} }

	define _app_controller => type { parent arm_controller

		public atend() => {
			.view->nav(-active=.name)
		} }

?>