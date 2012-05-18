<?lassoscript

	protect => {
		define trait_dbhost__hostnick => trait {

			provide database()::array => {
				return array(-database='_database')
			}

			 provide hostarray()::array => {
				return _hostarray
			}
		}
	}

?>