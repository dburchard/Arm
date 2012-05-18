<?lassoscript

	/*
	 * Arm Framework b3.0
	 *
	 * Copyright (c) 2012, Douglas Burchard
	 * Arm, and its accompanying files, are released under three
	 * licenses: MIT, BSD, and LGPL. You may pick the license 
	 * that best suits your development needs. See the LICENSE 
	 * file which accompanied the ArmSetup assistant for more 
	 * information.
	 *
	 * Date: May 17 2012
	 */

	// Patches the session_end method, for Lasso versions 9.1.4 and below
	// Code originally from Kyle Jessup on LassoTalk, March 15, 2012
	local(p,s,t,q) = lasso_version(-lassoversion)->split('.')
	if(
		integer(#p) < 9 ||
		(integer(#p) == 9 && integer(#s) < 1) ||
		(integer(#p) == 9 && integer(#s) == 1 && integer(#t) <= 4)
	) => {
		define sqlite_session_driver_impl->kill(id::string) => {
			.map->remove(#id)
			.delete->insert(#id);
			local(sql = sqlite_db(sys_databasespath + .'db'))
			#sql->doWithClose => {
				#sql->executeNow('BEGIN EXCLUSIVE TRANSACTION')
				with del in .delete
				do {
					#sql->executeNow('DELETE FROM sessions WHERE session_key = \'' + #del->encodeSQL92 + '\'');
				}
				.delete = array
				#sql->executeNow('COMMIT TRANSACTION')
			}		
		}
	}

	define arm => type {

		data protected defaultpath::string
		data protected unknownpath::string

		public oncreate(-defaultpath::string,-unknownpath::string,-dontcleanhtml::boolean=false) => {
			.'defaultpath' = #defaultpath
			.'unknownpath' = #unknownpath
			arm_data('nocleanup'=#dontcleanhtml)
		}

		public asstring()::string => {
			local('controller' = string)
			local('trypath' = ('/_controllers/' + string_replaceregexp(string_lowercase(string(arm_request->path)), -find='[^A-Za-z0-9-_]', -replace='') + '_cont.lasso'))
			protect => {
				local('trypathresults' = include_raw(#trypath))
			}
			if(string(#trypathresults)->length > (0)) => {
				#controller = #trypath

			else(string(arm_request->path)->length == (0))
				#controller = (.'defaultpath')

			else
				#controller = (.'unknownpath')
			}
			library_once(#controller)
			#controller->removetrailing('.lasso')
			#controller->removeleading('/_controllers/')
			arm_request->path(string_removetrailing(#controller, -pattern='_cont'))
			local('ref' = escape_tag(#controller)->invoke)
			return(#ref->run)
		}
	}

	define arm_data(package::pair)::void => {
		if(var('_arm_pagedata')->type != map->type) => {
			var('_arm_pagedata') = map
		}
		$_arm_pagedata->insert(#package)
	}

	define arm_data(key::string)::any => {
		if(var('_arm_pagedata')->type == map->type) => {
			return $_arm_pagedata->find(#key)
		}
	}

	define arm_request => type {

		data private pathroute::string = '_q'

		public oncreate(
			-method::string='',
			-route::string='',
			-params::array=array,
			-noextraparams::boolean=false
		)::any => {
			.Instantiatstorage
			
			if(#method->size || #route->size || #params->size || #noextraparams) => {

				local(o = true)

				// Check method
				if(#method->size > 0 && #method != .method) => { #o = false }

				// Check route
				if(#route == '') => { #route = .route }
				local('actualroute' = .route)
				#actualroute->removeleading('/')
				#actualroute->removetrailing('/')
				#actualroute = #actualroute->split('/')
				local(testroute = string(#route))
				#testroute->removeleading('/')
				#testroute->removetrailing('/')
				#testroute = #testroute->split('/')
				iterate(#testroute) => {
					local('test' = string(loop_value))
					local('testresult' = true)
					local('bang' = false)
					if(#test->beginswith('!')) => {
						#test->removeleading('!')
						#bang=true
					}
					if(#actualroute->size < loop_count) => {
						if(string_removeleading(#test, -pattern=':') != 'any') => {
							#testresult = false
						}
					else(#test->beginswith(':'))
						if(#bang && .matchtype(#actualroute->get(loop_count), -isa=string_removeleading(#test, -pattern=':'))) => {
							#testresult = false
						else(!#bang && not .matchtype(#actualroute->get(loop_count), -isa=string_removeleading(#test, -pattern=':')))
							#testresult = false
						}
					else(not #test->beginswith(':'))
						if(#bang && #test == #actualroute->get(loop_count)) => {
							#testresult = false
						else(!#bang && #test != #actualroute->get(loop_count))
							#testresult = false
						}
					}
					if(!#testresult) => {
						#o = false
						loop_abort
					}
				}
				if(#actualroute->size > #testroute->size) => { #o = false }

				// Check params
				iterate(#params, local('test')) => {
					if(#test->type != pair->type && .params !>> string(#test)) => {
						#o = false

					else(#test->type == pair->type)
						iterate(.params->find(#test->name), local('actual')) => {
							if(#test->value->type == regexp(-find='')->type) => {
								#test->value->input = string(#actual->value)
								if(not #test->value->find) => {
									#o = false

								}
							else
								if(#test->value != #actual->value) => {
									#o = false

								}
							}
						}
					}
				}



				if(#params->size > 0 && #noextraparams) => {
					iterate(#params, local(c)) => {
						if(#c->type == pair->type) => {
							if(.params !>> #c->name) => {
								#o = false
							}
						else
							if(.params !>> string(#c)) => {
								#o = false
							}
						}
					}
				}

				if(givenblock->type == {}->type && #o) => {
					givenblock()
				else(givenblock->type != {}->type)
					return #o
				}
			}
		}

		private Instantiatstorage()::void => {
			if(arm_data(.datakey)->type != staticarray->type) => {
				local(pr = array)
				if(client_getparams->find(.'pathroute')->first->type == pair->type) => {
					#pr->merge(string_removeleading(string(client_getparams->find(.'pathroute')->first->value), '/')->split('/'))
				else
					#pr->merge(response_filepath->split('/'))
				}
				arm_data(.datakey=#pr->asstaticarray)
			}
		}

		private datakey()::string => {
			return ('pathroute#' + .'pathroute')
		}

		private matchtype(x::string, -isa::string)::boolean => {
			/*
				->istype('type','value')
				√	date		20120215
				√	datetime	20120215T200615
				√	array		foo,bar,23,tess
				√	decimal		12.3402
				√	integer		12
				√	alnum		foobar23
				√	alpha		foobar
				√	uuid		C969AB19-8889-452F-8D44-D7A9C0478FE3
				√	any
			*/
			local(o = false)

			match(#isa) => {

				case('date','dtime')
					if(#x >> '-' && #x >> ':');
						local(formats) = array(
								'\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}',
								'\\d{4}-\d{2}-\d{2}T\d{2}:\d{2}',
								'\d{4}-\\d{2}T\\d{2}:\\d{2}:\\d{2}',
								'\\d{4}-\\d{2}T\\d{2}:\\d{2}',
								'\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}',
								'\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}',
								'\\d{4}-\\d{2} \\d{2}:\\d{2}:\\d{2}',
								'\\d{4}-\\d{2} \\d{2}:\\d{2}');	
					else(#x >> '/' && #x >> ':');
						local(formats) = array(
								'\\d{2}/\\d{2}/\\d{4} \\d{2}:\\d{2}:\\d{2}',
								'\\d{2}/\\d{2}/\\d{4} \\d{2}:\\d{2}',
								'\\d{2}/\\d{4} \\d{2}:\\d{2}:\\d{2}',
								'\\d{2}/\\d{4} \\d{2}:\\d{2}',
								'\\d{2}/\\d{2}/\\d{4} \\d{2}:\\d{2}:\\d{2} a',
								'\\d{2}/\\d{2}/\\d{4} \\d{2}:\\d{2} a',
								'\\d{2}/\\d{4} \\d{2}:\\d{2}:\\d{2} a',
								'\\d{2}/\\d{4} \\d{2}:\\d{2} a');
					else(#x >> '-');
						local(formats) = array(
								'\\d{4}-\\d{2}-\\d{2}',
								'\\d{4}-\\d{2}');
					else(#x >> '/');
						local(formats) = array(
								'\\d{2}/\\d{2}/\\d{4}',
								'\\d{4}/\\d{2}');
					else(#x >> ':');
						local(formats) = array(
								'\\d{4}\\d{2}\\d{2}T\\d{2}:\\d{2}:\\d{2}',
								'\\d{4}\\d{2}\\d{2}T\\d{2}:\\d{2}',
								'\\d{4}\\d{2}T\\d{2}:\\d{2}:\\d{2}',
								'\\d{4}\\d{2}T\\d{2}:\\d{2}',
								'\\d{2}:\\d{2}:\\d{2} a',
								'\\d{2}:\\d{2} a',
								'\\d{2}:\\d{2}:\\d{2}',
								'\\d{2}:\\d{2}');
					else;
						local(formats) = array(
								'\\d{4}\\d{2}\\d{2}\\d{2}\\d{2}\\d{2}',
								'\\d{4}\\d{2}\\d{2}T\\d{2}\\d{2}\\d{2}',
								'\\d{4}\\d{2}\\d{2}T\\d{2}\\d{2}',
								'\\d{4}\\d{2}\\d{2}T\\d{2}',
								'\\d{4}\\d{2}\\d{2}',
								'\\d{4}\\d{2}',
								'\\d{4}');
					/if;
					local(o = false)
					iterate(#formats, local(fmt)) => {
						if(regexp(-find=#fmt, -input=#x)->find) => {
							#o = true
							loop_abort
						}
					}
					if(#x != string(date(#x))) => {
						#o = false
					}

				case('array')
					if(#x-> size) => {
						#o = true
					}

				case('decimal')
					if(#x->size > 0 && regexp(-find='^-?\\d*\\.?\\d*$', -input=#x)->find) => {
						#o = true
					}

				case('integer')
					if(regexp(-find='^-?\\d+$', -input=#x)->find) => {
						#o = true
					}

				case('alnum')
					#o = true
					iterate(#x, local(char)) => {
						if(not #char->isalnum) => {
							#o = false
							loop_abort
						}
					}

				case('alpha')
					#o = true
					iterate(#x, local(char)) => {
						if(not #char->isalpha) => {
							#o = false
							loop_abort
						}
					}

				case('uuid')
					if(regexp(-find='^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$', -input=#x)->find) => {
						#o = true
					}

				case('any')
					#o = true

			}

			return #o
		}

		public asstring()::void => { return void }

		public route()::string => {

			local(pathroute = arm_data(.datakey)->join('/'))
			#pathroute->removeleading(.path)
			return #pathroute
		}

		public route(index::integer)::string => {
			local(routearray = string_removeleading(.route, -pattern='/')->split('/'))
			fail_if(#index > #routearray->size, -1, 'Arm_Request->Route expected an integer less than or equal to the length of the route. Expected less than or equal to ' + #routearray->size + ', received ' + #index + '.')
			fail_if(#index < 1, -1, 'Arm_Request->Route expected an integer greater than 0, received ' + #index + '.')
			return #routearray->get(#index)
		}

		public path()::string => {
			local(o = string)
			if(string(arm_data('overridepath'))->size) => {
				#o = arm_data('overridepath')
			else
				#o = arm_data(.datakey)->first
			}
			return #o
		}

		public path(newpath::string)::void => {
			arm_data('overridepath'=#newpath)
		}

		public method()::string => {
			local(o = string)
			local(a = array('GET','POST','PUT','DELETE'))
			if(#a >> web_request->postparam('_method')->asstring) => {
				#o = web_request->postparam('_method')->asstring
			else
				#o = web_request->requestMethod->asstring
			}
			#o->uppercase
			return #o
		}

		public param(name::string)::string => {
			local(found = .params->find(#name)->first)
			if(#found->type == pair->type) => {
				#found = #found->value
			}
			return #found
		}

		public params()::staticarray => {
			local(o = array)
			#o->merge(web_request->postparams)
			#o->merge(web_request->queryparams)
			#o->removeall(.'pathroute')
			#o->removeall('_method')
			return #o->asstaticarray
		}
	}

	define arm_model => type {

		data protected values::map = map

		public _unknownTag()::void => {
			return .'values'->find(tag_name)
		}

	}

	define arm_view => type {

		data protected content::string
		data protected defaultvalue::string
		data protected fragments::map
		data protected values::map = map
		data protected title = null
		data protected description = null
		data protected keywords = null
		data protected author = null
		data protected canonical = null
		data protected stylecalls::array = array
		data protected style::array = array
		data protected scriptcalls::array = array
		data protected javascript::array = array
		data protected jquery::array = array
		data protected template::string
		data protected nolasso::boolean

		protected template()::string => {
			return .'template'
		}

		public template(template::string, -nolasso::boolean=false)::void => {
			.'template' = #template
			.'nolasso' = #nolasso
		}

		public defaultvalue(package::string)::void => {
			.'defaultvalue' = #package
		}

		public title(package::string = '')::void => {
			.'title' = #package
		}

		public description(package::string = '')::void => {
			.'description' = #package
		}

		public keywords(package::string = '')::void => {
			.'keywords' = #package
		}

		public author(package::string = '')::void => {
			.'author' = #package
		}

		public canonical(package::string = '')::void => {
			.'canonical' = #package
		}

		public style(style::string, -replace::boolean=false)::void => {
			if(#replace) => {
				.'style' = array
			}
			if(#style->length > 0) => {
				.'style'->insert(#style)
			}
		}

		public style(-src::string, -replace::boolean=false)::void => {
			if(#replace) => {
				.'stylecalls' = array
			}
			if(#src->length > 0) => {
				.'stylecalls'->insert(#src)
			}
		}

		public javascript(javascript::string, -replace::boolean=false)::void => {
			if(#replace) => {
				.'javascript' = array
			}
			if(#javascript->length > 0) => {
				.'javascript'->insert(#javascript)
			}
		}

		public javascript(-src::string, -attributes::map=map, -replace::boolean=false)::void => {
			if(#replace) => {
				.'javascript' = array
			}
			if(#src->length > 0) => {
				.'javascript'->insert(#src=#attributes)
			}
		}

		public jquery(package::string, -replace=false)::void => {
			if(#replace) => {
				.'jquery' = array
			}
			.'jquery'->insert(#package)
		}

		public _unknownTag(...)::any => {
			/*

				Allows creating "virtual member-tags" for replacing
				place holders, such as the following, within the 
				specified template.

					<!-- $toolbar -->

			*/

			local('fragment' = null)
			iterate(#rest) => {
				if(string(loop_value->type) == 'keyword') => {
					if(loop_value->name == 'fragment') => {
						#fragment = string(loop_value->value)
					}
				}
			}

			if(#fragment->type == string->type) => {
				.'values'->insert(method_name=(escape_tag(.type)->invoke))
				(.'values'->find(method_name))->template(#fragment)
			else(.'values' >> method_name)
				if((.'values'->find(method_name))->type == .type) => {
					return .'values'->find(method_name)
				else
					fail(-1,'Placeholder value already set.')
				}
			else
				.'values'->insert(method_name=(#rest->first))
			}

		}

		protected replace_title()::void => {
			local('package' = .'title')
			if(#package->type != null->type) => {
				.'content' = string_replaceregexp(.'content', -find='<title>.*?</title>', -replace='<title>' + #package + '</title>')
			}
		}

		protected replace_description()::void => {
			local('package' = .'description')
			if(#package->type != null->type) => {
				.'content' = string_replaceregexp(.'content', -find='<meta[^>]*name="description"[^>]*>', -replace='<meta name="description" content="' + #package + '">')
			}
		}

		protected replace_keywords()::void => {
			local('package' = .'keywords')
			if(#package->type != null->type) => {
				.'content' = string_replaceregexp(.'content', -find='<meta[^>]*name="keywords"[^>]*>', -replace='<meta name="keywords" content="' + #package + '">')
			}
		}

		protected replace_author()::void => {
			local('package' = .'author')
			if(#package->type != null->type) => {
				.'content' = string_replaceregexp(.'content', -find='<meta[^>]*name="author"[^>]*>', -replace='<meta name="author" content="' + #package + '">')
			}
		}

		protected replace_canonical()::void => {
			local('package' = .'canonical')
			if(#package->type == null->type || string(#package)->size == 0) => {
				#package = arm_request->path + '/' + arm_request->route
			}
			.'content' = string_replaceregexp(.'content', -find='<link[^>]*rel="canonical"[^>]*>', -replace='<link rel="canonical" href="' + #package + '">')
		}

		protected insert_stylecalls()::void => {
			iterate(.'stylecalls') => {
				.'content' = string_replace(.'content', -find='</head>', -replace='<link rel="stylesheet" href="' + loop_value + '">\r</head>')
			}
		}

		protected insert_style()::void => {
			if(.'style'->size > 0) => {
				.'content' = string_replace(.'content', -find='</head>', -replace='<style type="text/css" title="text/css" media="all">\r' + .'style'->join('\r') + '\r</style>\r</head>')
			}
		}

		protected insert_javascript()::void => {
			local('output' = array)
			iterate(.'javascript') => {
				if(loop_value->type == pair->type) => {
					local('call' = string)
					#call += '<script type="text/javascript" src="' + encode_html(loop_value->name) + '"'
					iterate(loop_value->value, local('p')) => {
						#call += ' ' + encode_html(#p->name) + '="' + encode_html(#p->value) + '"'
					}
					#call += '></script>'
					#output->insert(#call)
				else
					#output->insert('<script type="text/javascript">\r' + loop_value + '\r</script>')
				}
			}
			.'content' = string_replace(.'content', -find='</body>', -replace=#output->join('\r') + '\r</body>')
		}

		protected insert_jquery()::void => {
			if(.'jquery'->size > 0) => {
				.'content' = string_replace(.'content', -find='</body>', -replace='<script type="text/javascript">\r$(document).ready(function(){\r' + .'jquery'->join('\r') + '\r});\r</script>\r</body>')
			}
		}

		protected placeholder_prefix()::string => {
			return '<!--\\* \\$'
		}

		protected placeholder_suffix()::string => {
			return ' -->'
		}

		protected replace_placeholders()::void => {
			iterate(.'values', local('pair')) => {
				if(#pair->type == pair->type) => {
					.'content' = string_replaceregexp(.'content', -find=(.placeholder_prefix + encode_html(#pair->name) + .placeholder_suffix), -replace=string(#pair->value))
				}
			}
			.'content' = string_replaceregexp(.'content', -find=.placeholder_prefix + '[\\w]*?' + .placeholder_suffix, -replace=string(.'defaultvalue'))
			.'content' = string_replaceregexp(.'content', -find='<!--\\*[\\s\\S]*?-->', -replace='')
		}

		protected cleanup_html()::void => {
			.'content' = string_replaceregexp(.'content', -find='\\n\\s*', -replace='\n')
			.'content' = string_replaceregexp(.'content', -find='\\n+', -replace=' ')
		}

		protected export()::string => {
			fail_if(string(.template)->size == 0, -1, 'No template file specified for the Arm framework.')
			if(.'nolasso') => {
				.'content' = string(include_raw(.template))
			else
				.'content' = string(include(.template))
			}
			.replace_placeholders
			.replace_title
			.replace_description
			.replace_keywords
			.replace_author
			.replace_canonical
			.insert_stylecalls
			.insert_style
			.insert_javascript
			.insert_jquery
			if(not arm_data('nocleanup')) => {
				.cleanup_html
			}
			return .'content'
		}

		public asstring()::string => {
			return .export
		}

	}

	define arm_controller => type {

		data public view
		data public models::map = map
		data protected values::map = map

		public run()::string => {
			.session_preserve
			if(.hasmethod(::atbegin)) => {
				.atbegin ? .main
			else
				.main
			}
			if(.hasmethod(::atend)) => {
				.atend
			}
			return .'view'
		}

		public name()::string => {
			return arm_request->path
		}

		public view(value)::void => {
			.'view' = #value
		}

		public view()::any => {
			return .'view'
		}

		public model(value::pair)::void => {
			.'models'->insert(#value)
		}

		public model(name::string)::any => {
			return .'models'->find(#name)
		}

		public val(value::pair)::void => {
			.'values'->insert(#value)
		}

		public val(name::string)::any => {
			return .'values'->find(#name)
		}

		protected session_preserve()::void => {
			if(
				string(action_param('-lassosession:' + .session_name))->size > 0 ||
				string(cookie('_LassoSessionTracker_' + .session_name))->size > 0
			) => {
				.session_start
			}
		}

		protected session_name()::string => {
			return 'arm'
		}

		public session_start(-force::boolean=false)::void => {
			// The session will only be started if it hasn't already been started,
			// or the -force keyword is used.
			if(#force || session_id(.session_name)->type == void->type) => {
				if(var('_arm_sessiondata')->type != map->type) => {
					var('_arm_sessiondata' = map)
				}
				/*
				if(cookie(.session_name) -> size) => {
					session_start(-name=(.session_name), -usenone, -expires=(360), -id=cookie(.session_name))
				else
					session_start(-name=(.session_name), -uselink, -expires=(360))
				}
				cookie_set((.session_name)=session_id(-name=(.session_name)), -domain=server_name, -path='/')
				*/
				session_start(-name=(.session_name), -expires=(360), -useauto)
				session_addvar(-name=(.session_name), '_arm_sessiondata')
			}
		}

		public session_var(package::pair)::void => {
			.session_start
			$_arm_sessiondata->insert(#package)
		}

		public session_var(name::string)::any => {
			.session_start
			return $_arm_sessiondata->find(#name)
		}

		public session_removevar(name::string)::void => {
			if(var('_arm_sessiondata')->type == map->type) => {
				$_arm_sessiondata->removeall(#name)
			}
		}

		public session_flip()::void => {
			if(session_id(.session_name)->type != void->type) => {
				session_end(-name=.session_name)
			}
			.session_start(-force)
		}

	}

?>