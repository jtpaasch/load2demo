PLUGIN = load2demo.plugin
PLUGIN_DESC = "Demo to load 2 binaries"
SOURCE = $(wildcard *.ml) $(wildcard **/*.ml) $(wildcard **/*.mli)
Is = .
PKGs = findlib.dynload,bap
TAG = "warn(all)"


##############################################
# DEFAULT
##############################################

.DEFAULT_GOAL = all
all:
	$(MAKE) uninstall
	$(MAKE) clean
	$(MAKE) build
	$(MAKE) install


##############################################
# PLUGIN
##############################################

build: $(PLUGIN)
$(PLUGIN): $(SOURCE)
	bapbuild \
	    -use-ocamlfind \
	    -pkgs $(PKGs) \
	    -Is $(Is) \
	    -tag $(TAG) \
	    $(PLUGIN)

.PHONY: install
install: build
	bapbundle update -desc $(PLUGIN_DESC) $(PLUGIN)
	bapbundle install $(PLUGIN)

.PHONY: uninstall
uninstall:
	bapbundle remove $(PLUGIN)


##############################################
# CLEAN
##############################################

.PHONY: clean
clean:
	bapbundle remove $(PLUGIN)
	bapbuild -clean $(PLUGIN)
