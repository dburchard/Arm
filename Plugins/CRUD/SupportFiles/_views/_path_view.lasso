<?lassoscript

	define _path_view => type {

		parent _app_view

		public msgs(index::integer)::string => {
			local( o = map(
				locale_chinese->language=map(
					1='添加新記錄',
					2='更新',
					3='刪除',
					4='保存',
					5='查看所有記錄',
					6='編輯',
					7='已成功创建记录',
					8='已成功更新记录',
					9='记录被成功删除',
					10='试图创造新的记录时遇到了一个错误',
					11='试图更新记录时遇到了一个错误',
					12='试图删除记录时遇到了一个错误'
				),
				locale_english->language=map(
					1='Add a new record',
					2='Update',
					3='Delete',
					4='Save',
					5='View all records',
					6='Edit',
					7='The record was successfully created',
					8='The record was successfully updated',
					9='The record was successfully deleted',
					10='An error was encountered while trying to create the new record',
					11='An error was encountered while trying to update the record',
					12='An error was encountered while trying to delete the record'
				),
				locale_french->language=map(
					1='Ajouter un nouveau record',
					2='Mettre à jour',
					3='Effacer',
					4='Sauver',
					5='Voir tous les dossiers',
					6='éditer',
					7='Le record a été créé avec succès',
					8='Le record a été correctement mis à jour',
					9='Le record a été supprimé avec succès',
					10='Une erreur s\'est produite tout en essayant de créer le nouveau record',
					11='Une erreur s\'est produite tout en essayant de mettre à jour le dossier',
					12='Une erreur s\'est produite tout en essayant de supprimer l\'enregistrement'
				),
				locale_german->language=map(
					1='Hinzufügen eines neuen Datensatzes',
					2='Aktualisieren',
					3='Löschen',
					4='Sparen',
					5='Alle Aufzeichnungen',
					6='Bearbeiten',
					7='Der Rekord wurde erfolgreich erstellt',
					8='Der Rekord wurde erfolgreich aktualisiert',
					9='Der Datensatz wurde erfolgreich gelöscht',
					10='Ein Fehler trat bei dem Versuch, den neuen Datensatz zu erstellen',
					11='Ein Fehler trat bei dem Versuch, den Datensatz zu aktualisieren',
					12='Ein Fehler trat bei dem Versuch, den Datensatz zu löschen'
				),
				locale_italian->language=map(
					1='Aggiungere un nuovo record',
					2='Aggiornare',
					3='Cancellare',
					4='Salvare',
					5='Visualizza tutti i record',
					6='Modifica',
					7='Il record è stato creato con successo',
					8='Il record è stato aggiornato con successo',
					9='Il record è stato cancellato con successo',
					10='È verificato un errore durante il tentativo di creare il nuovo record',
					11='È verificato un errore durante il tentativo di aggiornare il record',
					12='È verificato un errore durante il tentativo di eliminare il record'
				),
				locale_japanese->language=map(
					1='新しいレコードを追加',
					2='更新',
					3='削除する',
					4='保存',
					5='すべてのレコードを表示する',
					6='編集',
					7='レコードが正常に作成されました',
					8='レコードが正常に更新されました',
					9='レコードが正常に削除されました',
					10='新しいレコードを作成しようとしているときにエラーが発生しました',
					11='レコードを更新しようとしているときにエラーが発生しました',
					12='レコードを削除しようとしているときにエラーが発生しました'
				),
				locale_korean->language=map(
					1='새 레코드를 추가',
					2='업데이트',
					3='삭제',
					4='저장',
					5='모든 기록보기',
					6='편집',
					7='레코드가 성공적으로 만들었습니다',
					8='레코드가 성공적으로 업데이 트되었습니다',
					9='기록이 삭제되었습니다',
					10='새 레코드를 생성하는 동안 오류가 발생했습니다',
					11='레코드를 업데이 트하는 동안 오류가 발생했습니다',
					12='레코드를 삭제하는 도중 오류가 발생했습니다'
				)
			))

			local(lang = locale_english->language)
			if(#o >> locale_default->language) => {
				#lang = locale_default->language
			}
			
			return #o->find(#lang)->find(#index)
		}

		public alert(index::integer, addendum::string='')::void => {
			.'values'->insert('alert'='<p class="alert">' + .msgs(#index) + (#addendum ? ': ' + #addendum | '.') + '</p>')
		}

		public list(values::staticarray, -keyfield::string)::void => {
			local(o = '')
			#o += '<div class="scrollableContainer">'
			#o += '<table>'
			#o += '<thead>'
			#o += '<tr>'
			#o += '<th></th>'
			if(#values->first->hasmethod(::value)) => {
				iterate(#values->first->value, local(f)) => {
					if(#f->name != #keyfield) => {
						#o += '<th>' + #f->name + '</th>'
					}
				}
			}
			#o += '</tr>'
			#o += '</thead>'
			#o += '<tbody>'
			iterate(#values, local(r)) => {
				#o += '<tr>'
				#o += '<td><a href="/' + arm_request->path + '/' + encode_url(#r->name) + '">' + loop_count + '.</a></td>'
				local(i = 0)
				iterate(#r->value, local(c)) => {
					if(#c->name != #keyfield) => {
						#i = #i + 1
						#o += '<td>'
						if(#i == 1) => {
							#o += '<a href="/' + arm_request->path + '/' + encode_url(#r->name) + '">' + #c->value + '</a>'
						else
							#o += #c->value
						}
						#o += '</td>'
					}
				}
				#o += '</tr>'
			}
			#o += '</tbody>'
			#o += '</table>'
			#o += '</div>'
			#o += '<ol class="navigationLinks">'
			#o += '<li><a href="/' + arm_request->path + '/new">' + .msgs(1) + '</a></li>'
			#o += '</ol>'
			.'values'->insert('mainbody'=#o)
		}

		public form(values::pair, -keyfield::string)::void => {
			local(o = '')
			if(string(#values->name)->size > 0) => {
				#o += '<form action="/' + arm_request->path + '/' + encode_html(#values->name) + '" method="POST">'
			else
				#o += '<form action="/' + arm_request->path + '" method="POST">'
			}
			#o += '<fieldset>'
			iterate(#values->value, local(f)) => {
				if(#f->name != #keyfield) => {
					#o += '<p>'
					#o += '<label for="' + #f->name + '">' + #f->name + '</label>'
					#o += '<input type="text" id="' + #f->name + '" name="' + #f->name + '" value="' + #f->value + '" />'
					#o += '</p>'
				}
			}
			#o += '</fieldset>'
			if(string(#values->name)->size > 0) => {
				#o += '<button type="submit" name="_method" value="PUT">' + .msgs(2) + '</button>'
				#o += '<button type="submit" name="_method" value="DELETE">' + .msgs(3) + '</button>'
			else
				#o += '<button type="submit">' + .msgs(4) + '</button>'
			}
			#o += '</form>'
			#o += '<ol class="navigationLinks">'
			#o += '<li><a href="/' + arm_request->path + '">' + .msgs(5) + '</a></li>'
			#o += '</ol>'
			.'values'->insert('mainbody'=#o)
		}

		public detail(values::pair, -keyfield::string)::void => {
			local(o = '')
			iterate(#values->value, local(f)) => {
				if(#f->name != #keyfield) => {
					#o += '<p>'
					#o += '<span class="label">' + #f->name + '</span>'
					#o += '<span class="value">' + #f->value + '</span>'
					#o += '</p>'
				}
			}
			#o += '<ol class="navigationLinks">'
			#o += '<li><a href="/' + arm_request->path + '/' + encode_html(#values->name) + '/edit">' + .msgs(6) + '</a></li>'
			#o += '<li><a href="/' + arm_request->path + '">' + .msgs(5) + '</a></li>'
			#o += '</ol>'

			.'values'->insert('mainbody'=#o)
		}

	}

?>