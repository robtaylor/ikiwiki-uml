UML Diagramming for Ikiwiki
===========================

Install
-------

Just run make, this will do a use-local install of the plugin.

Usage
-----

Do something like:

     [[!uml src="
      lice -> Bob: Authentication Request
      Bob --> Alice: Authentication Response

      Alice -> Bob: Another authentication Request
      Alice <-- Bob: another authentication Response
    " ]]

For the rest of PlantUML's syntax, read [the PlantUML Language Reference Guide](http://downloads.sourceforge.net/project/plantuml/PlantUML%20Language%20Reference%20Guide.pdf)


