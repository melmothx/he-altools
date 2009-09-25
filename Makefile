PDFDIRECTORY = /home/melmoth/progetti/tal/pdf_archive
TEXDIRECTORY = /home/melmoth/progetti/tal/LaTeX_archive
pdfs = $(patsubst %.xml,$(PDFDIRECTORY)/letter/%_letter.pdf,$(wildcard *.xml))

all : $(pdfs)

$(PDFDIRECTORY)/letter/%_letter.pdf : %.xml
	PDFDIRECTORY=$(PDFDIRECTORY) TEXDIRECTORY=$(TEXDIRECTORY) he-drupal2latex $<
##	PDFDIRECTORY=$(PDFDIRECTORY) TEXDIRECTORY=$(TEXDIRECTORY) uploadthepdfs $<

