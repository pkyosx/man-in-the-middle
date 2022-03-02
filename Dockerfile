from node

workdir /app
copy src /app

copy config/cert.pem /tmp/cert.pem
copy config/key.pem /tmp/key.pem

RUN npm install nodemon -g

ENTRYPOINT ["nodemon", "app.js"]