LOCALPATH := ~/.ikiwiki/IkiWiki/Plugin/

plugins = plantuml.pm plantuml.jar
local: ${plugins}
	mkdir -p ${LOCALPATH}
	cp ${plugins} ${LOCALPATH}

plantuml.jar:
	curl -L -O http://downloads.sourceforge.net/project/plantuml/plantuml.jar


