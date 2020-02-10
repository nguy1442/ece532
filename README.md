# ece532
Github Repo for ECE532

On the repo there’s 2 folders, 1 for board files and the other containing a bare minimum sample Vivaldi project (inside tut4 folder)



After you clone the repo, you can recreate the project by going into /tut4/proj/, starting up Vivado in that directory, and running the following TCL commands in the TCL console or whatever



1. That command to load in the board files from the board files directory (if needed, might not be necessary if you have them installed already)



2. source tut4.tcl (this recreates the project)



3. source bd.tcl (this recreated the whole block diagram/connections, note you need to regenerate the HDL wrapper for it by right clicking it)



Make sure you’re in /proj directory when you start Vivado and do those steps
