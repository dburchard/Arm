<?lassoscript

	library_once('/_libraries/plugin_host__hostnick.lasso')

	define _path_mod => type {

		parent _app_model

		trait {
			import trait_dbhost__hostnick
		}

		private table()::staticarray => { return staticarray(-table='_table') }

		public keyfield()::string => { return '_keyfield' }

		public newkeyvalue() => { return _keyfieldvalue }

		public columns(params::staticarray = staticarray)::pair => {
			local(o = array)
			inline(-host=.hostarray, .database, .table, -show) => {
				local(r = array)
				iterate(column_names) => {
					local(v = string)
					if(#params->find(column_name(loop_count))->size > 0) => {
						if(#params->find(column_name(loop_count))->first->type == pair->type) => {
							#v = #params->find(column_name(loop_count))->first->value
						}
					}
					#r->insert(column_name(loop_count)=#v)
				}
				#o->insert(''=#r->asstaticarray)
			}
			return #o->first
		}

		public list(
			-key::any=null,
			-sortfield::string='',
			-sortorder::string='ascending'
		)::staticarray => {
			inline(
				-host=.hostarray, .database, .table,
				-keyfield=.keyfield,
				-keyvalue=#key,
				-sortfield=#sortfield,
				-sortorder=#sortorder,
				-maxrecords='all',
				-search
			) => {
				local(o = array)
				records => {
					local(r = array)
					iterate(field_names) => {
						#r->insert(loop_value=field(field_name(loop_count)))
					}
					#o->insert(field(.keyfield)=#r->asstaticarray)
				}
				return #o->asstaticarray
			}
		}

		public create(params::staticarray) => {
			local(col = .columns->value)
			local(values = array)
			iterate(#params, local(prm)) => {
				if(#prm->type == pair->type) => {
					if(#col >> #prm->name) => { #values->insert(#prm) }
				}
			}
			#values->removeall(.keyfield)
			local('newkeyvalue' = .newkeyvalue)
			local('keyfield' = null)
			if(string(#newkeyvalue)->size) => {
				#keyfield = array(.keyfield=#newkeyvalue)
			}
			inline(
				-host=.hostarray, .database, .table, 
				#keyfield,
				#values,
				-add
			) => {
				if(error_currenterror == error_noerror) => {
					if(string(#newkeyvalue)->size) => {
						return #newkeyvalue
					else
						return keyfield_value
					}
				else
					return false
				}
			}
		}

		public show(key::string)::pair => {
			return .list(-key=#key)->first
		}

		public update(params::staticarray, -key::string)::boolean => {
			local(col = .columns->value)
			local(values = array)
			iterate(#params, local(prm)) => {
				if(#prm->type == pair->type) => {
					if(#col >> #prm->name) => { #values->insert(#prm) }
				}
			}
			#values->removeall(.keyfield)
			inline(
				-host=.hostarray, .database, .table, 
				-keyfield=.keyfield,
				-keyvalue=#key,
				#values,
				-update
			) => { return (error_currenterror == error_noerror) }
		}

		public delete(key::string)::boolean => {
			inline(
				-host=.hostarray, .database, .table, 
				-keyfield=.keyfield,
				-keyvalue=#key,
				-delete
			) => { return (error_currenterror == error_noerror) }
		}

	}

?>