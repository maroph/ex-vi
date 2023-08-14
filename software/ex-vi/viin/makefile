MS=quickref.ms
PS=quickref.ps
PDF=quickref.pdf
HTML=paper-1.html paper-2.html paper-3.html paper-4.html paper-5.html \
	paper-6.html paper-7.html paper-notes.html \
	paper.html paper.css

.SUFFIXES: .pdf .ps .ms
.ms.ps: ; tbl $< | GROFF_FONT_PATH= groff -ms -Tps > $@
.ps.pdf: ; PATH=/usr/bin:$$PATH gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=$@ -sPAPERSIZE=a4 -dFIXEDMEDIA pdfparams.ps $<

all: $(PS) $(PDF)

$(PDF): pdfparams.ps

