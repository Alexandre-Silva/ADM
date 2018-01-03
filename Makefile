.PHONY += README.html

README.html: README.md
	pandoc -f gfm -i README.md -o README.html
