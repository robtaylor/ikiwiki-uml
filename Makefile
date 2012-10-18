LOCALPATH := ~/.ikiwiki/IkiWiki/Plugin/

plugins = plantuml.pm plantuml.jar
local: ${plugins}
	mkdir -p ${LOCALPATH}
	cp ${plugins} ${LOCALPATH}

plantuml.jar:
	curl -L -O http://downloads.sourceforge.net/project/plantuml/plantuml.jar

PlantUML%20Language%20Reference%20Guide.pdf:
	curl -L -O http://downloads.sourceforge.net/project/plantuml/PlantUML%20Language%20Reference%20Guide.pdf

reference: PlantUML%20Language%20Reference%20Guide.pdf
