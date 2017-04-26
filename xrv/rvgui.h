# RVGUI.H -- Definition file for the GUI interface support procedures.

define	UI_KEYWORDS	"|ui_update\
			 |ui_donestatus\
			 |ui_quit\
			 |ui_output\
			 |ui_showv\
			 |ui_fxcset\
			 |ui_keywset\
			 |ui_filtset\
			 |ui_fmopset\
			 |ui_contset\
			 |ui_fxcstat\
			 |ui_keywstat\
			 |ui_filtstat\
			 |ui_contstat\
			 |ui_autowrite\
			 |ui_imload\
			 |ui_listopen\
			 |ui_imglist\
			 |ui_aplist|"

define	UI_UPDATE	 1		# Update the whole thing
define	UI_DONESTATUS	 2		# Update the dialog box status
define	UI_QUIT		 3		# Quit the task
define	UI_OUTPUT	 4		# Set an output file and move list
define	UI_SHOWV	 5		# Show verbose fit information
define	UI_FXCSET	 6		# Update the task with new parameters
define	UI_KEYWSET	 7		# Update the pset with new parameters
define	UI_FILTSET	 8		# Update the pset with new parameters
define	UI_FMOPSET	 9		# Update the fft mode options
define	UI_CONTSET	10		# Update the pset with new parameters
define	UI_FXCSTAT	11		# Update the task parameters to the GUI
define	UI_KEYWSTAT	12		# Update the pset parameters to the GUI
define	UI_FILTSTAT	13		# Update the pset parameters to the GUI
define	UI_CONTSTAT	14		# Update the pset parameters to the GUI
define	UI_AUTOWRITE	15		# Update the autowrite param
define	UI_IMLOAD	16		# Load the requested image
define	UI_LISTOPEN	17		# Open the image list
define	UI_IMGLIST	18		# Update the current image list
define	UI_APLIST	19		# Set an aperture list and template
