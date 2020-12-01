#!/bin/sh
cd ./home/ubuntu
sudo apt update

sudo apt-get install -y nodejs
git clone https://github.com/luvi01/cloud-orm.git

cd ./cloud-orm
sudo apt-get install -y npm
sudo npm install pm2@latest -g
cd ./src
mkdir config
cd ./config

#sed -i 's/PLACE_NAME/'${dbName}'/g' settings.py
#sed -i 's/PLACE_USER/'${dbUser}'/g' settings.py
#sed -i 's/PLACE_PASSWORD/'${dbPass}'/g' settings.py
#sed -i 's/PLACE_HOST/'${dbHost}'/g' settings.py
#sed -i 's/PLACE_PORT/'${dbPort}'/g' settings.py

cat << EOF > typeorm.config.ts
import { TypeOrmModuleOptions } from '@nestjs/typeorm';


export const typeOrmConfig: TypeOrmModuleOptions = {
    type: 'postgres',
    host: '${dbHost}',
    port: ${dbPort},
    username: '${dbUser}',
    password: '${dbPass}',
    database: '${dbName}',
    entities: [__dirname + '/../**/*.entity.{js,ts}'],
    synchronize: true
};
EOF

cd ..
cd ..
sudo npm i
sudo pm2 start "npm start" --name "orm"


#cd ..
#./install.sh
#sudo reboot