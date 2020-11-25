#!/bin/sh
cd ./home/ubuntu
sudo apt update
git clone https://github.com/luvi01/tasks.git
cd ./tasks
cd ./portfolio

sed -i 's/PLACE_NAME/'${dbName}'/g' settings.py
sed -i 's/PLACE_USER/'${dbUser}'/g' settings.py
sed -i 's/PLACE_PASSWORD/'${dbPass}'/g' settings.py
sed -i 's/PLACE_HOST/'${dbHost}'/g' settings.py
sed -i 's/PLACE_PORT/'${dbPort}'/g' settings.py

cd ..
./install.sh
sudo reboot