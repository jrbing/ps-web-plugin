# makefile
pluginname=ps-web-plugin
pluginfile=$(pluginname).zip
FILES=$(shell find $(pluginname))

.PHONY: clean

$(pluginfile): $(FILES)
	zip -r $(pluginfile) $(pluginname)

clean:
	@-rm -rf $(pluginfile)
