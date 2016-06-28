#!/bin/bash
chown shiny:shiny -R /srv/shiny-server/lyricsexplorer
sudo -u shiny bash << EOF
shiny-server&
EOF


