# # Put in your GitHub account details.
# GITHUB_USER=foo
# GITHUB_API_TOKEN=foo
# 
# # Project name = directory name.
# # TO DO: This variable seems to fail sometimes. Fix it.
# #PROJECT_NAME=$${PWD\#\#*/}
# 
# # For now it's just written in the makefile and you manually change it.
# PROJECT_NAME=test
# 
# # Gerbv PCB image preview parameters - colours, plus resolution.
GERBER_IMAGE_RESOLUTION?=600
BACKGROUND_COLOR?=\#006600
HOLES_COLOR?=\#000000
SILKSCREEN_COLOR?=\#ffffff
PADS_COLOR?=\#FFDE4E
TOP_SOLDERMASK_COLOR?=\#009900
BOTTOM_SOLDERMASK_COLOR?=\#2D114A
GERBV_OPTIONS= --export=png --dpi=$(GERBER_IMAGE_RESOLUTION) --background=$(BACKGROUND_COLOR) --border=1

# # STUFF YOU WILL NEED:
# # - git, gerbv and eagle must be installed and must be in path.
# # - Got GitHub account?
# # - GitHub set up with your SSH keys etc.
# # - Put your GitHub username and private API key in the makefile
# 
# # On Mac OSX we will create a link to the Eagle binary:
# # sudo ln -s /Applications/EAGLE/EAGLE.app/Contents/MacOS/EAGLE /usr/bin/eagle 
# 
# .SILENT: all gerbers git github clean
# 
# all : gerbers git github
# 
# .PHONY: gerbers
# 

.SECONDARY: .png

boards := $(wildcard *.brd)
zips := $(patsubst %.brd,%_gerber.zip,$(boards))
pngs := $(patsubst %.brd,%.png,$(boards))
back_pngs := $(patsubst %.brd,%_back.png,$(boards))
mds := $(patsubst %.brd,%.md,$(boards))

GERBER_DIR=gerbers

all: $(zips) $(pngs) $(back_pngs) README.md

README.md: Intro.md $(mds)
	cat $+ > README.md 

%.GTL: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< Top Pads Vias Dimension

%.GBL: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< Bottom Pads Vias Dimension

%.GTO: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< tPlace tNames tValues

%.GTP: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< tCream

%.GBO: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< bPlace bNames bValues

%.GTS: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< tStop

%.GBS: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< bStop

%.GML: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< Milling

# board outline
%.OLN: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< Dimension

%.TXT: %.brd
	eagle -X -d EXCELLON_24 -o $@ $< Drills Holes

%_gerber.zip: %.GTL %.GBL %.GTO %.GTP %.GBO %.GTS %.GBS %.GML %.TXT %.png %_back.png
	zip $@ $^ $*.dri

%.png: %.TXT %.GTO %.GTS %.GTL
	gerbv $(GERBV_OPTIONS) --output=$@ \
        --f=$(HOLES_COLOR) $*.TXT \
        --f=$(SILKSCREEN_COLOR) $*.GTO \
        --f=$(PADS_COLOR) $*.GTS \
        --f=$(TOP_SOLDERMASK_COLOR) $*.GTL
	convert $@ -alpha set -fill none -draw 'matte 0,0 floodfill' -trim $@

%_back.png: %.TXT %.GBO %.GBS %.GBL
	gerbv $(GERBV_OPTIONS) --output=$@ \
        --f=$(HOLES_COLOR) $*.TXT \
        --f=$(SILKSCREEN_COLOR) $*.GBO \
        --f=$(PADS_COLOR) $*.GBS \
        --f=$(TOP_SOLDERMASK_COLOR) $*.GBL
	convert $@ -alpha set -fill none -draw 'matte 0,0 floodfill' -flop -trim +repage $@

%.md: %.png %_back.png %.GTL
	echo "## $* \n\n" >  $@
	gerber_board_size $*.GTL >> $@
	echo "\n\n| Front | Back |\n| --- | --- |\n| ![Front]($*.png) | ![Back]($*_back.png) |\n\n" >>  $@

.gitignore:
	echo "\n*~\n.*.swp\n*.?#?\n.*.lck" > .gitignore

.git:
	echo "\n*~\n.*.swp\n*.?#?\n.*.lck" > .gitignore
	git init
	git add .
	git commit -m 'First Commit'

Intro.md:
	touch Intro.md

clean:
	rm -rf *.G[TBM][LOPS] *.TXT *.dri *.gpi
	rm -rf *.[bs]#?



# # TO DO: Can we get Eagle to automatically export the schematic, as a PDF or PostScript or PNG, at the command line?
# eagle -C "print file .pdf; quit;" Pixie85.sch
# 
# git : gerbers
# 
# 	if [ ! -d .git ]; then git init > /dev/null; fi
# 	if [ -d ./gerbers ]; then git add ./gerbers; fi
# 	for f in `ls *.brd *.sch *.png *.pdf *.txt *.markdown .gitignore 2> /dev/null`; do git add $$f; done
# 	-git commit -m "foo" > /dev/null
# 	echo "Files committed to local git repository."
# 
# github : git
# 
# # TO DO: When we call the API to see if the repository exists, it cannot see your private repos unless the username and key is put in.
# 	
# 	-curl -f https://github.com/api/v2/yaml/repos/show/$(GITHUB_USER)/$(PROJECT_NAME) > /dev/null 2>&1; \
# 	if [ $$? -eq 0 ]; then echo "GitHub remote repository already exists."; fi
# 
# # TO DO: Known bug case - breaks if the GitHub repository exists but there is still a remote set for some reason in the local git repo.
# 
# 	-curl -f https://github.com/api/v2/yaml/repos/show/$(GITHUB_USER)/$(PROJECT_NAME) > /dev/null 2>&1; if [ $$? -eq 22 ]; then \
# 	curl -F 'login=$(GITHUB_USER)' -F 'token=$(GITHUB_API_TOKEN)' https://github.com/api/v2/yaml/repos/create -F 'name=$(PROJECT_NAME)' > /dev/null 2>&1; \
# 	git remote add origin git@github.com:$(GITHUB_USER)/$(PROJECT_NAME).git; echo "Built new GitHub remote repository."; fi
# 	echo "Pushing to GitHub remote repository..."
# 	git push -u origin master 2> /dev/null
# 	echo "Done."
# 
# clean :
# 	rm -rf *.{GTL,GBL,GTO,GTP,GBO,GTS,GBS,GML,TXT,dri,gpi,png}
# 	rm -rf ./gerbers
# 	rm -rf .git
# 
