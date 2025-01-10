#!/bin/bash

./steamcmd.sh +runscript ~/rs2server.txt
cd /home/steam/RS2/server 
wine ./Binaries/Win64/VNGame.exe VNTE-CuChi?game=ROGame.ROGameInfoTerritories
